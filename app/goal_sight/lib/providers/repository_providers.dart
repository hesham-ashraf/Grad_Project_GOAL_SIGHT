// ---------------------------------------------------------------------------
// GoalSight — Repository Providers
//
// Riverpod providers exposing all repository interfaces.
// Swap the Mock* implementations for Supabase* when backend is ready.
// Zero UI changes required — providers keep the same types.
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/analysis_export_model.dart';
import '../data/models/club_model.dart';
import '../data/models/manager_model.dart';
import '../data/models/match_analysis_model.dart';
import '../data/models/player_heatmap_model.dart';
import '../data/models/player_profile_model.dart';
import '../data/models/risk_analysis_model.dart';
import '../data/repositories/interfaces/i_analysis_repository.dart';
import '../data/repositories/interfaces/i_club_repository.dart';
import '../data/repositories/interfaces/i_manager_repository.dart';
import '../data/repositories/interfaces/i_player_repository.dart';
import '../data/repositories/interfaces/i_upload_repository.dart';
import 'paginated_notifier.dart';
import '../data/repositories/supabase/supabase_analysis_repository.dart';
import '../data/repositories/supabase/supabase_player_repository.dart';
import '../data/repositories/supabase/supabase_storage_repository.dart';
import '../data/repositories/supabase/supabase_club_repository.dart';
import '../data/repositories/supabase/supabase_manager_repository.dart';
import '../data/repositories/supabase/supabase_upload_repository.dart';
import '../data/repositories/supabase/supabase_notification_repository.dart';
import '../data/services/analysis_engine.dart';
import '../data/models/upload_job_model.dart';
import '../data/models/notification_model.dart';

// ── Repository singletons ─────────────────────────────────────────────────

/// Club repository — Supabase-backed (teams + season stats + squads).
final clubRepositoryProvider = Provider<IClubRepository>(
  (_) => const SupabaseClubRepository(),
);

/// Player repository — Supabase-backed (players + player_intelligence).
final playerRepositoryProvider = Provider<IPlayerRepository>(
  (_) => const SupabasePlayerRepository(),
);

/// Analysis repository — Supabase-backed (match_analyses + nested).
final analysisRepositoryProvider = Provider<IAnalysisRepository>(
  (_) => const SupabaseAnalysisRepository(),
);

/// Upload repository — Supabase-backed (upload_jobs).
final uploadRepositoryProvider = Provider<IUploadRepository>(
  (_) => const SupabaseUploadRepository(),
);

/// Manager repository — Supabase-backed (managers directory table).
final managerRepositoryProvider = Provider<IManagerRepository>(
  (_) => const SupabaseManagerRepository(),
);

/// Analysis engine - calls the configured ML backend when ANALYSIS_API_URL is
/// set, with the simulator kept as a demo/offline fallback.
final analysisEngineProvider = Provider<IAnalysisEngine>(
  (_) => ModelAnalysisEngine(),
);

/// Storage repository — analysis exports + report persistence.
final storageRepositoryProvider = Provider<SupabaseStorageRepository>(
  (_) => const SupabaseStorageRepository(),
);

// ── Club providers ────────────────────────────────────────────────────────

/// All clubs, optionally filtered by [query]
final clubListProvider = FutureProvider.family<List<ClubModel>, String?>(
  (ref, query) => ref.watch(clubRepositoryProvider).fetchClubs(query: query),
);

/// Single club by id
final clubDetailProvider = FutureProvider.family<ClubModel, String>(
  (ref, clubId) => ref.watch(clubRepositoryProvider).fetchClubById(clubId),
);

/// Infinite-scroll clubs directory, keyed by search query ('' = all).
/// Server-paginated via [IClubRepository.fetchClubsPaged].
final clubsPagedProvider = StateNotifierProvider.autoDispose
    .family<PaginatedNotifier<ClubModel>, PaginatedState<ClubModel>, String>(
  (ref, query) {
    final repo = ref.watch(clubRepositoryProvider);
    return PaginatedNotifier<ClubModel>(
      (page, size) => repo.fetchClubsPaged(
        page: page,
        pageSize: size,
        query: query.isEmpty ? null : query,
        sortBy: 'ranking',
      ),
      pageSize: 12,
    );
  },
);

// ── Player providers ──────────────────────────────────────────────────────

/// Squad for a given club (null = all players)
final squadProvider = FutureProvider.family<List<PlayerProfileModel>, String?>(
  (ref, clubId) =>
      ref.watch(playerRepositoryProvider).fetchSquad(clubId: clubId),
);

/// Single player by id
final playerDetailProvider = FutureProvider.family<PlayerProfileModel, String>(
  (ref, playerId) =>
      ref.watch(playerRepositoryProvider).fetchPlayerById(playerId),
);

