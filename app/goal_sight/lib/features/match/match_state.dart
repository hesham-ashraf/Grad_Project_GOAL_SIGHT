import '../../data/models/match_model.dart';

enum ViewStatus { initial, loading, success, error }

class MatchState {
  const MatchState({
    this.status = ViewStatus.initial,
    this.matches = const [],
    this.errorMessage,
  });

  final ViewStatus status;
  final List<MatchModel> matches;
  final String? errorMessage;

  MatchState copyWith({
    ViewStatus? status,
    List<MatchModel>? matches,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MatchState(
      status: status ?? this.status,
      matches: matches ?? this.matches,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
