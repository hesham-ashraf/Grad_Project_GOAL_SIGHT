import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../core/services/api_service.dart';
import '../core/services/secure_storage_service.dart';
import '../core/services/websocket_service.dart';
import '../data/datasources/admin_remote_datasource.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/datasources/match_remote_datasource.dart';
import '../data/models/match_model.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/match_repository.dart';
import '../features/admin/admin_controller.dart';
import '../features/admin/admin_state.dart';
import '../data/models/analytics_summary.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_state.dart';
import '../data/models/fan_highlight_model.dart';
import '../data/models/standing_entry_model.dart';
import '../features/match/live_match_controller.dart';
import '../features/match/live_match_state.dart';
import '../features/match/match_controller.dart';
import '../features/match/match_state.dart';
import '../features/user/team_member_model.dart';
import 'clubs_provider.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => const SecureStorageService(),
);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return ApiService(storage).dio;
});

final webSocketServiceProvider = Provider<WebSocketService>(
  (ref) {
    final service = WebSocketService();
    ref.onDispose(service.dispose);
    return service;
  },
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
);

final matchRemoteDataSourceProvider = Provider<MatchRemoteDataSource>(
  (ref) => MatchRemoteDataSource(ref.watch(dioProvider)),
);

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>(
  (ref) => AdminRemoteDataSource(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<IAuthRepository>(
  (ref) => SupabaseAuthRepository(
    ref.watch(secureStorageServiceProvider),
  ),
);

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => const MatchRepository(),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(adminRemoteDataSourceProvider)),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);

final matchControllerProvider =
    StateNotifierProvider<MatchController, MatchState>(
  (ref) => MatchController(ref.watch(matchRepositoryProvider)),
);

final adminControllerProvider =
    StateNotifierProvider<AdminController, AdminState>(
  (ref) => AdminController(ref.watch(adminRepositoryProvider)),
);

final matchDetailsProvider = FutureProvider.family<MatchModel, String>(
  (ref, matchId) =>
      ref.watch(matchRepositoryProvider).fetchMatchDetails(matchId),
);

final analyticsSummaryProvider = Provider<AnalyticsSummary>((ref) {
  final matches = ref.watch(matchControllerProvider).matches;
  if (matches.isEmpty) {
    return const AnalyticsSummary(
      totalGoals: 0,
      avgPossession: 50,
      avgPassAccuracy: 70,
    );
  }

  return AnalyticsSummary(
    totalGoals: matches.length * 2,
    avgPossession: 57,
    avgPassAccuracy: 83,
  );
});

final teamMembersProvider = Provider<List<TeamMemberModel>>(
  (ref) => const [
    TeamMemberModel(
      id: 'p1',
      name: 'Ahmed Nasser',
      position: 'Goalkeeper',
      shirtNumber: 1,
      age: 26,
      rating: 7.5,
      stamina: 88,
      goals: 0,
      assists: 0,
      isStarting: true,
    ),
    TeamMemberModel(
      id: 'p2',
      name: 'Karim Adel',
      position: 'Defender',
      shirtNumber: 4,
      age: 24,
      rating: 7.9,
      stamina: 91,
      goals: 1,
      assists: 1,
      isStarting: true,
    ),
    TeamMemberModel(
      id: 'p3',
      name: 'Omar Fathy',
      position: 'Defender',
      shirtNumber: 5,
      age: 27,
      rating: 7.7,
      stamina: 89,
      goals: 0,
      assists: 1,
      isStarting: true,
    ),
    TeamMemberModel(
      id: 'p4',
      name: 'Ziad Hamdy',
      position: 'Midfielder',
      shirtNumber: 8,
      age: 23,
      rating: 8.1,
      stamina: 93,
      goals: 3,
      assists: 6,
      isStarting: true,
    ),
    TeamMemberModel(
      id: 'p5',
      name: 'Hassan Ali',
      position: 'Midfielder',
      shirtNumber: 10,
      age: 25,
      rating: 8.4,
      stamina: 86,
      goals: 8,
      assists: 7,
      isStarting: true,
    ),
    TeamMemberModel(
      id: 'p6',
      name: 'Mostafa Samir',
      position: 'Forward',
      shirtNumber: 9,
      age: 22,
      rating: 8.0,
      stamina: 84,
      goals: 11,
      assists: 4,
      isStarting: true,
    ),
    TeamMemberModel(
      id: 'p7',
      name: 'Youssef Tarek',
      position: 'Forward',
      shirtNumber: 11,
      age: 21,
      rating: 7.4,
      stamina: 82,
      goals: 5,
      assists: 2,
      isStarting: false,
    ),
  ],
);

