import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/fan/fan_bottom_navigation_bar.dart';
import 'clubs_screen.dart';
import 'fan_home_screen.dart';
import 'matches_screen.dart';
import 'profile_screen.dart';
import 'standings_screen.dart';

class FanNavigationScreen extends StatefulWidget {
  const FanNavigationScreen({super.key});

  @override
  State<FanNavigationScreen> createState() => _FanNavigationScreenState();
}

class _FanNavigationScreenState extends State<FanNavigationScreen>
    with SingleTickerProviderStateMixin {
  static const List<FanNavigationItem> _items = <FanNavigationItem>[
    FanNavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    FanNavigationItem(
      label: 'Matches',
      icon: Icons.sports_soccer,
      activeIcon: Icons.sports_soccer_rounded,
    ),
    FanNavigationItem(
      label: 'Standings',
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard_rounded,
    ),
    FanNavigationItem(
      label: 'Clubs',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    FanNavigationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
    ),
  ];

  static const List<Widget> _screens = <Widget>[
    FanHomeScreen(),
    MatchesScreen(),
    StandingsScreen(),
    ClubsScreen(),
    ProfileScreen(),
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
    final bottomPadding =
        FanBottomNavigationBar.totalHeight(context) + context.rs(12, min: 10, max: 16);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _FanBackdrop()),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
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
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FanBottomNavigationBar(
              items: _items,
              currentIndex: _selectedIndex,
              onChanged: _handleTabChange,
            ),
          ),
        ],
      ),
    );
  }
}

class _FanBackdrop extends StatelessWidget {
  const _FanBackdrop();

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
            top: -120,
            right: -80,
            child: _BackdropOrb(
              size: 260,
              color: AppColors.primaryPurple.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            left: -110,
            bottom: 120,
            child: _BackdropOrb(
              size: 300,
              color: AppColors.accentCyan.withValues(alpha: 0.1),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.5),
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Color(0xA8050816),
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