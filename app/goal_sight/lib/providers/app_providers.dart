import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../core/services/api_service.dart';
import '../core/services/secure_storage_service.dart';
import '../core/services/websocket_service.dart';
import '../data/datasources/admin_remote_datasource.dart';
import '../data/models/match_model.dart';
import '../data/models/player_analysis_model.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/match_repository.dart';
import '../data/models/system_overview_model.dart';
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
import 'repository_providers.dart';

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

/// Team members for the coach's club, derived from the Supabase-backed club
/// squad (first/top-ranked club). Empty while clubs are loading.
final teamMembersProvider = Provider<List<TeamMemberModel>>((ref) {
  final clubs = ref.watch(mockClubsProvider);
  if (clubs.isEmpty) return const [];
  final squad = clubs.first.players;
  return [
    for (var i = 0; i < squad.length; i++)
      TeamMemberModel(
        id: squad[i].id,
        name: squad[i].name,
        position: squad[i].position,
        shirtNumber: i + 1,
        age: squad[i].age,
        rating: squad[i].rating,
        // Stamina is not tracked on ClubPlayer; approximate from season rating.
        stamina: (squad[i].rating * 11).round().clamp(40, 100),
        goals: squad[i].goals,
        assists: squad[i].assists,
        isStarting: i < 11,
      ),
  ];
});

/// The coach's club name, sourced from the Supabase-backed club list.
final coachTeamNameProvider = Provider<String>((ref) {
  final clubs = ref.watch(mockClubsProvider);
  return clubs.isEmpty ? 'GoalSight FC' : clubs.first.name;
});

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

/// System alerts derived from real Supabase operational counts (managers,
/// analyses, active processing jobs). Empty while the overview is loading.
final adminSystemAlertsProvider = Provider<List<String>>((ref) {
  return ref.watch(adminSystemOverviewProvider).maybeWhen(
    data: (overview) {
      final alerts = <String>[];
      if (overview.activeMatches > 0) {
        alerts.add(
            '${overview.activeMatches} upload(s) currently processing.');
      } else {
        alerts.add('No uploads processing — pipeline idle.');
      }
      alerts.add('${overview.totalUsers} manager account(s) active.');
      alerts.add('${overview.totalMatches} match analyses available.');
      return alerts;
    },
    orElse: () => const <String>[],
  );
});

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

// ── Admin: Supabase-backed system overview counts ─────────────────────────

final adminSystemOverviewProvider = FutureProvider<SystemOverviewModel>((ref) async {
  final client = Supabase.instance.client;

  final managersRaw = await client
      .from('profiles')
      .select('id')
      .eq('role', 'manager');
  final totalManagers = (managersRaw as List).length;

  final analysesRaw = await client
      .from('match_analyses')
      .select('id');
  final totalAnalyses = (analysesRaw as List).length;

  final activeRaw = await client
      .from('upload_jobs')
      .select('id')
      .eq('status', 'processing');
  final activeJobs = (activeRaw as List).length;

  return SystemOverviewModel(
    totalUsers: totalManagers,
    totalMatches: totalAnalyses,
    activeMatches: activeJobs,
  );
});

// ── Admin: Squad derived from real player + risk data ────────────────────

final adminSquadProvider = FutureProvider<List<PlayerAnalysisModel>>((ref) async {
  final players = await ref.watch(squadProvider(null).future);
  final risks = await ref.watch(squadRiskProvider(null).future);

  final riskMap = {for (final r in risks) r.playerId: r};

  return players.map((p) {
    final risk = riskMap[p.id];
    final posShort = p.position.contains('/') ? p.position.split('/').last.trim() : p.position;
    final avatarUrl =
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(p.name)}'
        '&background=705AF5&color=fff&length=2&bold=true&size=96';

    return PlayerAnalysisModel(
      id: p.id,
      name: p.name,
      position: posShort,
      imageUrl: avatarUrl,
      overallRating: p.currentRating,
      fatigueLevel: p.fatigue.toDouble(),
      injuryRisk: risk?.injuryRisk ?? 20.0,
      workRate: p.activityLevel.toDouble(),
      tacticalImpact: risk != null ? (100.0 - risk.tacticalRisk).clamp(0, 100) : 75.0,
      keyStrengths: p.insights.take(2).toList(),
      weaknesses: const [],
      recentRatings: {
        for (var i = 0; i < p.ratingsHistory.length; i++)
          'Match ${i + 1}': p.ratingsHistory[i],
      },
    );
  }).toList();
});
