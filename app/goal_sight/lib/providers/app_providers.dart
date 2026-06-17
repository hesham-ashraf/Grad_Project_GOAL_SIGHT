import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../core/services/api_service.dart';
import '../core/services/secure_storage_service.dart';
import '../core/services/websocket_service.dart';
import '../core/theme/app_theme.dart';
import '../data/datasources/admin_remote_datasource.dart';
import '../data/models/activity_model.dart';
import '../data/models/match_model.dart';
import '../data/models/upload_job_model.dart' show UploadStatus;
import '../data/models/player_analysis_model.dart';
import '../data/models/tactical_insight_model.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/match_repository.dart';
import '../data/models/system_overview_model.dart';
import '../features/admin/admin_controller.dart';
import '../features/admin/admin_state.dart';
import '../features/manager/manager_dashboard_models.dart';
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

/// Fan match feed — backed by match_analyses from Supabase (completed results).
/// Mapped to MatchModel so existing fan home UI needs no changes.
final fanLiveMatchesProvider = FutureProvider<List<MatchModel>>((ref) async {
  final analyses = await ref.watch(matchAnalysisListProvider(null).future);
  return analyses.map((a) => MatchModel(
    id: a.matchId,
    homeTeam: a.homeTeam,
    awayTeam: a.awayTeam,
    status: a.status.isNotEmpty ? a.status : 'FT',
    score: a.score,
    date: a.date,
    intensity: a.intensity,
    highlightText: a.highlightText,
    isTopMatch: a.intensity >= 80,
    summary: a.summary.overallNarrative,
    dominantTeam: a.summary.dominantTeam,
    recommendations: a.recommendations,
    tactics: TacticalAnalysis(
      homePossession: a.homeAnalysis.possession,
      homeStyle: a.homeAnalysis.style,
      homePressure: a.homeAnalysis.pressureStyle,
      awayPossession: a.awayAnalysis.possession,
      awayStyle: a.awayAnalysis.style,
      awayPressure: a.awayAnalysis.pressureStyle,
    ),
    players: a.players
        .map((p) => MatchPlayer(
              id: p.id,
              name: p.name,
              rating: p.rating,
              insight: p.insight,
              isBest: p.isMOTM,
              isWorst: p.isWorst,
            ))
        .toList(),
  )).toList();
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
    data: (matches) => matches.take(5).toList(),
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

// ── Admin: Supabase-backed system overview counts (scoped to admin's club) ──

final adminSystemOverviewProvider = FutureProvider<SystemOverviewModel>((ref) async {
  final client = Supabase.instance.client;

  // Fetch the admin's club_id for explicit scoping (RLS also handles this).
  String? clubId;
  try {
    final profile = await client
        .from('profiles')
        .select('club_id')
        .eq('id', client.auth.currentUser?.id ?? '')
        .maybeSingle();
    clubId = profile?['club_id'] as String?;
  } catch (_) {
    // Ignore; fall back to unscoped queries (RLS still guards the data).
  }

  // Managers in the same club (role = 'manager' is already RLS-scoped).
  var managersQuery = client.from('profiles').select('id').eq('role', 'manager');
  if (clubId != null) managersQuery = managersQuery.eq('club_id', clubId);
  final totalManagers = ((await managersQuery) as List).length;

  // Analyses — RLS ensures only club-scoped rows are returned.
  final totalAnalyses =
      ((await client.from('match_analyses').select('id')) as List).length;

  // Active processing jobs — RLS-scoped.
  final activeJobs = ((await client
          .from('upload_jobs')
          .select('id')
          .eq('status', 'processing')) as List)
      .length;

  return SystemOverviewModel(
    totalUsers: totalManagers,
    totalMatches: totalAnalyses,
    activeMatches: activeJobs,
  );
});

// ── Manager Dashboard (Supabase-derived) ─────────────────────────────────

final managerDashboardProvider = FutureProvider<ManagerDashboardData>((ref) async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id ?? '';

  // Club name from the manager's profile → teams join
  String clubName = 'My Club';
  try {
    final profile = await client
        .from('profiles')
        .select('display_name, club_id, teams(name)')
        .eq('id', uid)
        .maybeSingle();
    final teamMap = profile?['teams'] as Map<String, dynamic>?;
    if (teamMap != null) clubName = (teamMap['name'] as String?) ?? clubName;
  } catch (_) {}

  // Match analyses scoped by RLS (manager sees only their club's data)
  final analyses = await ref.watch(matchAnalysisListProvider(null).future);
  final matchCount = analyses.length;

  // Squad for avg rating & top performers
  final squad = await ref.watch(squadProvider(null).future);
  final risks = await ref.watch(squadRiskProvider(null).future);

  final avgRating = squad.isEmpty
      ? 0.0
      : squad.map((p) => p.currentRating).reduce((a, b) => a + b) / squad.length;

  final avgFatigue = squad.isEmpty
      ? 0.0
      : squad.map((p) => p.fatigue.toDouble()).reduce((a, b) => a + b) / squad.length;

  // League position placeholder (no standings table yet)
  const leaguePos = '#—';

  final keyStats = [
    ManagerKeyStat(
      label: 'Played Matches',
      value: '$matchCount',
      icon: Icons.event_available_rounded,
      tint: AppColors.accentCyan,
    ),
    ManagerKeyStat(
      label: 'Team Average Rating',
      value: avgRating.toStringAsFixed(2),
      icon: Icons.stars_rounded,
      tint: AppColors.primaryPurple,
    ),
    ManagerKeyStat(
      label: 'Team Fatigue Level',
      value: '${avgFatigue.toInt()}%',
      icon: Icons.bolt_rounded,
      tint: AppColors.warning,
    ),
    ManagerKeyStat(
      label: 'League Position',
      value: leaguePos,
      icon: Icons.emoji_events_rounded,
      tint: AppColors.accentGreen,
    ),
  ];

  // Last match from most recent analysis
  ManagerLastMatch lastMatch;
  if (analyses.isNotEmpty) {
    final last = analyses.last;
    final parts = last.score.split(' - ');
    final homeScore = int.tryParse(parts.isNotEmpty ? parts[0].trim() : '0') ?? 0;
    final awayScore = int.tryParse(parts.length > 1 ? parts[1].trim() : '0') ?? 0;
    lastMatch = ManagerLastMatch(
      homeTeam: last.homeTeam,
      awayTeam: last.awayTeam,
      homeScore: homeScore,
      awayScore: awayScore,
      aiSummary: last.summary.overallNarrative,
      dominantTeam: last.summary.dominantTeam,
    );
  } else {
    lastMatch = const ManagerLastMatch(
      homeTeam: '—',
      awayTeam: '—',
      homeScore: 0,
      awayScore: 0,
      aiSummary: 'No matches analysed yet.',
      dominantTeam: '—',
    );
  }

  // Top performers from squad sorted by rating
  final topPerformers = (squad.toList()
        ..sort((a, b) => b.currentRating.compareTo(a.currentRating)))
      .take(3)
      .map((p) => ManagerPlayerPerformance(name: p.name, rating: p.currentRating))
      .toList();

  // AI insights from high-risk players
  final insights = <ManagerInsight>[];
  final highRisk = risks.where((r) => r.injuryRisk > 60).take(2);
  for (final r in highRisk) {
    insights.add(ManagerInsight(
      title: '${r.playerName} Injury Risk',
      message:
          'Injury risk at ${r.injuryRisk.toInt()}%. Consider rotating before next match.',
      severity: r.injuryRisk > 75
          ? ManagerInsightSeverity.high
          : ManagerInsightSeverity.medium,
    ));
  }
  final highFatigue = risks.where((r) => r.fatigueRisk > 70).take(2);
  for (final r in highFatigue) {
    if (insights.any((i) => i.title.startsWith(r.playerName))) continue;
    insights.add(ManagerInsight(
      title: '${r.playerName} Fatigue Spike',
      message:
          'Fatigue risk at ${r.fatigueRisk.toInt()}%. Rotation recommended.',
      severity: ManagerInsightSeverity.medium,
    ));
  }
  if (analyses.isNotEmpty && insights.length < 3) {
    final recs = analyses.last.recommendations;
    for (final rec in recs.take(3 - insights.length)) {
      insights.add(ManagerInsight(
        title: 'AI Recommendation',
        message: rec,
        severity: ManagerInsightSeverity.low,
      ));
    }
  }
  if (insights.isEmpty) {
    insights.add(const ManagerInsight(
      title: 'Squad In Good Shape',
      message: 'No high-risk alerts at this time. Continue current training plan.',
      severity: ManagerInsightSeverity.low,
    ));
  }

  return ManagerDashboardData(
    clubName: clubName,
    subtitle: 'Season 2025/26 · AI Intelligence Active',
    keyStats: keyStats,
    lastMatch: lastMatch,
    topPerformers: topPerformers,
    insights: insights,
  );
});

// ── Admin: club_id from the signed-in user (cached in UserModel after P0-1) ─

final adminClubIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth.user?.clubId;
});

