import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/admin/admin_bottom_navigation_bar.dart';
import 'admin_home_dashboard.dart';
import 'managers_page.dart';
import 'squad_overview_page.dart';
import 'club_analytics_page.dart';
import 'admin_profile_page.dart';

class AdminNavigationScreen extends StatefulWidget {
  const AdminNavigationScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen>
    with SingleTickerProviderStateMixin {
  static const List<AdminNavigationTab> _tabs = <AdminNavigationTab>[
    AdminNavigationTab(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    AdminNavigationTab(
      label: 'Managers',
      icon: Icons.manage_accounts_outlined,
      activeIcon: Icons.manage_accounts_rounded,
    ),
    AdminNavigationTab(
      label: 'Squad',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    AdminNavigationTab(
      label: 'Analytics',
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
    ),
    AdminNavigationTab(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
    ),
  ];

  static const List<Widget> _screens = <Widget>[
    AdminHomeDashboard(),
    ManagersPage(),
    SquadOverviewPage(),
    ClubAnalyticsPage(),
    AdminProfilePage(),
  ];

  late final AnimationController _transitionController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..value = 1;

    final curvedAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.94, end: 1).animate(curvedAnimation);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.018),
      end: Offset.zero,
    ).animate(curvedAnimation);
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _handleTabChange(int index) {
    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
    _transitionController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _AdminBackdrop()),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AdminBottomNavigationBar(
              tabs: _tabs,
              currentIndex: _selectedIndex,
              onChanged: _handleTabChange,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBackdrop extends StatelessWidget {
  const _AdminBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.backgroundAlt,
            AppColors.background,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -130,
            left: -90,
            child: _BackdropOrb(
              size: 280,
              color: AppColors.primaryPurple.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            right: -110,
            bottom: 120,
            child: _BackdropOrb(
              size: 320,
              color: AppColors.accentCyan.withValues(alpha: 0.1),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.05, -0.45),
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Color(0xAB050816),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
