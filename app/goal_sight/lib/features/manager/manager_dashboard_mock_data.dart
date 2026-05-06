import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'manager_dashboard_models.dart';

const ManagerDashboardData kManagerDashboardMockData = ManagerDashboardData(
  clubName: 'GoalSight FC',
  subtitle: 'Team Performance Overview',
  keyStats: [
    ManagerKeyStat(
      label: 'Played Matches',
      value: '28',
      icon: Icons.event_available_rounded,
      tint: AppColors.accentCyan,
    ),
    ManagerKeyStat(
      label: 'Team Average Rating',
      value: '7.82',
      icon: Icons.stars_rounded,
      tint: AppColors.primaryPurple,
    ),
    ManagerKeyStat(
      label: 'Team Fatigue Level',
      value: '68%',
      icon: Icons.bolt_rounded,
      tint: AppColors.warning,
    ),
    ManagerKeyStat(
      label: 'League Position',
      value: '#3',
      icon: Icons.emoji_events_rounded,
      tint: AppColors.accentGreen,
    ),
  ],
  lastMatch: ManagerLastMatch(
    homeTeam: 'GoalSight FC',
    awayTeam: 'Falcons United',
    homeScore: 3,
    awayScore: 1,
    aiSummary:
        'GoalSight controlled central zones and recovered possession quickly after turnovers. '
        'Wide overloads in the second half created 6 high-value chances and decisive momentum.',
    dominantTeam: 'GoalSight FC',
  ),
  topPerformers: [
    ManagerPlayerPerformance(
      name: 'Hassan Ali',
      rating: 9.1,
    ),
    ManagerPlayerPerformance(
      name: 'Ziad Hamdy',
      rating: 8.4,
    ),
    ManagerPlayerPerformance(
      name: 'Mostafa Samir',
      rating: 7.8,
    ),
  ],
  insights: [
    ManagerInsight(
      title: 'Midfield Fatigue Spike',
      message: 'High fatigue in midfield after 70 minutes. Rotate one central midfielder next match.',
      severity: ManagerInsightSeverity.high,
    ),
    ManagerInsight(
      title: 'Defensive Line Drop',
      message: 'Defensive performance dropped late. Back line retreated 8m deeper than target shape.',
      severity: ManagerInsightSeverity.medium,
    ),
    ManagerInsight(
      title: 'Positive Pressing Trend',
      message: 'Pressing efficiency improved by 12% versus previous match. Keep current front-three trigger timing.',
      severity: ManagerInsightSeverity.low,
    ),
  ],
);
