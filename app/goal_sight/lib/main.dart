import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'presentation/state_management/router_provider.dart';

// TODO: Paste your Supabase Project URL here (from Supabase Settings -> API).
const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';

// TODO: Paste your Supabase anon public key here (safe for client use).
// Do NOT use the service_role key in a client app.
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase once before the app starts.
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

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
