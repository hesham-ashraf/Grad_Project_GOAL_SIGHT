import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_roles.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository) : super(AuthState.initial());

  final IAuthRepository _authRepository;

  Future<void> restoreSession() async {
    if (state.status == AuthStatus.loading) return;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _authRepository.restoreSession();
      final token = await _authRepository.getToken();

      if (user == null || token == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
        return;
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: error.toString(),
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
        status: AuthStatus.authenticated,
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
    await _authRepository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
