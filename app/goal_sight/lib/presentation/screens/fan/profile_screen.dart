import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/utils/responsive.dart';
import '../../state_management/app_providers.dart';
import '../../widgets/fan/profile_widgets.dart';
import '../../widgets/fan/fan_profile_advanced_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  // header + stats banner + notifs + favourites + saved + prefs + achievements + account
  static const int _sectionCount = 8;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();

    _fades = List.generate(_sectionCount, (i) {
      final start = (i * 0.1).clamp(0.0, 0.85);
      final end = (start + 0.22).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic));
    });

    _slides = _fades
        .map((f) =>
            Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                .animate(f))
        .toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _section(int idx, Widget child) => FadeTransition(
        opacity: _fades[idx],
        child: SlideTransition(position: _slides[idx], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    final name = user?.name ?? 'Guest Fan';
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : 'user@example.com';
    final roleLabel = user?.role.label ?? UserRole.fan.label;

    final h = context.rs(20, min: 16, max: 24);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            context.rs(20, min: 16, max: 28),
            context.rs(32, min: 24, max: 44),
            context.rs(20, min: 16, max: 28),
            context.rs(100, min: 80, max: 120),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 0. Profile Header ────────────────────────────────────────
              _section(
                0,
                ProfileHeader(
                  name: name,
                  role: roleLabel,
                  subtitle: 'Football Enthusiast',
                ),
              ),
              SizedBox(height: h),

              // ── 1. Fan Stats Banner ──────────────────────────────────────
              _section(1, FanStatsBanner(name: name)),
              SizedBox(height: h),

              // ── 2. Notification Settings ─────────────────────────────────
              _section(2, const NotificationSettingsCard()),
              SizedBox(height: h),

              // ── 3. Favourites ────────────────────────────────────────────
              _section(3, const FavoritesCard()),
              SizedBox(height: h),

              // ── 4. Saved Analyses ─────────────────────────────────────────
              _section(4, const SavedMatchesCard()),
              SizedBox(height: h),

              // ── 5. Preferences ────────────────────────────────────────────
              _section(5, const PreferencesCard()),
              SizedBox(height: h),

              // ── 6. Achievements ───────────────────────────────────────────
              _section(6, const AchievementsCard()),
              SizedBox(height: h),

              // ── 7. Account Management ─────────────────────────────────────
              _section(
                7,
                AccountManagementCard(
                  email: email,
                  onLogout: () {
                    ref.read(authControllerProvider.notifier).logout();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
