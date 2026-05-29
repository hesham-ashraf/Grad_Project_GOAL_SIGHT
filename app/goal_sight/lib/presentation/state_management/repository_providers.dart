// ---------------------------------------------------------------------------
// GoalSight — Repository Providers
//
// Riverpod providers exposing all repository interfaces.
// Swap the Mock* implementations for Supabase* when backend is ready.
// Zero UI changes required — providers keep the same types.
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/club_model.dart';
import '../../data/models/manager_model.dart';
import '../../data/models/match_analysis_model.dart';
import '../../data/models/player_profile_model.dart';
import '../../data/models/risk_analysis_model.dart';
import '../../data/repositories/interfaces/i_analysis_repository.dart';
import '../../data/repositories/interfaces/i_club_repository.dart';
import '../../data/repositories/interfaces/i_manager_repository.dart';
import '../../data/repositories/interfaces/i_player_repository.dart';
import '../../data/repositories/interfaces/i_upload_repository.dart';
import '../../data/repositories/mock/mock_analysis_repository.dart';
import '../../data/repositories/mock/mock_club_repository.dart';
import '../../data/repositories/mock/mock_manager_repository.dart';
import '../../data/repositories/mock/mock_player_repository.dart';
import '../../data/repositories/mock/mock_upload_repository.dart';
import '../../features/manager/upload_job_model.dart';

// ── Repository singletons ─────────────────────────────────────────────────

/// Club repository — swap MockClubRepository → SupabaseClubRepository
final clubRepositoryProvider = Provider<IClubRepository>(
  (_) => const MockClubRepository(),
);

/// Player repository — swap MockPlayerRepository → SupabasePlayerRepository
final playerRepositoryProvider = Provider<IPlayerRepository>(
  (_) => const MockPlayerRepository(),
);

/// Analysis repository — swap MockAnalysisRepository → SupabaseAnalysisRepository
final analysisRepositoryProvider = Provider<IAnalysisRepository>(
  (_) => const MockAnalysisRepository(),
);

/// Upload repository — swap MockUploadRepository → SupabaseUploadRepository
final uploadRepositoryProvider = Provider<IUploadRepository>(
  (_) => const MockUploadRepository(),
);

/// Manager repository — swap MockManagerRepository → SupabaseManagerRepository
final managerRepositoryProvider = Provider<IManagerRepository>(
  (_) => const MockManagerRepository(),
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

// ── Player providers ──────────────────────────────────────────────────────

/// Squad for a given club (null = all players)
final squadProvider = FutureProvider.family<List<PlayerProfileModel>, String?>(
  (ref, clubId) => ref.watch(playerRepositoryProvider).fetchSquad(clubId: clubId),
);

/// Single player by id
final playerDetailProvider = FutureProvider.family<PlayerProfileModel, String>(
  (ref, playerId) => ref.watch(playerRepositoryProvider).fetchPlayerById(playerId),
);

/// Risk analysis for a single player
final playerRiskProvider = FutureProvider.family<RiskAnalysisModel, String>(
  (ref, playerId) => ref.watch(playerRepositoryProvider).fetchRiskAnalysis(playerId),
);

/// Full squad risk analysis, sorted by composite score descending
final squadRiskProvider = FutureProvider.family<List<RiskAnalysisModel>, String?>(
  (ref, clubId) =>
      ref.watch(playerRepositoryProvider).fetchSquadRiskAnalysis(clubId: clubId),
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
  (ref, managerId) =>
      ref.watch(uploadRepositoryProvider).fetchUploadHistory(managerId: managerId),
);

/// Single upload job by id
final uploadJobDetailProvider =
    FutureProvider.family<UploadJobModel, String>(
  (ref, jobId) => ref.watch(uploadRepositoryProvider).fetchUploadById(jobId),
);

// ── Manager providers ─────────────────────────────────────────────────────

/// All managers, optionally filtered by active status
/// Pass '' to get all, 'active' for active only, 'disabled' for inactive only
final managerListProvider =
    FutureProvider.family<List<ManagerModel>, String>(
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