/// Per-match movement heatmaps for a player (newest first). Empty until the
/// AI pipeline produces heatmaps for the player.
final playerHeatmapsProvider =
    FutureProvider.family<List<PlayerMatchHeatmap>, String>(
  (ref, playerId) =>
      ref.watch(playerRepositoryProvider).fetchPlayerHeatmaps(playerId),
);

/// Per-match history for a player (rating + stats per match), newest first.
final playerMatchHistoryProvider =
    FutureProvider.family<List<PlayerMatchHistory>, String>(
  (ref, playerId) =>
      ref.watch(playerRepositoryProvider).fetchPlayerMatchHistory(playerId),
);

/// Risk analysis for a single player
final playerRiskProvider = FutureProvider.family<RiskAnalysisModel, String>(
  (ref, playerId) =>
      ref.watch(playerRepositoryProvider).fetchRiskAnalysis(playerId),
);

/// Full squad risk analysis, sorted by composite score descending
final squadRiskProvider =
    FutureProvider.family<List<RiskAnalysisModel>, String?>(
  (ref, clubId) => ref
      .watch(playerRepositoryProvider)
      .fetchSquadRiskAnalysis(clubId: clubId),
);

// ── Analysis providers ────────────────────────────────────────────────────

/// All match analyses for a given club (null = all clubs)
final matchAnalysisListProvider =
    FutureProvider.family<List<MatchAnalysisModel>, String?>(
  (ref, clubId) =>
      ref.watch(analysisRepositoryProvider).fetchAnalyses(clubId: clubId),
);

/// Single match analysis by id
final matchAnalysisDetailProvider =
    FutureProvider.family<MatchAnalysisModel, String>(
  (ref, matchId) =>
      ref.watch(analysisRepositoryProvider).fetchAnalysisById(matchId),
);

/// Latest analysis for a given club (null = across all clubs)
final latestAnalysisProvider =
    FutureProvider.family<MatchAnalysisModel?, String?>(
  (ref, clubId) =>
      ref.watch(analysisRepositoryProvider).fetchLatestAnalysis(clubId: clubId),
);

// ── Upload providers ──────────────────────────────────────────────────────

/// Upload history for a given manager (null = all uploads)
final uploadHistoryProvider =
    FutureProvider.family<List<UploadJobModel>, String?>(
  (ref, managerId) => ref
      .watch(uploadRepositoryProvider)
      .fetchUploadHistory(managerId: managerId),
);

/// Single upload job by id
final uploadJobDetailProvider = FutureProvider.family<UploadJobModel, String>(
  (ref, jobId) => ref.watch(uploadRepositoryProvider).fetchUploadById(jobId),
);

// ── Manager providers ─────────────────────────────────────────────────────

/// All managers, optionally filtered by active status
/// Pass '' to get all, 'active' for active only, 'disabled' for inactive only
final managerListProvider = FutureProvider.family<List<ManagerModel>, String>(
  (ref, filter) {
    bool? activeOnly;
    if (filter == 'active') activeOnly = true;
    if (filter == 'disabled') activeOnly = false;
    return ref
        .watch(managerRepositoryProvider)
        .fetchManagers(activeOnly: activeOnly);
  },
);

/// Single manager by id
final managerDetailProvider = FutureProvider.family<ManagerModel, String>(
  (ref, managerId) =>
      ref.watch(managerRepositoryProvider).fetchManagerById(managerId),
);

/// Synchronous managers list for admin screens (empty while loading / on error).
final adminManagersProvider = Provider<List<ManagerModel>>((ref) {
  return ref.watch(managerListProvider('')).maybeWhen(
        data: (managers) => managers,
        orElse: () => const <ManagerModel>[],
      );
});

// ── Storage providers ─────────────────────────────────────────────────────

/// Analysis exports, optionally filtered by analysis id (null = all).
final analysisExportsProvider =
    FutureProvider.family<List<AnalysisExportModel>, String?>(
  (ref, analysisId) => ref
      .watch(storageRepositoryProvider)
      .fetchAnalysisExports(analysisId: analysisId),
);

/// Stored reports, optionally filtered by report type (null = all).
final storedReportsProvider =
    FutureProvider.family<List<StoredReportModel>, StoredReportType?>(
  (ref, type) => ref.watch(storageRepositoryProvider).fetchReports(type: type),
);

// ── Notification providers ────────────────────────────────────────────────

/// Notification repository singleton.
final notificationRepositoryProvider = Provider<SupabaseNotificationRepository>(
  (_) => const SupabaseNotificationRepository(),
);

/// All notifications for the signed-in admin (newest first).
final notificationsProvider = FutureProvider<List<NotificationModel>>(
  (ref) => ref.watch(notificationRepositoryProvider).fetchNotifications(),
);

/// Unread notification count (0 while loading / on error).
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (list) => list.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});

/// Realtime stream of notifications (auto-updates on INSERT/UPDATE via Supabase Realtime).
final notificationsStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationRepositoryProvider).watchNotifications();
});
