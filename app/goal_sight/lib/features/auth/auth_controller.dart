import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_roles.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository) : super(AuthState.initial());

  final IAuthRepository _authRepository;

  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _authRepository.restoreSession();
      final token = await _authRepository.getToken();
      state = user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : state.copyWith(
              status: AuthStatus.authenticated,
              user: user,
              token: token,
              clearError: true,
            );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Session restore failed. ${error.toString()}',
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user =
          await _authRepository.login(email: email, password: password);
      final token = await _authRepository.getToken();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Login failed. ${error.toString()}',
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      final token = await _authRepository.getToken();
      state = state.copyWith(
        status: AuthStatus.emailVerificationRequired,
        user: user,
        token: token,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Registration failed. ${error.toString()}',
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    await _authRepository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> verifyEmail({required String code}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (code.trim().length < 4) {
      state = state.copyWith(
        status: AuthStatus.emailVerificationRequired,
        errorMessage: 'Enter the verification code sent to your email.',
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.authenticated,
      clearError: true,
    );
  }

  Future<void> resendVerificationEmail() async {
    state = state.copyWith(clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
