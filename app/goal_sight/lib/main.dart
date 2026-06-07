import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/router_provider.dart';
import 'shared/goalsight_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load connection config from `.env`. Missing file is non-fatal: the app
  // simply runs without Supabase (mock data flows).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env bundled — leave dotenv empty so hasSupabaseConfig is false.
  }

  if (hasSupabaseConfig) {
    // Initialize Supabase once before the app starts.
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

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
          child: GoalSightAppStateOverlay(child: child ?? const SizedBox.shrink()),
        );
      },
      routerConfig: router,
    );
  }
}
