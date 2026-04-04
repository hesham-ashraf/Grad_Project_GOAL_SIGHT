import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/match_model.dart';

class MatchRemoteDataSource {
  const MatchRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<MatchModel>> fetchMatches() async {
    try {
      final response = await _dio.get(ApiConstants.managerMatchesEndpoint);
      final raw = (response.data['matches'] ?? response.data) as List<dynamic>;
      return raw
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      if (!ApiConstants.enableMockFallback) rethrow;
      return const [
        MatchModel(
          id: 'm1',
          homeTeam: 'Falcons FC',
          awayTeam: 'Eagles FC',
          status: 'live',
          score: '1 - 0',
        ),
        MatchModel(
          id: 'm2',
          homeTeam: 'Tigers FC',
          awayTeam: 'Sharks FC',
          status: 'scheduled',
          score: '0 - 0',
        ),
      ];
    }
  }

  Future<MatchModel> fetchMatchDetails(String matchId) async {
    try {
      final response =
          await _dio.get('${ApiConstants.managerMatchesEndpoint}/$matchId');
      return MatchModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      if (!ApiConstants.enableMockFallback) rethrow;
      return MatchModel(
        id: matchId,
        homeTeam: 'Falcons FC',
        awayTeam: 'Eagles FC',
        status: 'live',
        score: '1 - 0',
      );
    }
  }

  Future<void> uploadMatch({
    required String homeTeam,
    required String awayTeam,
  }) async {
    try {
      await _dio.post(
        ApiConstants.managerMatchesEndpoint,
        data: {
          'homeTeam': homeTeam,
          'awayTeam': awayTeam,
        },
      );
    } catch (_) {
      if (!ApiConstants.enableMockFallback) rethrow;
    }
  }
}
