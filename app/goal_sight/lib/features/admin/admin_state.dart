import '../../data/models/match_model.dart';
import '../../data/models/system_overview_model.dart';
import '../../data/models/user_model.dart';
import '../match/match_state.dart';

class AdminState {
  const AdminState({
    this.status = ViewStatus.initial,
    this.overview,
    this.users = const [],
    this.matches = const [],
    this.isSubmittingMatch = false,
    this.errorMessage,
  });

  final ViewStatus status;
  final SystemOverviewModel? overview;
  final List<UserModel> users;
  final List<MatchModel> matches;
  final bool isSubmittingMatch;
  final String? errorMessage;

  AdminState copyWith({
    ViewStatus? status,
    SystemOverviewModel? overview,
    List<UserModel>? users,
    List<MatchModel>? matches,
    bool? isSubmittingMatch,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      users: users ?? this.users,
      matches: matches ?? this.matches,
      isSubmittingMatch: isSubmittingMatch ?? this.isSubmittingMatch,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
