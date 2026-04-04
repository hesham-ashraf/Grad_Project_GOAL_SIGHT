import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/match_model.dart';
import '../../data/repositories/match_repository.dart';
import 'match_state.dart';

class MatchController extends StateNotifier<MatchState> {
  MatchController(this._matchRepository) : super(const MatchState());

  final MatchRepository _matchRepository;

  Future<void> loadMatches() async {
    state = state.copyWith(status: ViewStatus.loading, clearError: true);
    try {
      final matches = await _matchRepository.fetchMatches();
      state = state.copyWith(
        status: ViewStatus.success,
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

  Future<void> uploadMatch({
    required String homeTeam,
    required String awayTeam,
  }) async {
    await _matchRepository.uploadMatch(homeTeam: homeTeam, awayTeam: awayTeam);
    await loadMatches();
  }

  Future<MatchModel> fetchMatchDetails(String matchId) {
    return _matchRepository.fetchMatchDetails(matchId);
  }
}
