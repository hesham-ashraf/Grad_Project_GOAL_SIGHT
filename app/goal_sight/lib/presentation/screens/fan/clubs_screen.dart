import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/fan/fan_section_placeholder.dart';

class ClubsScreen extends StatelessWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FanSectionPlaceholder(
      badgeText: 'TEAM HUB',
      title: 'Clubs',
      subtitle:
          'Open club pages, browse squad profiles, and keep track of the teams you care about.',
      icon: Icons.groups_rounded,
      accentColor: AppColors.primaryBlue,
      highlights: [
        'Squad views',
        'Club profiles',
        'Watchlists',
      ],
    );
  }
}