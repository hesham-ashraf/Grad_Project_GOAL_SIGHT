// ---------------------------------------------------------------------------
// GoalSight — Player Profile PDF Export
//
// Builds the JSON snapshot the Python PDF microservice expects from the data
// the manager already has (PlayerProfileModel + the player's match heatmaps),
// POSTs it to `${PDF_API_URL}/player-report`, and returns the PDF bytes. The UI
// then shares/prints them via the `printing` package.
// ---------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/pdf_config.dart';
import '../models/player_heatmap_model.dart';
import '../models/player_profile_model.dart';

class PdfExportException implements Exception {
  PdfExportException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PdfExportService {
  PdfExportService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Generates the player-profile PDF and returns its bytes.
  Future<Uint8List> generatePlayerReport({
    required PlayerProfileModel player,
    List<PlayerMatchHeatmap> heatmaps = const [],
    List<PlayerMatchHistory> matchHistory = const [],
    String? clubName,
  }) async {
    if (!hasPdfApi) {
      throw PdfExportException(
        'PDF export is not configured. Set PDF_API_URL in .env to the PDF '
        'service (e.g. http://10.0.2.2:8000 for the Android emulator).',
      );
    }

    final base = pdfApiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    // Prefer the freshly-fetched per-match history; fall back to whatever the
    // player object already carries.
    final history =
        matchHistory.isNotEmpty ? matchHistory : player.matchHistory;
    final body = _buildPayload(player, heatmaps, history, clubName);

    try {
      final resp = await _dio.post<List<int>>(
        '$base/player-report',
        data: body,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final data = resp.data;
      if (data == null || data.isEmpty) {
        throw PdfExportException('The PDF service returned an empty response.');
      }
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      throw PdfExportException(
        'Could not reach the PDF service (${e.type.name}). '
        'Check PDF_API_URL and that the service is running.',
      );
    }
  }

  Map<String, dynamic> _buildPayload(
    PlayerProfileModel p,
    List<PlayerMatchHeatmap> heatmaps,
    List<PlayerMatchHistory> matchHistory,
    String? clubName,
  ) {
    return {
      'name': p.name,
      'position': p.position,
      'jersey_number': p.jerseyNumber,
      'club': clubName ?? '',
      'nationality': p.nationality,
      'age': p.age,
      'height_cm': p.heightCm,
      'weight_kg': p.weightKg,
      'market_value': p.marketValue,
      'is_captain': p.isCaptain,
      'current_rating': p.currentRating,
      'average_rating': p.averageRating,
      'fatigue': p.fatigue,
      'activity_level': p.activityLevel,
      'primary_contribution': p.primaryContribution,
      'secondary_contribution': p.secondaryContribution,
      'status': p.status,
      'trend': p.trendLabel,
      'improvement_rate': p.improvementRate,
      'total_matches': p.totalMatches,
      'total_goals': p.totalGoals,
      'total_assists': p.totalAssists,
      'total_tackles': p.totalTackles,
      'insights': p.insights,
      'match_history': [
        for (final m in matchHistory)
          {
            'date': m.matchDate.toIso8601String(),
            'home_team': m.homeTeam,
            'away_team': m.awayTeam,
            'rating': m.playerRating,
            'status': m.performanceStatus,
            'goals': m.goals,
            'assists': m.assists,
            'tackles': m.tackles,
            'key_passes': m.keyPasses,
          },
      ],
      'heatmaps': [
        for (final h in heatmaps)
          {
            'match_label': h.matchLabel,
            'date_label': h.dateLabel,
            'url': h.url,
          },
      ],
      'generated_at': DateTime.now().toIso8601String().split('T').first,
    };
  }
}

final pdfExportServiceProvider =
    Provider<PdfExportService>((ref) => PdfExportService());