// ── Admin: Tactical insights derived from match analyses ──────────────────

final adminTacticalInsightsProvider = FutureProvider<List<TacticalInsightModel>>((ref) async {
  final clubId = ref.watch(adminClubIdProvider);
  final analyses = await ref.watch(matchAnalysisListProvider(clubId).future);

  final insights = <TacticalInsightModel>[];
  for (var i = 0; i < analyses.length && insights.length < 5; i++) {
    final a = analyses[analyses.length - 1 - i]; // newest first
    final recs = a.recommendations;
    if (recs.isEmpty) continue;
    for (var j = 0; j < recs.length && insights.length < 5; j++) {
      insights.add(TacticalInsightModel(
        id: '${a.matchId}_$j',
        title: recs[j].split(' ').take(5).join(' '),
        description: recs[j],
        category: j == 0 ? 'Opportunity' : 'Warning',
        impactScore: 7.0 + (j * 0.5).clamp(0, 2),
        generatedAt: DateTime.now().subtract(Duration(hours: i * 6 + j * 2)),
        relatedMatchId: a.matchId,
      ));
    }
  }
  return insights;
});

// ── Admin: Activity feed derived from recent uploads ──────────────────────

final adminActivityProvider = FutureProvider<List<ActivityModel>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  final uploads = await ref.watch(uploadHistoryProvider(uid).future);

  return uploads.take(8).indexed.map((entry) {
    final idx = entry.$1;
    final job = entry.$2;
    final action = switch (job.status) {
      UploadStatus.completed => 'Analyzed Match',
      UploadStatus.failed => 'Upload Failed',
      _ => 'Uploaded Match',
    };
    return ActivityModel(
      id: job.id,
      userId: 'manager_$idx',
      userName: 'Manager',
      userRole: 'Manager',
      action: action,
      description: '${job.homeTeam} vs ${job.awayTeam}',
      timestamp: job.uploadedAt,
      relatedEntityId: job.id,
    );
  }).toList();
});

// ── Admin: Squad derived from real player + risk data ────────────────────

final adminSquadProvider = FutureProvider<List<PlayerAnalysisModel>>((ref) async {
  final clubId = ref.watch(adminClubIdProvider);
  final players = await ref.watch(squadProvider(clubId).future);
  final risks = await ref.watch(squadRiskProvider(clubId).future);

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
