import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_roles.dart';
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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final UserRole _selectedRole = UserRole.fan;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) return;
    await HapticService.medium();
    await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
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
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: context.padAll(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        // ── Logo ────────────────────────────────────────
                        _reveal(
                          0,
                          GoalSightLogo(
                            iconSize: context.rs(56, min: 46, max: 70),
                            showSubtitle: false,
                          ),
                        ),

                        SizedBox(height: context.rs(22, min: 16, max: 30)),

                        // ── Card ─────────────────────────────────────────
                        _reveal(
                          1,
                          AuthCard(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  const AuthGradientTitle(
                                    text: 'Create Account',
                                    fontSize: 26,
                                  ),
                                  SizedBox(height: context.rs(5, min: 3, max: 8)),
                                  Text(
                                    'Join GOALSIGHT and analyze football like a pro.',
                                    style: AppTextStyles.body(
                                      color: AppColors.textMuted,
                                    ).copyWith(fontSize: 13),
                                  ),

                                  SizedBox(height: context.rs(22, min: 16, max: 28)),

                                  // Full name
                                  AppTextField(
                                    label: 'Full Name',
                                    hintText: 'Enter your full name',
                                    controller: _nameController,
                                    validator: (v) =>
                                        Validators.requiredField(v, 'Name'),
                                  ),

                                  SizedBox(height: context.rs(12, min: 8, max: 16)),

                                  // Email
                                  AppTextField(
                                    label: 'Email Address',
                                    hintText: 'you@club.com',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: Validators.email,
                                  ),

                                  SizedBox(height: context.rs(12, min: 8, max: 16)),

                                  // Password
                                  AppTextField(
                                    label: 'Password',
                                    hintText: 'Create a strong password',
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    validator: Validators.password,
                                    suffixIcon: PasswordToggleIcon(
                                      obscure: _obscurePassword,
                                      onTap: () => setState(
                                        () =>
                                            _obscurePassword = !_obscurePassword,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: context.rs(12, min: 8, max: 16)),

                                  // Confirm password
                                  AppTextField(
                                    label: 'Confirm Password',
                                    hintText: 'Re-enter your password',
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    suffixIcon: PasswordToggleIcon(
                                      obscure: _obscureConfirmPassword,
                                      onTap: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Confirm password is required';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: context.rs(16, min: 10, max: 20)),

                                  // Terms
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _acceptTerms = !_acceptTerms,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: _acceptTerms,
                                            onChanged: (v) => setState(
                                              () => _acceptTerms = v ?? false,
                                            ),
                                            activeColor: AppColors.primaryPurple,
                                            side: const BorderSide(
                                              color: AppColors.outline,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: AppTextStyles.caption(
                                                color: AppColors.textSecondary,
                                              ),
                                              children: const [
                                                TextSpan(
                                                  text: 'I agree to the ',
                                                ),
                                                TextSpan(
                                                  text: 'Terms & Conditions',
                                                  style: TextStyle(
                                                    color: AppColors.primaryPurple,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                TextSpan(text: ' and '),
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  style: TextStyle(
                                                    color: AppColors.primaryPurple,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (!_acceptTerms) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'You must accept the terms to continue',
                                      style: AppTextStyles.caption(
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],

                                  // Error state
                                  if (hasError) ...[
                                    SizedBox(height: context.rs(14, min: 10, max: 18)),
                                    AuthErrorBox(
                                      message: authState.errorMessage!,
                                    ),
                                  ],

                                  SizedBox(height: context.rs(22, min: 16, max: 28)),

                                  // Create account button
                                  PrimaryButton(
                                    label: 'CREATE ACCOUNT',
                                    loading: loading,
                                    icon: Icons.person_add_alt_1_rounded,
                                    onPressed: _submit,
                                  ),

                                  SizedBox(height: context.rs(18, min: 12, max: 24)),

                                  // Sign in link
                                  Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go('/login');
                                        }
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          style: AppTextStyles.body(
                                            color: AppColors.textSecondary,
                                          ).copyWith(fontSize: 13),
                                          children: const [
                                            TextSpan(
                                              text: 'Already have an account? ',
                                            ),
                                            TextSpan(
                                              text: 'Sign In',
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

                        SizedBox(height: context.rs(20, min: 12, max: 28)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
