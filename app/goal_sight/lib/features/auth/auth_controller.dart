import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/constants/app_roles.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Maps backend errors to a user-friendly message.
String _authError(Object error) {
  if (error is AuthException) return error.message;
  return 'Something went wrong. Please try again.';
}

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
        status: AuthStatus.unauthenticated,
        errorMessage: _authError(error),
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
        errorMessage: _authError(error),
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
      // A token means email confirmation is disabled → straight in.
      // No token means a confirmation email/OTP was sent.
      state = state.copyWith(
        status: token != null
            ? AuthStatus.authenticated
            : AuthStatus.emailVerificationRequired,
        user: user,
        token: token,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _authError(error),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    await _authRepository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> verifyEmail({required String code}) async {
    final email = state.user?.email;
    if (email == null || email.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Missing email for verification. Please sign in again.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user =
          await _authRepository.verifyEmailOtp(email: email, token: code);
      final token = await _authRepository.getToken();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
        clearError: true,
      );
    } catch (error) {
      // Keep the user on the verification screen with the error shown.
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _authError(error),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _authRepository.signInWithGoogle();
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
        errorMessage: _authError(error),
      );
    }
  }

  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _authRepository.verifyPasswordResetOtp(email: email, token: token);
      // Keep email in state so the next step (update password) knows the address.
      state = state.copyWith(
        status: AuthStatus.passwordResetOtpVerified,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _authError(error),
      );
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _authRepository.updatePassword(newPassword);
      // After password update, sign out so the user logs in fresh.
      await _authRepository.logout();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _authError(error),
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    final email = state.user?.email;
    if (email == null || email.isEmpty) return;
    state = state.copyWith(clearError: true);
    try {
      await _authRepository.resendVerification(email);
    } catch (_) {
      // Non-fatal; the screen shows its own "resent" confirmation.
    }
  }
}
