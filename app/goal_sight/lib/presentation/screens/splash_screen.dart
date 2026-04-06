import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_state.dart';
import '../state_management/app_providers.dart';
import '../widgets/goalsight_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _restored = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;

    _restored = true;
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider).status;
    final isLoading =
        status == AuthStatus.loading || status == AuthStatus.initial;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F5F9), Color(0xFFEDEFF5)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GoalSightLogo(iconSize: context.rs(74, min: 58, max: 90)),
              SizedBox(height: context.rs(24, min: 16, max: 32)),
              if (isLoading)
                const CircularProgressIndicator(color: AppTheme.brandBlue),
            ],
          ),
        ),
      ),
    );
  }
}
