import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_roles.dart';
import '../../features/auth/auth_state.dart';
import '../../features/manager/screens/manager_navigation_screen.dart';
import '../../data/models/club_model.dart';
import '../../data/models/match_analysis_model.dart';
import '../../features/supabase_test/test_supabase_page.dart';
import '../screens/admin/admin_panel_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/admin_dashboard_screen.dart';
import '../screens/fan/club_details_screen.dart';
import '../screens/fan/fan_navigation_screen.dart';
import '../screens/manager/manager_panel_screen.dart';
import '../screens/match/live_match_screen.dart';
import '../screens/match/match_details_screen.dart';
import '../screens/player/player_profile_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/fan/match_analysis_screen.dart';
import 'app_providers.dart';

// Temporary: set to false when you finish Supabase testing.
const bool kShowSupabaseTestPage = false;

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: kShowSupabaseTestPage ? '/supabase-test' : '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthPage = location == '/login' || location == '/register';
      final isSplash = location == '/splash';
      final isSupabaseTest = location == '/supabase-test';
      final isAdminRoute =
          location.startsWith('/admin') || location == '/admin-panel';
      final isManagerRoute = location.startsWith('/manager');
      final isFanRoute = location.startsWith('/fan');

      // Allow the test page without auth redirects.
      if (isSupabaseTest) return null;

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return isSplash ? null : '/splash';
      }

      if (authState.status != AuthStatus.authenticated ||
          authState.user == null) {
        return isAuthPage ? null : '/login';
      }

      final role = authState.user!.role;

      if (role == UserRole.admin && (isManagerRoute || isFanRoute)) {
        return '/admin';
      }

      if (role == UserRole.manager && (isAdminRoute || isFanRoute)) {
        return '/manager';
      }

      if (role == UserRole.fan && (isAdminRoute || isManagerRoute)) {
        return '/fan';
      }

      if (isSplash || isAuthPage) {
        if (role == UserRole.admin) return '/admin';
        if (role == UserRole.manager) return '/manager';
        return '/fan';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/supabase-test',
        builder: (context, state) => const TestSupabasePage(),
      ),
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerNavigationScreen(),
      ),
      GoRoute(
        path: '/fan',
        builder: (context, state) => const FanNavigationScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/fan-match-analysis',
        builder: (context, state) {
          final match = state.extra as MatchAnalysisModel;
          return MatchAnalysisScreen(match: match);
        },
      ),
      GoRoute(
        path: '/fan-club-details',
        builder: (context, state) {
          final club = state.extra as ClubModel;
          return ClubDetailsScreen(club: club);
        },
      ),
      GoRoute(
        path: '/manager-panel',
        builder: (context, state) => const ManagerPanelScreen(),
      ),
      GoRoute(
        path: '/admin-panel',
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: '/match/:matchId',
        builder: (context, state) {
          return MatchDetailsScreen(matchId: state.pathParameters['matchId']!);
        },
      ),
      GoRoute(
        path: '/live-match/:matchId',
        builder: (context, state) {
          return LiveMatchScreen(matchId: state.pathParameters['matchId']!);
        },
      ),
      GoRoute(
        path: '/player/:playerId',
        builder: (context, state) {
          return PlayerProfileScreen(
              playerId: state.pathParameters['playerId']!);
        },
      ),
    ],
  );
});
