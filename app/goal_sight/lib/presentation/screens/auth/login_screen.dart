import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../features/auth/auth_state.dart';
import '../../../providers/app_providers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_card_widgets.dart';
import '../../widgets/goalsight_logo.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;

  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;
  static const int _n = 4;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fades = List.generate(_n, (i) {
      final start = (i * 0.14).clamp(0.0, 0.80);
      final end = (start + 0.30).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _slides = _fades
        .map(
          (f) => Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(f),
        )
        .toList();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await HapticService.medium();
    await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _demoLogin(String email, String password) async {
    await HapticService.selection();
    _emailController.text = email;
    _passwordController.text = password;
    await ref.read(authControllerProvider.notifier).login(
          email: email,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.status == AuthStatus.loading;
    final hasError =
        authState.status == AuthStatus.error &&
        authState.errorMessage != null;

    return AuthBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: context.padAll(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  SizedBox(height: context.rs(8, min: 4, max: 16)),

                  // ── Logo & tagline ─────────────────────────────────────
                  _reveal(
                    0,
                    GoalSightLogo(
                      iconSize: context.rs(62, min: 52, max: 78),
                      showSubtitle: false,
                    ),
                  ),

                  SizedBox(height: context.rs(28, min: 20, max: 38)),

                  // ── Auth card ──────────────────────────────────────────
                  _reveal(
                    1,
                    AuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            const AuthGradientTitle(text: 'Welcome Back'),
                            SizedBox(height: context.rs(5, min: 3, max: 8)),
                            Text(
                              'Sign in to access your analytics dashboard',
                              style: AppTextStyles.body(
                                color: AppColors.textMuted,
                              ).copyWith(fontSize: 13),
                            ),

                            SizedBox(height: context.rs(24, min: 18, max: 32)),

                            // Email
                            AppTextField(
                              label: 'Email Address',
                              hintText: 'you@club.com',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),

                            SizedBox(height: context.rs(14, min: 10, max: 18)),

                            // Password
                            AppTextField(
                              label: 'Password',
                              hintText: 'Enter your password',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: Validators.password,
                              suffixIcon: PasswordToggleIcon(
                                obscure: _obscurePassword,
                                onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),

                            SizedBox(height: context.rs(12, min: 8, max: 16)),

                            // Remember me + forgot password
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(
                                      () => _rememberMe = v ?? false,
                                    ),
                                    activeColor: AppColors.primaryPurple,
                                    side: const BorderSide(
                                      color: AppColors.outline,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: AppTextStyles.caption(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: loading
                                      ? null
                                      : () => context.push('/forgot-password'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: AppTextStyles.caption(
                                      color: AppColors.primaryPurple,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),

                            // Error state
                            if (hasError) ...[
                              SizedBox(height: context.rs(14, min: 10, max: 18)),
                              AuthErrorBox(message: authState.errorMessage!),
                            ],

                            SizedBox(height: context.rs(22, min: 16, max: 28)),

                            // Sign In button
                            PrimaryButton(
                              label: 'SIGN IN',
                              loading: loading,
                              icon: Icons.login_rounded,
                              onPressed: _submit,
                            ),

                            SizedBox(height: context.rs(20, min: 14, max: 26)),

                            // Google sign-in
                            const AuthDividerLabel(label: 'Or continue with'),
                            SizedBox(height: context.rs(14, min: 10, max: 18)),
                            _GoogleSignInButton(loading: loading),

                            SizedBox(height: context.rs(20, min: 14, max: 26)),

                            // Demo login — dev only
                            if (kDebugMode) ...[
                              const AuthDividerLabel(label: 'Quick Demo'),
                              SizedBox(height: context.rs(14, min: 10, max: 18)),
                              DemoLoginSection(
                                loading: loading,
                                onLogin: _demoLogin,
                              ),
                              SizedBox(height: context.rs(20, min: 14, max: 26)),
                            ],

                            // Register link
                            Center(
                              child: GestureDetector(
                                onTap: () => context.push('/register'),
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.body(
                                      color: AppColors.textSecondary,
                                    ).copyWith(fontSize: 13),
                                    children: const [
                                      TextSpan(
                                        text: "Don't have an account? ",
                                      ),
                                      TextSpan(
                                        text: 'Register Now',
                                        style: TextStyle(
                                          color: AppColors.primaryPurple,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: context.rs(24, min: 16, max: 32)),

                  // Footer
                  _reveal(
                    3,
                    Text(
                      '© 2026 GOALSIGHT. Premium Football Analytics Platform.',
                      style: AppTextStyles.caption(
                        color: AppColors.textMuted.withValues(alpha: 0.55),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: context.rs(12, min: 8, max: 20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Google Sign-In Button ────────────────────────────────────────────────────

class _GoogleSignInButton extends ConsumerWidget {
  const _GoogleSignInButton({required this.loading});
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: loading
            ? null
            : () async {
                await HapticService.medium();
                await ref
                    .read(authControllerProvider.notifier)
                    .signInWithGoogle();
              },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.outlineSubtle),
          backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryPurple,
                ),
              )
            : const _GoogleIcon(),
        label: Text(
          'Continue with Google',
          style: AppTextStyles.button(color: AppColors.textPrimary).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    // Simple "G" colored circle as a stand-in; replace with official SVG asset.
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
