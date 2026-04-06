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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = true;
  UserRole _selectedRole = UserRole.manager;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) return;

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
                              'Create Your Account',
                              style: AppTheme.authTitleStyle(context).copyWith(
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join GOALSIGHT and start analyzing football matches like a pro.',
                              style: AppTheme.authSubtitleStyle(context),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Full Name',
                              hintText: 'Enter your full name',
                              controller: _nameController,
                              validator: (value) =>
                                  Validators.requiredField(value, 'Name'),
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'Email Address',
                              hintText: 'Enter your email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'Password',
                              hintText: 'Create a strong password',
                              controller: _passwordController,
                              obscureText: true,
                              validator: Validators.password,
                              suffixIcon: const Icon(
                                Icons.remove_red_eye_outlined,
                                color: Color(0xFF8A97B6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              controller: _confirmPasswordController,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirm password is required';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              suffixIcon: const Icon(
                                Icons.remove_red_eye_outlined,
                                color: Color(0xFF8A97B6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Account Type',
                              style: TextStyle(
                                color: Color(0xFF4B587A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                ChoiceChip(
                                  label: const Text('Fan'),
                                  selected: _selectedRole == UserRole.fan,
                                  onSelected: (_) => setState(
                                    () => _selectedRole = UserRole.fan,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Manager'),
                                  selected: _selectedRole == UserRole.manager,
                                  onSelected: (_) => setState(
                                    () => _selectedRole = UserRole.manager,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Admin'),
                                  selected: _selectedRole == UserRole.admin,
                                  onSelected: (_) => setState(
                                    () => _selectedRole = UserRole.admin,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 22,
                                  child: Checkbox(
                                    value: _acceptTerms,
                                    onChanged: (value) => setState(
                                      () => _acceptTerms = value ?? false,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'I agree to the ',
                                      style:
                                          TextStyle(color: Color(0xFF68789B)),
                                      children: [
                                        TextSpan(
                                          text: 'Terms & Conditions',
                                          style: TextStyle(
                                            color: AppTheme.brandPurple,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyle(
                                            color: AppTheme.brandPurple,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!_acceptTerms)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'You need to accept terms to continue',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            if (authState.status == AuthStatus.error &&
                                authState.errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                authState.errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ],
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'CREATE ACCOUNT',
                              loading: loading,
                              icon: Icons.person_add_alt_1_rounded,
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
                                    'Or register with',
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
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.push('/login');
                                  }
                                },
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(color: Color(0xFF23304C)),
                                    children: [
                                      TextSpan(
                                          text: 'Already have an account? '),
                                      TextSpan(
                                        text: 'Sign In',
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
