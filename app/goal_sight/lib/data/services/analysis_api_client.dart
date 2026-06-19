// ---------------------------------------------------------------------------
// GoalSight — Analysis API Client
//
// Talks to the WSL FastAPI analysis service (exposed via ngrok). Base URL comes
// from ANALYSIS_API_URL (lib/core/config/analysis_config.dart). Every request
// carries the manager's Supabase JWT so the service can attribute the job.
//
// Endpoint flow:
//   POST   /jobs                 multipart video + match metadata → { job_id }
//   GET    /jobs/{id}            status poll
//   GET    /jobs/{id}/naming     detected players + team legend
//   POST   /jobs/{id}/players    { mappings, my_team_id } → starts analysis
//   GET    /jobs/{id}/result     final result (+ Supabase analysis_id)
// ---------------------------------------------------------------------------

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/config/analysis_config.dart';
import '../models/analysis_job_model.dart';

class AnalysisApiException implements Exception {
  AnalysisApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AnalysisApiClient {
  AnalysisApiClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  bool get isConfigured => hasAnalysisApi;

  String get _base => analysisApiBaseUrl.replaceAll(RegExp(r'/+$'), '');

  Options _opts({String contentType = 'application/json'}) {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return Options(
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        // ngrok's free tier shows a warning interstitial unless this is set.
        'ngrok-skip-browser-warning': 'true',
      },
      contentType: contentType,
      sendTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(minutes: 10),
    );
  }

  void _ensure() {
    if (!isConfigured) {
      throw AnalysisApiException(
        'No analysis server configured. Set ANALYSIS_API_URL in .env to your '
        'ngrok URL and restart the app.',
      );
    }
  }

  /// Uploads the match video + metadata; the service starts detection
  /// immediately and returns a job id.
  Future<String> createJob({
    required String videoPath,
    required String fileName,
    required String homeTeam,
    required String awayTeam,
    String competition = '',
    String venue = '',
    String matchDate = '',
    String? clubId,
    String? uploadedBy,
  }) async {
    _ensure();
    final form = FormData.fromMap({
      'video': await MultipartFile.fromFile(videoPath, filename: fileName),
      'home_team': homeTeam,
      'away_team': awayTeam,
      'competition': competition,
      'venue': venue,
      'match_date': matchDate,
      if (clubId != null) 'club_id': clubId,
      if (uploadedBy != null) 'uploaded_by': uploadedBy,
    });
    final res = await _dio.post(
      '$_base/jobs',
      data: form,
      options: _opts(contentType: 'multipart/form-data'),
    );
    final id = _asMap(res.data)['job_id']?.toString();
    if (id == null || id.isEmpty) {
      throw AnalysisApiException('Server did not return a job id.');
    }
    return id;
  }

  Future<AnalysisJobStatusResult> getStatus(String jobId) async {
    _ensure();
    final res = await _dio.get('$_base/jobs/$jobId', options: _opts());
    return AnalysisJobStatusResult.fromJson(_asMap(res.data));
  }

  Future<NamingData> getNaming(String jobId) async {
    _ensure();
    final res = await _dio.get('$_base/jobs/$jobId/naming', options: _opts());
    return NamingData.fromJson(_asMap(res.data));
  }

  Future<void> confirmPlayers({
    required String jobId,
    required List<PlayerNameMapping> mappings,
    required int myTeamId,
  }) async {
    _ensure();
    await _dio.post(
      '$_base/jobs/$jobId/players',
      data: {
        'mappings': mappings.map((m) => m.toJson()).toList(),
        'my_team_id': myTeamId,
      },
      options: _opts(),
    );
  }

  Future<AnalysisJobResult> getResult(String jobId) async {
    _ensure();
    final res = await _dio.get('$_base/jobs/$jobId/result', options: _opts());
    return AnalysisJobResult.fromJson(_asMap(res.data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return data.cast<String, dynamic>();
    throw AnalysisApiException('Unexpected server response: $data');
  }
}
