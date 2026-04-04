import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/match_model.dart';
import '../models/system_overview_model.dart';
import '../models/user_model.dart';

class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._dio);

  final Dio _dio;

  Future<SystemOverviewModel> fetchOverview() async {
    try {
      final response = await _dio.get(ApiConstants.adminOverviewEndpoint);
      return SystemOverviewModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (_) {
      if (!ApiConstants.enableMockFallback) rethrow;
      return const SystemOverviewModel(
        totalUsers: 28,
        totalMatches: 120,
        activeMatches: 3,
      );
    }
  }

  Future<List<UserModel>> fetchUsers() async {
    try {
      final response = await _dio.get(ApiConstants.adminUsersEndpoint);
      final raw = (response.data['users'] ?? response.data) as List<dynamic>;
      return raw
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      if (!ApiConstants.enableMockFallback) rethrow;
      return [
        UserModel.fromJson({
          'id': 'u1',
          'name': 'Manager One',
          'email': 'manager1@goalsight.ai',
          'role': 'manager',
        }),
        UserModel.fromJson({
          'id': 'u2',
          'name': 'Admin One',
          'email': 'admin1@goalsight.ai',
          'role': 'admin',
        }),
      ];
    }
  }

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
      ];
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
