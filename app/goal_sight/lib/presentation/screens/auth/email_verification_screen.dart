import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/auth_state.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/otp_input.dart';
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
  String _otp = '';
  bool _resent = false;
  int _resendCountdown = 0;
  Timer? _timer;

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
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) t.cancel();
      });
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 6) return;
    await HapticService.medium();
    await ref.read(authControllerProvider.notifier).verifyEmail(code: _otp);
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;
    await HapticService.light();
    await ref.read(authControllerProvider.notifier).resendVerificationEmail();
    if (!mounted) return;
    setState(() => _resent = true);
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final loading = authState.status == AuthStatus.loading;
    final hasError =
        authState.errorMessage != null && authState.status == AuthStatus.error;

    return AuthBackground(
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) {
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header icon
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentCyan
                                          .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(15),
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
                                        ? 'We sent a 6-digit code to ${user!.email}. Enter it below.'
                                        : 'Enter the 6-digit code sent to your email.',
                                    style: AppTextStyles.body(
                                      color: AppColors.textMuted,
                                    ).copyWith(fontSize: 13),
                                  ),

                                  SizedBox(
                                    height: context.rs(28, min: 20, max: 36),
                                  ),

                                  // 6-box OTP
                                  OtpInput(
                                    enabled: !loading,
                                    onChanged: (v) =>
                                        setState(() => _otp = v),
                                    onCompleted: (v) {
                                      setState(() => _otp = v);
                                      _verify();
                                    },
                                  ),

                                  // Error state
                                  if (hasError) ...[
                                    SizedBox(
                                      height: context.rs(16, min: 12, max: 20),
                                    ),
                                    AuthErrorBox(
                                      message: authState.errorMessage!,
                                    ),
                                  ],

                                  // Resent confirmation
                                  if (_resent && !hasError) ...[
                                    SizedBox(
                                      height: context.rs(16, min: 12, max: 20),
                                    ),
                                    const AuthSuccessBox(
                                      message:
                                          'A fresh verification code has been sent.',
                                    ),
                                  ],

                                  SizedBox(
                                    height: context.rs(24, min: 18, max: 30),
                                  ),

                                  // Verify button
                                  PrimaryButton(
                                    label: 'VERIFY AND CONTINUE',
                                    icon: Icons.verified_user_outlined,
                                    loading: loading,
                                    onPressed: _otp.length == 6 ? _verify : null,
                                  ),

                                  SizedBox(
                                    height: context.rs(14, min: 10, max: 18),
                                  ),

                                  // Resend with cooldown
                                  Center(
                                    child: TextButton(
                                      onPressed: loading || _resendCountdown > 0
                                          ? null
                                          : _resend,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                      child: Text(
                                        _resendCountdown > 0
                                            ? 'Resend code in ${_resendCountdown}s'
                                            : 'Resend verification code',
                                        style: AppTextStyles.caption(
                                          color: _resendCountdown > 0
                                              ? AppColors.textMuted
                                              : AppColors.textSecondary,
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
