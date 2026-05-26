import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/auth_state.dart';
import '../../state_management/app_providers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/goalsight_logo.dart';
import '../../widgets/primary_button.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController(text: '2026');
  bool _resent = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).verifyEmail(
          code: _codeController.text.trim(),
        );
  }

  Future<void> _resend() async {
    await ref.read(authControllerProvider.notifier).resendVerificationEmail();
    if (!mounted) return;
    setState(() => _resent = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final loading = authState.status == AuthStatus.loading;

    return Theme(
      data: AppTheme.lightTheme(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF23304C),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/register');
            },
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF3F5F9), Color(0xFFEDEFF5)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: context.padAll(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    GoalSightLogo(iconSize: context.rs(64, min: 54, max: 80)),
                    SizedBox(height: context.rs(22, min: 16, max: 28)),
                    Container(
                      padding: context.padSym(h: 24, v: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          context.rs(20, min: 14, max: 26),
                        ),
                        border: Border.all(color: const Color(0xFFDCE3F1)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify Your Email',
                              style: AppTheme.authTitleStyle(context),
                            ),
                            SizedBox(height: context.rs(8, min: 5, max: 12)),
                            Text(
                              'We sent a verification code to ${user?.email ?? 'your email'}. Use 2026 for the Phase 1 mock flow.',
                              style: AppTheme.authSubtitleStyle(context),
                            ),
                            SizedBox(height: context.rs(20, min: 12, max: 28)),
                            AppTextField(
                              label: 'Verification Code',
                              hintText: '2026',
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Verification code is required';
                                }
                                if (value.trim().length < 4) {
                                  return 'Enter at least 4 digits';
                                }
                                return null;
                              },
                              suffixIcon: const Icon(Icons.verified_outlined),
                            ),
                            if (authState.errorMessage != null) ...[
                              SizedBox(height: context.rs(8, min: 5, max: 12)),
                              Text(
                                authState.errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ],
                            if (_resent) ...[
                              SizedBox(height: context.rs(8, min: 5, max: 12)),
                              const Text(
                                'A fresh mock verification code was sent.',
                                style: TextStyle(color: Color(0xFF1F9D5A)),
                              ),
                            ],
                            SizedBox(height: context.rs(16, min: 10, max: 22)),
                            PrimaryButton(
                              label: 'VERIFY AND CONTINUE',
                              icon: Icons.verified_user_outlined,
                              loading: loading,
                              onPressed: _verify,
                            ),
                            SizedBox(height: context.rs(10, min: 7, max: 14)),
                            Center(
                              child: TextButton(
                                onPressed: loading ? null : _resend,
                                child: const Text('Resend verification code'),
                              ),
                            ),
                            Center(
                              child: TextButton(
                                onPressed: loading
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        ref
                                            .read(authControllerProvider.notifier)
                                            .logout();
                                      },
                                child: const Text('Use another account'),
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
    );
  }
}
