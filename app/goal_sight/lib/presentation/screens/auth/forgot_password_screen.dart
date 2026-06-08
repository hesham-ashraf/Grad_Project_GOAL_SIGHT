import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/app_providers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_card_widgets.dart';
import '../../widgets/goalsight_logo.dart';
import '../../widgets/primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

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
    _emailController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sent = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Could not send reset email. Please check the address and try again.';
      });
    }
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () => context.go('/login'),
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
                                duration: const Duration(milliseconds: 360),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.06),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                ),
                                child: _sent
                                    ? _SuccessState(
                                        key: const ValueKey('sent'),
                                        email: _emailController.text.trim(),
                                      )
                                    : _FormState(
                                        key: const ValueKey('form'),
                                        formKey: _formKey,
                                        emailController: _emailController,
                                        loading: _loading,
                                        error: _error,
                                        onSubmit: _sendResetLink,
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

// ─── Form state ───────────────────────────────────────────────────────────────

class _FormState extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _FormState({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.3),
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
            'Enter your email and we\'ll send a secure reset link.',
            style: AppTextStyles.body(color: AppColors.textMuted).copyWith(
              fontSize: 13,
            ),
          ),

          SizedBox(height: context.rs(24, min: 16, max: 30)),

          AppTextField(
            label: 'Email Address',
            hintText: 'you@club.com',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),

          if (error != null) ...[
            SizedBox(height: context.rs(14, min: 10, max: 18)),
            AuthErrorBox(message: error!),
          ],

          SizedBox(height: context.rs(22, min: 16, max: 28)),

          PrimaryButton(
            label: 'SEND RESET LINK',
            icon: Icons.mark_email_read_outlined,
            loading: loading,
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
                style: AppTextStyles.caption(
                  color: AppColors.textSecondary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Success state ────────────────────────────────────────────────────────────

class _SuccessState extends StatelessWidget {
  final String email;
  const _SuccessState({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Success ring icon
        Container(
          width: context.rs(68, min: 56, max: 84),
          height: context.rs(68, min: 56, max: 84),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentGreen.withValues(alpha: 0.10),
            border: Border.all(
              color: AppColors.accentGreen.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.check_rounded,
            color: AppColors.accentGreen,
            size: context.rs(30, min: 24, max: 38),
          ),
        ),

        SizedBox(height: context.rs(20, min: 14, max: 26)),

        const AuthGradientTitle(text: 'Link Sent!', fontSize: 24),

        SizedBox(height: context.rs(10, min: 6, max: 14)),

        Text(
          email.isNotEmpty
              ? 'Check $email for a secure password reset link.'
              : 'Check your inbox for a secure password reset link.',
          style: AppTextStyles.body(
            color: AppColors.textMuted,
          ).copyWith(fontSize: 13),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.rs(26, min: 18, max: 32)),

        PrimaryButton(
          label: 'RETURN TO SIGN IN',
          icon: Icons.login_rounded,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
