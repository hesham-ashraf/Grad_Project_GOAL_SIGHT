import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthException,
        OAuthProvider,
        OtpType,
        Session,
        Supabase,
        SupabaseClient,
        User,
        UserAttributes;

import '../../core/constants/app_roles.dart';
import '../../core/services/secure_storage_service.dart';
import '../models/user_model.dart';

/// Auth contract. The Supabase implementation lives below; callers depend only
/// on this interface so the backend can be swapped without UI changes.
abstract interface class IAuthRepository {
  Future<UserModel> login({required String email, required String password});

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  /// Restores the persisted Supabase session (if any) on app launch.
  Future<UserModel?> restoreSession();

  Future<void> logout();

  /// Current access token, or null when signed out.
  Future<String?> getToken();

  /// Sends a password-reset OTP email.
  Future<void> sendPasswordReset(String email);

  /// Re-sends the signup confirmation email/OTP.
  Future<void> resendVerification(String email);

  /// Signs in via Google OAuth; returns the authenticated user.
  Future<UserModel> signInWithGoogle();

  /// Verifies a password-reset OTP and returns a live session.
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  });

  /// Updates the authenticated user's password (call after [verifyPasswordResetOtp]).
  Future<void> updatePassword(String newPassword);

  /// Confirms a signup using the emailed OTP [token].
  Future<UserModel> verifyEmailOtp({
    required String email,
    required String token,
  });
}

/// Supabase-backed authentication. Roles are read from the `profiles` table
/// (the source of truth, written by the `handle_new_user` trigger at signup) —
/// never trusted from user metadata for routing decisions.
class SupabaseAuthRepository implements IAuthRepository {
  SupabaseAuthRepository(this._storage);

  final SecureStorageService _storage;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw const AuthException('Invalid email or password.');
    }
    return _hydrate(user, res.session);
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim(), 'role': role.value},
    );
    final user = res.user;
    if (user == null) {
      throw const AuthException('Registration failed. Please try again.');
    }

    // When email confirmation is disabled, Supabase returns a live session and
    // the user is authenticated immediately. Otherwise the profile already
    // exists (created by the signup trigger) but no session is issued yet.
    if (res.session != null) {
      return _hydrate(user, res.session);
    }

    await _storage.saveRole(role.value);
    return UserModel(
      id: user.id,
      name: name.trim(),
      email: email.trim(),
      role: role,
    );
  }

  @override
  Future<UserModel> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final res = await _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.signup,
    );
    final user = res.user;
    if (user == null) {
      throw const AuthException('Invalid or expired verification code.');
    }
    return _hydrate(user, res.session);
  }

  @override
  Future<void> resendVerification(String email) {
    return _client.auth.resend(type: OtpType.signup, email: email.trim());
  }

  @override
  Future<void> sendPasswordReset(String email) {
    // Uses Supabase's OTP-mode reset (configure "OTP" email template in dashboard).
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    // TODO: Set the webClientId from your Google Cloud Console OAuth credential.
    // Enable Google provider in Supabase Dashboard → Auth → Providers → Google.
    const webClientId =
        'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com';
    final googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign-in cancelled.');
    }
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthException('Google sign-in failed: no ID token.');
    }
    final res = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    final user = res.user;
    if (user == null) throw const AuthException('Google sign-in failed.');
    return _hydrate(user, res.session);
  }

  @override
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    final res = await _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.recovery,
    );
    if (res.user == null) {
      throw const AuthException('Invalid or expired reset code.');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  @override
  Future<UserModel?> restoreSession() async {
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser;
    if (session == null || user == null) return null;
    return _hydrate(user, session);
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
    await _storage.clearSession();
  }

  @override
  Future<String?> getToken() async {
    return _client.auth.currentSession?.accessToken;
  }

  /// Builds a [UserModel] from the auth user + the `profiles` row (role/name),
  /// and mirrors the token/role into secure storage for non-Supabase consumers
  /// (e.g. the live-match WebSocket).
  Future<UserModel> _hydrate(User user, Session? session) async {
    var role = UserRole.fan;
    var name = user.userMetadata?['full_name']?.toString() ??
        user.email ??
        'User';

    try {
      final profile = await _client
          .from('profiles')
          .select('full_name, role')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null) {
        role = parseUserRole((profile['role'] ?? 'fan').toString());
        final fullName = profile['full_name']?.toString();
        if (fullName != null && fullName.isNotEmpty) name = fullName;
      }
    } catch (_) {
      // Profile not readable yet (transient/RLS) — fall back to metadata role.
      final metaRole = user.userMetadata?['role']?.toString();
      if (metaRole != null) role = parseUserRole(metaRole);
    }

    if (session != null) await _storage.saveToken(session.accessToken);
    await _storage.saveRole(role.value);

    return UserModel(
      id: user.id,
      name: name,
      email: user.email ?? '',
      role: role,
    );
  }
}
