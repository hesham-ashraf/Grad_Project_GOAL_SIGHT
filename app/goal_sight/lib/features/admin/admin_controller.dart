import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/match_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../match/match_state.dart';
import 'admin_state.dart';

class AdminController extends StateNotifier<AdminState> {
  AdminController(this._adminRepository) : super(const AdminState());

  final AdminRepository _adminRepository;

  Future<void> loadDashboard() async {
    state = state.copyWith(status: ViewStatus.loading, clearError: true);
    try {
      final overview = await _adminRepository.fetchOverview();
      final users = await _adminRepository.fetchUsers();
      final matches = await _adminRepository.fetchMatches();

      state = state.copyWith(
        status: ViewStatus.success,
        overview: overview,
        users: users,
        matches: matches,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: ViewStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> addMatch({
    required String homeTeam,
    required String awayTeam,
  }) async {
    if (homeTeam.trim().isEmpty || awayTeam.trim().isEmpty) return;

    state = state.copyWith(isSubmittingMatch: true, clearError: true);
    try {
      await _adminRepository.uploadMatch(
        homeTeam: homeTeam.trim(),
        awayTeam: awayTeam.trim(),
      );

      final inserted = MatchModel(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        homeTeam: homeTeam.trim(),
        awayTeam: awayTeam.trim(),
        status: 'scheduled',
        score: '0 - 0',
      );

      final updatedMatches = [inserted, ...state.matches];
      state = state.copyWith(
        status: ViewStatus.success,
        matches: updatedMatches,
        isSubmittingMatch: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: ViewStatus.error,
        isSubmittingMatch: false,
        errorMessage: error.toString(),
      );
    }
  }
}
