import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/manager_bottom_navigation_bar.dart';
import 'manager_home_screen.dart';
import 'manager_matches_screen.dart';
import 'manager_profile_screen.dart';
import 'players_screen.dart';
import 'upload_match_screen.dart';

class ManagerNavigationScreen extends StatefulWidget {
  const ManagerNavigationScreen({super.key});

  @override
  State<ManagerNavigationScreen> createState() => _ManagerNavigationScreenState();
}

class _ManagerNavigationScreenState extends State<ManagerNavigationScreen>
    with SingleTickerProviderStateMixin {
  static const List<ManagerNavigationTab> _tabs = <ManagerNavigationTab>[
    ManagerNavigationTab(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    ManagerNavigationTab(
      label: 'Matches',
      icon: Icons.sports_soccer_outlined,
      activeIcon: Icons.sports_soccer_rounded,
    ),
    ManagerNavigationTab(
      label: 'Upload',
      icon: Icons.cloud_upload_outlined,
      activeIcon: Icons.cloud_upload_rounded,
    ),
    ManagerNavigationTab(
      label: 'Players',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    ManagerNavigationTab(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
    ),
  ];

  static const List<Widget> _screens = <Widget>[
    ManagerHomeScreen(),
    ManagerMatchesScreen(),
    UploadMatchScreen(),
    PlayersScreen(),
    ManagerProfileScreen(),
  ];

  late final AnimationController _transitionController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
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
          const Positioned.fill(child: _ManagerBackdrop()),
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
            child: ManagerBottomNavigationBar(
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

class _ManagerBackdrop extends StatelessWidget {
  const _ManagerBackdrop();

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
              color: AppColors.accentCyan.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            right: -110,
            bottom: 120,
            child: _BackdropOrb(
              size: 320,
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
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
