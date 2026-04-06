import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../features/auth/auth_state.dart';
import '../../state_management/app_providers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/goalsight_logo.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _loginAs(UserRole role) async {
    final email = role == UserRole.admin
        ? 'admin@goalsight.ai'
        : role == UserRole.manager
            ? 'manager@goalsight.ai'
            : 'fan@goalsight.ai';

    _emailController.text = email;
    _passwordController.text = '123456';

    await ref.read(authControllerProvider.notifier).login(
          email: email,
          password: '123456',
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.status == AuthStatus.loading;

    return Theme(
      data: AppTheme.lightTheme(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
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
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const GoalSightLogo(iconSize: 64),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                              'Welcome to GOALSIGHT',
                              style: AppTheme.authTitleStyle(context),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your email address and password to use the application.',
                              style: AppTheme.authSubtitleStyle(context),
                            ),
                            const SizedBox(height: 20),
                            AppTextField(
                              label: 'Email / Username',
                              hintText: 'Enter your email or username',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'Password',
                              hintText: 'Enter your password',
                              controller: _passwordController,
                              obscureText: true,
                              validator: Validators.password,
                              suffixIcon: const Icon(
                                Icons.remove_red_eye_outlined,
                                color: Color(0xFF8A97B6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) => setState(
                                        () => _rememberMe = value ?? false),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Remember Me'),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('Forget Password?'),
                                ),
                              ],
                            ),
                            if (authState.status == AuthStatus.error &&
                                authState.errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                authState.errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ],
                            const SizedBox(height: 10),
                            PrimaryButton(
                              label: 'SIGN IN',
                              loading: loading,
                              icon: Icons.login_rounded,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: const [
                                Expanded(
                                    child: Divider(color: Color(0xFFD8DFED))),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'Or login with',
                                    style: TextStyle(color: Color(0xFF68789B)),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(color: Color(0xFFD8DFED))),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.facebook,
                                        color: Color(0xFF1877F2)),
                                    label: const Text('Facebook'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Text(
                                      'G',
                                      style: TextStyle(
                                        color: Color(0xFFDB4437),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    label: const Text('Google'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6FB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Quick Demo Login',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF5F6D8D),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: loading
                                            ? null
                                            : () => _loginAs(UserRole.fan),
                                        child: const Text('Enter as Fan'),
                                      ),
                                      OutlinedButton(
                                        onPressed: loading
                                            ? null
                                            : () => _loginAs(UserRole.manager),
                                        child: const Text('Enter as Manager'),
                                      ),
                                      OutlinedButton(
                                        onPressed: loading
                                            ? null
                                            : () => _loginAs(UserRole.admin),
                                        child: const Text('Enter as Admin'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: () => context.push('/register'),
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(color: Color(0xFF23304C)),
                                    children: [
                                      TextSpan(text: "Don't have an account? "),
                                      TextSpan(
                                        text: 'Register Now',
                                        style: TextStyle(
                                          color: AppTheme.brandPurple,
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
                    const SizedBox(height: 14),
                    const Text(
                      '(c) 2026 GOALSIGHT. Premium Football Analytics Platform.',
                      style: TextStyle(color: Color(0xFF8A95B2), fontSize: 12),
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
