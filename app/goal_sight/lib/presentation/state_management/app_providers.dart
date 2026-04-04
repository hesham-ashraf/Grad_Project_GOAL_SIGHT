import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/websocket_service.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/match_remote_datasource.dart';
import '../../data/models/match_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/match_repository.dart';
import '../../features/admin/admin_controller.dart';
import '../../features/admin/admin_state.dart';
import '../../features/analytics/analytics_summary.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_state.dart';
import '../../features/fan/fan_highlight_model.dart';
import '../../features/manager/standing_entry_model.dart';
import '../../features/match/live_match_controller.dart';
import '../../features/match/live_match_state.dart';
import '../../features/match/match_controller.dart';
import '../../features/match/match_state.dart';
import '../../features/user/team_member_model.dart';

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
  (ref) => AuthRepository(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageServiceProvider),
  ),
);

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.watch(matchRemoteDataSourceProvider)),
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

final leagueStandingsProvider = Provider<List<StandingEntryModel>>(
  (ref) => const [
    StandingEntryModel(
      rank: 1,
      team: 'GoalSight FC',
      played: 24,
      wins: 16,
      draws: 5,
      losses: 3,
      goalsFor: 48,
      goalsAgainst: 20,
      points: 53,
    ),
    StandingEntryModel(
      rank: 2,
      team: 'Falcons United',
      played: 24,
      wins: 15,
      draws: 5,
      losses: 4,
      goalsFor: 44,
      goalsAgainst: 22,
      points: 50,
    ),
    StandingEntryModel(
      rank: 3,
      team: 'Sharks FC',
      played: 24,
      wins: 13,
      draws: 7,
      losses: 4,
      goalsFor: 41,
      goalsAgainst: 26,
      points: 46,
    ),
    StandingEntryModel(
      rank: 4,
      team: 'Eagles Club',
      played: 24,
      wins: 12,
      draws: 7,
      losses: 5,
      goalsFor: 35,
      goalsAgainst: 25,
      points: 43,
    ),
  ],
);

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
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    return const [
      FanHighlightModel(
        id: 'h1',
        title: 'Manchester United vs Liverpool - All Goals & Highlights',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&w=1100&q=80',
        duration: '5:23',
        league: 'Premier League',
        views: '1.2M views',
      ),
      FanHighlightModel(
        id: 'h2',
        title: 'Real Madrid vs Barcelona - El Clasico Extended Highlights',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?auto=format&fit=crop&w=1100&q=80',
        duration: '8:45',
        league: 'La Liga',
        views: '2.5M views',
      ),
      FanHighlightModel(
        id: 'h3',
        title: 'Bayern Munich - Amazing Team Goals Compilation',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1486286701208-1d58e9338013?auto=format&fit=crop&w=1100&q=80',
        duration: '6:12',
        league: 'Bundesliga',
        views: '892K views',
      ),
      FanHighlightModel(
        id: 'h4',
        title: 'PSG vs Marseille - Best Moments',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1459865264687-595d652de67e?auto=format&fit=crop&w=1100&q=80',
        duration: '4:58',
        league: 'Ligue 1',
        views: '654K views',
      ),
    ];
  },
);

final liveMatchControllerProvider = StateNotifierProvider.autoDispose
    .family<LiveMatchController, LiveMatchState, String>((ref, matchId) {
  final token = ref.watch(authControllerProvider).token;
  return LiveMatchController(
    webSocketService: ref.watch(webSocketServiceProvider),
    matchId: matchId,
    token: token,
  );
});
