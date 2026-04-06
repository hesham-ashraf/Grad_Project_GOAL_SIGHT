import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/state_management/router_provider.dart';

void main() {
  runApp(const ProviderScope(child: GoalSightApp()));
}

class GoalSightApp extends ConsumerWidget {
  const GoalSightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Goal Sight AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final scale = (mediaQuery.size.width / 390).clamp(0.92, 1.12);

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
