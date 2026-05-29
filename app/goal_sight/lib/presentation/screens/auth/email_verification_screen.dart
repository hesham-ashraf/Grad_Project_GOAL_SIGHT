import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/auth_state.dart';
import '../../../providers/app_providers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_card_widgets.dart';
import '../../widgets/goalsight_logo.dart';
import '../../widgets/primary_button.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController(text: '2026');
  bool _resent = false;

  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _codeController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    await HapticService.medium();
    await ref.read(authControllerProvider.notifier).verifyEmail(
          code: _codeController.text.trim(),
        );
  }

  Future<void> _resend() async {
    await HapticService.light();
    await ref.read(authControllerProvider.notifier).resendVerificationEmail();
    if (!mounted) return;
    setState(() => _resent = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final loading = authState.status == AuthStatus.loading;
    final hasError =
        authState.errorMessage != null &&
        authState.status == AuthStatus.error;

    return AuthBackground(
      child: SafeArea(
        child: Column(
          children: [
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
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) context.go('/register');
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
                    child: FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: Column(
                          children: [
                            GoalSightLogo(
                              iconSize: context.rs(58, min: 48, max: 72),
                              showSubtitle: false,
                            ),
                            SizedBox(height: context.rs(26, min: 18, max: 34)),
                            AuthCard(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Email icon
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentCyan
                                            .withValues(alpha: 0.10),
                                        borderRadius:
                                            BorderRadius.circular(15),
                                        border: Border.all(
                                          color: AppColors.accentCyan
                                              .withValues(alpha: 0.30),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.mark_email_unread_outlined,
                                        color: AppColors.accentCyan,
                                        size: 24,
                                      ),
                                    ),

                                    SizedBox(
                                      height: context.rs(16, min: 12, max: 20),
                                    ),

                                    const AuthGradientTitle(
                                      text: 'Verify Email',
                                      fontSize: 24,
                                    ),

                                    SizedBox(
                                      height: context.rs(6, min: 4, max: 8),
                                    ),

                                    Text(
                                      user?.email != null
                                          ? 'A verification code was sent to ${user!.email}.\nUse code 2026 for the Phase 1 mock flow.'
                                          : 'Enter the verification code sent to your email.\nUse code 2026 for the Phase 1 mock flow.',
                                      style: AppTextStyles.body(
                                        color: AppColors.textMuted,
                                      ).copyWith(fontSize: 13),
                                    ),

                                    SizedBox(
                                      height:
                                          context.rs(24, min: 16, max: 30),
                                    ),

                                    // Code field
                                    AppTextField(
                                      label: 'Verification Code',
                                      hintText: '2026',
                                      controller: _codeController,
                                      keyboardType: TextInputType.number,
                                      suffixIcon: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Icon(
                                          Icons.verified_outlined,
                                          color: AppColors.accentCyan,
                                          size: 20,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Verification code is required';
                                        }
                                        if (value.trim().length < 4) {
                                          return 'Enter at least 4 digits';
                                        }
                                        return null;
                                      },
                                    ),

                                    // Error state
                                    if (hasError) ...[
                                      SizedBox(
                                        height:
                                            context.rs(12, min: 8, max: 16),
                                      ),
                                      AuthErrorBox(
                                        message: authState.errorMessage!,
                                      ),
                                    ],

                                    // Resent confirmation
                                    if (_resent) ...[
                                      SizedBox(
                                        height:
                                            context.rs(12, min: 8, max: 16),
                                      ),
                                      const AuthSuccessBox(
                                        message:
                                            'A fresh verification code has been sent.',
                                      ),
                                    ],

                                    SizedBox(
                                      height: context.rs(22, min: 16, max: 28),
                                    ),

                                    // Verify button
                                    PrimaryButton(
                                      label: 'VERIFY AND CONTINUE',
                                      icon: Icons.verified_user_outlined,
                                      loading: loading,
                                      onPressed: _verify,
                                    ),

                                    SizedBox(
                                      height: context.rs(14, min: 10, max: 18),
                                    ),

                                    Center(
                                      child: TextButton(
                                        onPressed: loading ? null : _resend,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                        ),
                                        child: Text(
                                          'Resend verification code',
                                          style: AppTextStyles.caption(
                                            color: AppColors.textSecondary,
                                          ).copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),

                                    Center(
                                      child: TextButton(
                                        onPressed: loading
                                            ? null
                                            : () async {
                                                await HapticService.selection();
                                                await ref
                                                    .read(
                                                      authControllerProvider
                                                          .notifier,
                                                    )
                                                    .logout();
                                              },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                        ),
                                        child: Text(
                                          'Use another account',
                                          style: AppTextStyles.caption(
                                            color: AppColors.textMuted,
                                          ).copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
