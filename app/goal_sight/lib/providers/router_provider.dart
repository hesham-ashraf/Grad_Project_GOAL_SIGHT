import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_roles.dart';
import '../features/auth/auth_state.dart';
import '../features/manager/screens/add_player_screen.dart';
import '../features/manager/screens/manager_navigation_screen.dart';
import '../features/manager/screens/player_profile_screen.dart';
import '../features/manager/screens/upload_history_screen.dart';
import '../features/manager/screens/upload_match_screen.dart';
import '../data/models/club_model.dart';
import '../data/models/match_analysis_model.dart';
import '../data/models/player_profile_model.dart';
import '../features/supabase_test/test_supabase_page.dart';
import '../../presentation/screens/admin/admin_panel_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/admin/admin_navigation_screen.dart';
import '../../presentation/screens/admin/manager_details_page.dart';
import '../../presentation/screens/admin/player_intelligence_page.dart';
import '../../presentation/screens/admin/admin_notifications_page.dart';
import '../../presentation/screens/auth/email_verification_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/fan/club_details_screen.dart';
import '../../presentation/screens/fan/fan_navigation_screen.dart';
import '../../presentation/screens/manager/manager_panel_screen.dart';
import '../../presentation/screens/match/live_match_screen.dart';
import '../../presentation/screens/match/match_details_screen.dart';
import '../../presentation/screens/player/player_profile_screen.dart' as fan_player_profile;
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/fan/match_analysis_screen.dart';
import '../shared/transitions/transitions.dart';
import 'app_providers.dart';