final coachTeamNameProvider = Provider<String>((ref) => 'GoalSight FC');

// League standings derived from Supabase-backed club season stats.
final leagueStandingsProvider = Provider<List<StandingEntryModel>>((ref) {
  final clubs = ref.watch(mockClubsProvider);
  final ranked = clubs.toList()
    ..sort((a, b) {
      if (b.stats.points != a.stats.points) {
        return b.stats.points.compareTo(a.stats.points);
      }
      return b.stats.goalDifference.compareTo(a.stats.goalDifference);
    });

  return [
    for (var i = 0; i < ranked.length; i++)
      StandingEntryModel(
        rank: i + 1,
        team: ranked[i].name,
        played: ranked[i].stats.matchesPlayed,
        wins: ranked[i].stats.wins,
        draws: ranked[i].stats.draws,
        losses: ranked[i].stats.losses,
        goalsFor: ranked[i].stats.goalsScored,
        goalsAgainst: ranked[i].stats.goalsConceded,
        points: ranked[i].stats.points,
      ),
  ];
});

final adminSystemAlertsProvider = Provider<List<String>>(
  (ref) => const [
    '2 pending user verification requests.',
    'Weekly match import completed successfully.',
    'No critical incidents in the last 24 hours.',
  ],
);

final fanLiveMatchesProvider = FutureProvider<List<MatchModel>>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 950));
  return ref.watch(matchRepositoryProvider).fetchMatches();
});

final fanFeaturedMatchProvider = Provider<MatchModel?>((ref) {
  final asyncMatches = ref.watch(fanLiveMatchesProvider);
  return asyncMatches.maybeWhen(
    data: (matches) => matches.isEmpty ? null : matches.first,
    orElse: () => null,
  );
});

final fanTodayMatchesProvider = Provider<List<MatchModel>>((ref) {
  final asyncMatches = ref.watch(fanLiveMatchesProvider);
  return asyncMatches.maybeWhen(
    data: (matches) => matches
        .where((match) => match.status.toLowerCase() != 'finished')
        .toList(),
    orElse: () => const [],
  );
});

final fanRecentResultsProvider = Provider<List<MatchModel>>((ref) {
  final asyncMatches = ref.watch(fanLiveMatchesProvider);
  return asyncMatches.maybeWhen(
    data: (matches) => matches,
    orElse: () => const [],
  );
});

final fanHighlightsProvider = FutureProvider<List<FanHighlightModel>>(
  (ref) async {
    final rows = await Supabase.instance.client
        .from('highlights')
        .select('id, title, thumbnail_url, duration_seconds, league, views')
        .order('views', ascending: false);
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      return FanHighlightModel(
        id: map['id'].toString(),
        title: (map['title'] ?? '').toString(),
        thumbnailUrl: (map['thumbnail_url'] ?? '').toString(),
        duration:
            _formatDuration((map['duration_seconds'] as num? ?? 0).toInt()),
        league: (map['league'] ?? '').toString(),
        views: _formatViews((map['views'] as num? ?? 0).toInt()),
      );
    }).toList();
  },
);

String _formatDuration(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

String _formatViews(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M views';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K views';
  return '$v views';
}

final liveMatchControllerProvider = StateNotifierProvider.autoDispose
    .family<LiveMatchController, LiveMatchState, String>((ref, matchId) {
  final token = ref.watch(authControllerProvider).token;
  return LiveMatchController(
    webSocketService: ref.watch(webSocketServiceProvider),
    matchId: matchId,
    token: token,
  );
});
