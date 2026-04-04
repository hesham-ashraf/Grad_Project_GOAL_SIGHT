import '../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