// Temporary: set to false when you finish Supabase testing.
const bool kShowSupabaseTestPage = false;

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: kShowSupabaseTestPage ? '/supabase-test' : '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthPage = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location == '/email-verification';
      final isSplash = location == '/splash';
      final isEmailVerification = location == '/email-verification';
      final isSupabaseTest = location == '/supabase-test';
      final isAdminRoute =
          location.startsWith('/admin') || location == '/admin-panel';
      final isManagerRoute = location.startsWith('/manager');
      // Shared read-only routes that any authenticated role can navigate to
      // (e.g. a manager pushing /fan-match-analysis to view a match result).
      const sharedRoutes = {
        '/fan-match-analysis',
        '/fan-club-details',
        '/fan-player-profile',
      };
      final isSharedRoute = sharedRoutes.contains(location);
      final isFanRoute = !isSharedRoute && location.startsWith('/fan');

      // Allow the test page without auth redirects.
      if (isSupabaseTest) return null;

      if (authState.status == AuthStatus.initial) {
        return isSplash ? null : '/splash';
      }

      if (authState.status == AuthStatus.loading) {
        if (isAuthPage) return null;
        return isSplash ? null : '/splash';
      }

      if (authState.status == AuthStatus.emailVerificationRequired) {
        return isEmailVerification ? null : '/email-verification';
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
        // isFanRoute is already false for shared routes, so this guard
        // only fires for true fan-shell routes a manager shouldn't see.
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
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const SplashScreen(),
          transition: GoalSightPageTransition.fade,
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const LoginScreen(),
          transition: GoalSightPageTransition.fade,
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const RegisterScreen(),
          transition: GoalSightPageTransition.slideLeft,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const ForgotPasswordScreen(),
          transition: GoalSightPageTransition.modal,
        ),
      ),
      GoRoute(
        path: '/email-verification',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const EmailVerificationScreen(),
          transition: GoalSightPageTransition.slideUp,
        ),
      ),
      GoRoute(
        path: '/supabase-test',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const TestSupabasePage(),
        ),
      ),
      GoRoute(
        path: '/manager',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const ManagerNavigationScreen(),
        ),
      ),
      GoRoute(
        path: '/manager/add-player',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const AddPlayerScreen(),
          transition: GoalSightPageTransition.modal,
        ),
      ),
      GoRoute(
        path: '/manager/upload-history',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const UploadHistoryScreen(),
          transition: GoalSightPageTransition.slideLeft,
        ),
      ),
      GoRoute(
        path: '/manager/upload-match',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const UploadMatchScreen(),
          transition: GoalSightPageTransition.slideLeft,
        ),
      ),
      GoRoute(
        path: '/fan',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const FanNavigationScreen(),
        ),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const AdminNavigationScreen(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/admin/home',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const AdminNavigationScreen(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/admin/managers',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const AdminNavigationScreen(initialIndex: 1),
        ),
      ),
      GoRoute(
        path: '/admin/squad',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const AdminNavigationScreen(initialIndex: 2),
        ),
      ),
      GoRoute(
        path: '/admin/club-analytics',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const AdminNavigationScreen(initialIndex: 3),
        ),
      ),
      GoRoute(
        path: '/admin/profile',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const AdminNavigationScreen(initialIndex: 4),
        ),
      ),
      GoRoute(
        path: '/admin/managers/:id',
        pageBuilder: (context, state) {
          return goalSightTransitionPage(
            state: state,
            child: ManagerDetailsPage(managerId: state.pathParameters['id']!),
            transition: GoalSightPageTransition.slideLeft,
          );
        },
      ),
      GoRoute(
        path: '/admin/player/:id',
        pageBuilder: (context, state) {
          return goalSightTransitionPage(
            state: state,
            child: PlayerIntelligencePage(playerId: state.pathParameters['id']!),
            transition: GoalSightPageTransition.slideLeft,
          );
        },
      ),
      GoRoute(
        path: '/admin/notifications',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const AdminNotificationsPage(),
          transition: GoalSightPageTransition.slideLeft,
        ),
      ),
      GoRoute(
        path: '/fan-match-analysis',
        pageBuilder: (context, state) {
          final match = state.extra as MatchAnalysisModel;
          return goalSightTransitionPage(
            state: state,
            child: MatchAnalysisScreen(match: match),
            transition: GoalSightPageTransition.slideLeft,
          );
        },
      ),
      GoRoute(
        path: '/fan-club-details',
        pageBuilder: (context, state) {
          final club = state.extra as ClubModel;
          return goalSightTransitionPage(
            state: state,
            child: ClubDetailsScreen(club: club),
            transition: GoalSightPageTransition.slideLeft,
          );
        },
      ),
      GoRoute(
        path: '/manager-panel',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const ManagerPanelScreen(),
        ),
      ),
      GoRoute(
        path: '/manager-player-profile',
        pageBuilder: (context, state) {
          final player = state.extra as PlayerProfileModel;
          return goalSightTransitionPage(
            state: state,
            child: PlayerProfileScreen(player: player),
            transition: GoalSightPageTransition.slideLeft,
          );
        },
      ),
      GoRoute(
        path: '/admin-panel',
        pageBuilder: (context, state) => goalSightTransitionPage(
          state: state,
          child: const AdminPanelScreen(),
        ),
      ),
      GoRoute(
        path: '/match/:matchId',
        pageBuilder: (context, state) {
          return goalSightTransitionPage(
            state: state,
            child: MatchDetailsScreen(matchId: state.pathParameters['matchId']!),
            transition: GoalSightPageTransition.slideLeft,
          );
        },
      ),
      GoRoute(
        path: '/live-match/:matchId',
        pageBuilder: (context, state) {
          return goalSightTransitionPage(
            state: state,
            child: LiveMatchScreen(matchId: state.pathParameters['matchId']!),
            transition: GoalSightPageTransition.slideLeft,
          );
        },
      ),
      GoRoute(
        path: '/player/:playerId',
        pageBuilder: (context, state) {
          return goalSightTransitionPage(
            state: state,
            child: fan_player_profile.PlayerProfileScreen(
                playerId: state.pathParameters['playerId']!),
            transition: GoalSightPageTransition.slideLeft,
          );
        },
      ),
    ],
  );
});
