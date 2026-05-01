import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/fan/fan_section_placeholder.dart';

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FanSectionPlaceholder(
      badgeText: 'LEAGUE TABLE',
      title: 'Standings',
      subtitle:
          'Track league positions, goal difference, and current form across the competition.',
      icon: Icons.leaderboard_rounded,
      accentColor: AppColors.accentGreen,
      highlights: [
        'League table',
        'Goal difference',
        'Form streaks',
      ],
    );
  }
}