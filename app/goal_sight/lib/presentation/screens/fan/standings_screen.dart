import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/fan/standings_row.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  static const List<StandingTeamData> _mockStandings = [
    StandingTeamData(
      rank: 1,
      teamName: 'GoalSight FC',
      matchesPlayed: 10,
      goalDifference: 14,
      points: 25,
      teamColor: AppColors.accentCyan,
      isHighlighted: true,
    ),
    StandingTeamData(
      rank: 2,
      teamName: 'Falcons United',
      matchesPlayed: 10,
      goalDifference: 11,
      points: 22,
      teamColor: AppColors.primaryPurple,
    ),
    StandingTeamData(
      rank: 3,
      teamName: 'Lions City',
      matchesPlayed: 10,
      goalDifference: 8,
      points: 19,
      teamColor: AppColors.warning,
    ),
    StandingTeamData(
      rank: 4,
      teamName: 'Sharks FC',
      matchesPlayed: 10,
      goalDifference: 2,
      points: 16,
      teamColor: AppColors.primaryBlue,
    ),
    StandingTeamData(
      rank: 5,
      teamName: 'Eagles Club',
      matchesPlayed: 10,
      goalDifference: -1,
      points: 14,
      teamColor: AppColors.danger,
    ),
    StandingTeamData(
      rank: 6,
      teamName: 'Panthers',
      matchesPlayed: 10,
      goalDifference: -3,
      points: 11,
      teamColor: AppColors.accentGreen,
    ),
    StandingTeamData(
      rank: 7,
      teamName: 'Bulls',
      matchesPlayed: 10,
      goalDifference: -8,
      points: 8,
      teamColor: AppColors.textMuted,
    ),
    StandingTeamData(
      rank: 8,
      teamName: 'Wolves',
      matchesPlayed: 10,
      goalDifference: -12,
      points: 5,
      teamColor: AppColors.outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(20, min: 16, max: 24),
                context.rs(8, min: 4, max: 12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'League Table',
                    style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                      fontSize: context.rs(32, min: 28, max: 36),
                    ),
                  ),
                  SizedBox(height: context.rs(6, min: 4, max: 8)),
                  Text(
                    'Current standings for the 2026 Season',
                    style: AppTextStyles.body(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            // Pinned Table Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rs(4, min: 0, max: 8)),
              child: const StandingsHeaderRow(),
            ),
            
            // Scrollable Table Rows
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  context.rs(20, min: 16, max: 24),
                  0, // Header has bottom padding
                  context.rs(20, min: 16, max: 24),
                  context.rs(100, min: 80, max: 120), // Bottom padding for FanBottomNavigationBar
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: _mockStandings.length,
                itemBuilder: (context, index) {
                  final team = _mockStandings[index];
                  return StandingsRow(
                    team: team,
                    onTap: () {
                      // Navigate to club details in the future
                      // e.g. context.push('/club-details/${team.id}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viewing ${team.teamName} details...'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}