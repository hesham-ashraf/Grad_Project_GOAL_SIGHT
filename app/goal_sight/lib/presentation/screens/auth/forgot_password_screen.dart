import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/goalsight_logo.dart';
import '../../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF23304C),
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
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: _sent ? _successContent(context) : _formContent(),
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

  Widget _formContent() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('reset-form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reset Password',
            style: AppTheme.authTitleStyle(context),
          ),
          SizedBox(height: context.rs(8, min: 5, max: 12)),
          Text(
            'Enter your account email and we will send a secure reset link.',
            style: AppTheme.authSubtitleStyle(context),
          ),
          SizedBox(height: context.rs(20, min: 12, max: 28)),
          AppTextField(
            label: 'Email Address',
            hintText: 'you@club.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          SizedBox(height: context.rs(16, min: 10, max: 22)),
          PrimaryButton(
            label: 'SEND RESET LINK',
            icon: Icons.mark_email_read_outlined,
            loading: _loading,
            onPressed: _sendResetLink,
          ),
          SizedBox(height: context.rs(10, min: 7, max: 14)),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to sign in'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successContent(BuildContext context) {
    final email = _emailController.text.trim();

    return Column(
      key: const ValueKey('reset-sent'),
      children: [
        Container(
          width: context.rs(64, min: 52, max: 78),
          height: context.rs(64, min: 52, max: 78),
          decoration: const BoxDecoration(
            color: Color(0xFFEAF8F0),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF1F9D5A),
            size: 34,
          ),
        ),
        SizedBox(height: context.rs(16, min: 10, max: 22)),
        Text(
          'Reset Link Sent',
          style: AppTheme.authTitleStyle(context),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.rs(8, min: 5, max: 12)),
        Text(
          'Check $email for password reset instructions. This is a mock Phase 1 flow, so no email is actually sent yet.',
          style: AppTheme.authSubtitleStyle(context),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.rs(18, min: 12, max: 24)),
        PrimaryButton(
          label: 'RETURN TO SIGN IN',
          icon: Icons.login_rounded,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
