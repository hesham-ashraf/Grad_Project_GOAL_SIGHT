import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../features/auth/auth_state.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/otp_input.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_card_widgets.dart';
import '../../widgets/goalsight_logo.dart';
import '../../widgets/primary_button.dart';

enum _ResetStep { email, otp, newPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  _ResetStep _step = _ResetStep.email;

  // Step 1 — email
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  // Step 2 — OTP
  String _otp = '';
  int _resendCountdown = 0;
  Timer? _resendTimer;

  // Step 3 — new password
  final _pwFormKey = GlobalKey<FormState>();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();
  bool _obscurePw = true;
  bool _obscureConfirm = true;
  bool _pwLoading = false;
  String? _pwError;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
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

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    await HapticService.medium();
    final email = _emailController.text.trim();
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _step = _ResetStep.otp);
      _startResendCooldown();
    } catch (e) {
      // Show error via a setState; auth controller not involved for step 1.
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) return;
    await HapticService.medium();
    await ref.read(authControllerProvider.notifier).verifyPasswordResetOtp(
          email: _emailController.text.trim(),
          token: _otp,
        );
    if (!mounted) return;
    final status = ref.read(authControllerProvider).status;
    if (status == AuthStatus.passwordResetOtpVerified) {
      setState(() => _step = _ResetStep.newPassword);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;
    await HapticService.light();
    await ref
        .read(authRepositoryProvider)
        .sendPasswordReset(_emailController.text.trim());
    _startResendCooldown();
  }

  Future<void> _updatePassword() async {
    if (!_pwFormKey.currentState!.validate()) return;
    if (_pwController.text != _pwConfirmController.text) {
      setState(() => _pwError = 'Passwords do not match.');
      return;
    }
    setState(() {
      _pwLoading = true;
      _pwError = null;
    });
    await HapticService.medium();
    await ref
        .read(authControllerProvider.notifier)
        .updatePassword(_pwController.text);
    if (!mounted) return;
    setState(() => _pwLoading = false);
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () {
                    if (_step == _ResetStep.otp) {
                      setState(() => _step = _ResetStep.email);
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
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.04, 0),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                ),
                                child: switch (_step) {
                                  _ResetStep.email => _EmailStep(
                                      key: const ValueKey('email'),
                                      formKey: _emailFormKey,
                                      emailController: _emailController,
                                      onSubmit: _sendOtp,
                                    ),
                                  _ResetStep.otp => _OtpStep(
                                      key: const ValueKey('otp'),
                                      email: _emailController.text.trim(),
                                      resendCountdown: _resendCountdown,
                                      onChanged: (v) =>
                                          setState(() => _otp = v),
                                      onCompleted: (v) {
                                        setState(() => _otp = v);
                                        _verifyOtp();
                                      },
                                      onVerify: _verifyOtp,
                                      onResend: _resendOtp,
                                    ),
                                  _ResetStep.newPassword => _NewPasswordStep(
                                      key: const ValueKey('pw'),
                                      formKey: _pwFormKey,
                                      pwController: _pwController,
                                      confirmController: _pwConfirmController,
                                      obscurePw: _obscurePw,
                                      obscureConfirm: _obscureConfirm,
                                      loading: _pwLoading,
                                      error: _pwError,
                                      onTogglePw: () =>
                                          setState(() => _obscurePw = !_obscurePw),
                                      onToggleConfirm: () => setState(
                                            () => _obscureConfirm =
                                                !_obscureConfirm,
                                          ),
                                      onSubmit: _updatePassword,
                                    ),
                                },
                              ),
                            ),

                            // Step indicator
                            SizedBox(height: context.rs(20, min: 14, max: 26)),
                            _StepDots(
                              total: 3,
                              current: _step.index,
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

// ─── Step 1: Email ─────────────────────────────────────────────────────────────

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: AppColors.primaryPurple,
              size: 22,
            ),
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          const AuthGradientTitle(text: 'Reset Password', fontSize: 24),
          SizedBox(height: context.rs(6, min: 4, max: 8)),
          Text(
            'Enter your email and we\'ll send a 6-digit OTP to reset your password.',
            style:
                AppTextStyles.body(color: AppColors.textMuted).copyWith(fontSize: 13),
          ),
          SizedBox(height: context.rs(24, min: 16, max: 30)),
          AppTextField(
            label: 'Email Address',
            hintText: 'you@club.com',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          SizedBox(height: context.rs(22, min: 16, max: 28)),
          PrimaryButton(
            label: 'SEND OTP CODE',
            icon: Icons.mark_email_read_outlined,
            onPressed: onSubmit,
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                'Back to Sign In',
                style: AppTextStyles.caption(color: AppColors.textSecondary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: OTP ──────────────────────────────────────────────────────────────

class _OtpStep extends ConsumerWidget {
  const _OtpStep({
    super.key,
    required this.email,
    required this.resendCountdown,
    required this.onChanged,
    required this.onCompleted,
    required this.onVerify,
    required this.onResend,
  });

  final String email;
  final int resendCountdown;
  final void Function(String) onChanged;
  final void Function(String) onCompleted;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.status == AuthStatus.loading;
    final hasError =
        authState.status == AuthStatus.error && authState.errorMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accentCyan.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accentCyan.withValues(alpha: 0.30),
            ),
          ),
          child: const Icon(
            Icons.pin_outlined,
            color: AppColors.accentCyan,
            size: 22,
          ),
        ),
        SizedBox(height: context.rs(16, min: 12, max: 20)),
        const AuthGradientTitle(text: 'Enter OTP', fontSize: 24),
        SizedBox(height: context.rs(6, min: 4, max: 8)),
        Text(
          'We sent a 6-digit reset code to $email.',
          style: AppTextStyles.body(color: AppColors.textMuted)
              .copyWith(fontSize: 13),
        ),
        SizedBox(height: context.rs(28, min: 20, max: 36)),
        OtpInput(
          enabled: !loading,
          onChanged: onChanged,
          onCompleted: onCompleted,
        ),
        if (hasError) ...[
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          AuthErrorBox(message: authState.errorMessage!),
        ],
        SizedBox(height: context.rs(24, min: 18, max: 30)),
        PrimaryButton(
          label: 'VERIFY CODE',
          icon: Icons.verified_outlined,
          loading: loading,
          onPressed: onVerify,
        ),
        SizedBox(height: context.rs(14, min: 10, max: 18)),
        Center(
          child: TextButton(
            onPressed: !loading && resendCountdown == 0 ? onResend : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              resendCountdown > 0
                  ? 'Resend OTP in ${resendCountdown}s'
                  : 'Resend OTP',
              style: AppTextStyles.caption(
                color:
                    resendCountdown > 0 ? AppColors.textMuted : AppColors.textSecondary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Step 3: New password ─────────────────────────────────────────────────────

class _NewPasswordStep extends StatelessWidget {
  const _NewPasswordStep({
    super.key,
    required this.formKey,
    required this.pwController,
    required this.confirmController,
    required this.obscurePw,
    required this.obscureConfirm,
    required this.loading,
    required this.error,
    required this.onTogglePw,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController pwController;
  final TextEditingController confirmController;
  final bool obscurePw;
  final bool obscureConfirm;
  final bool loading;
  final String? error;
  final VoidCallback onTogglePw;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.accentGreen,
              size: 22,
            ),
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          const AuthGradientTitle(text: 'New Password', fontSize: 24),
          SizedBox(height: context.rs(6, min: 4, max: 8)),
          Text(
            'Choose a strong new password for your account.',
            style: AppTextStyles.body(color: AppColors.textMuted)
                .copyWith(fontSize: 13),
          ),
          SizedBox(height: context.rs(24, min: 16, max: 30)),
          AppTextField(
            label: 'New Password',
            hintText: 'At least 8 characters',
            controller: pwController,
            obscureText: obscurePw,
            validator: Validators.password,
            suffixIcon: PasswordToggleIcon(
              obscure: obscurePw,
              onTap: onTogglePw,
            ),
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          AppTextField(
            label: 'Confirm Password',
            hintText: 'Repeat your new password',
            controller: confirmController,
            obscureText: obscureConfirm,
            validator: (v) =>
                v == null || v.isEmpty ? 'Please confirm your password.' : null,
            suffixIcon: PasswordToggleIcon(
              obscure: obscureConfirm,
              onTap: onToggleConfirm,
            ),
          ),
          if (error != null) ...[
            SizedBox(height: context.rs(14, min: 10, max: 18)),
            AuthErrorBox(message: error!),
          ],
          SizedBox(height: context.rs(22, min: 16, max: 28)),
          PrimaryButton(
            label: 'UPDATE PASSWORD',
            icon: Icons.check_circle_outline_rounded,
            loading: loading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({required this.total, required this.current});
  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: isActive ? AppGradients.brand : null,
            color: isActive ? null : AppColors.outlineSubtle,
          ),
        );
      }),
    );
  }
}
