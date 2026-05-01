import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/match_model.dart';
import '../widgets/fan/club_card.dart';
import '../widgets/fan/standings_row.dart';

// Matches
final mockMatchesProvider = Provider<List<MatchModel>>((ref) {
  return const [
    MatchModel(
      id: 'm1',
      homeTeam: 'GoalSight FC',
      awayTeam: 'Falcons United',
      score: '3 - 1',
      date: 'Today, 20:00',
      status: 'FT',
      intensity: 91,
      homeColor: AppColors.accentCyan,
      awayColor: AppColors.primaryPurple,
      highlightText: 'High intensity match',
      isTopMatch: true,
      summary: 'GoalSight FC dominated the midfield with quick passing transitions, overpowering Falcons United who struggled to break the high press.',
      dominantTeam: 'GoalSight FC',
      tactics: TacticalAnalysis(
        homePossession: 64,
        homeStyle: 'Possession-based',
        homePressure: 'High Press',
        awayPossession: 36,
        awayStyle: 'Counter-attack',
        awayPressure: 'Low Block',
      ),
      players: [
        MatchPlayer(id: 'p1', name: 'Hassan Ali', rating: 8.9, insight: 'Controlled the tempo and provided 2 key assists.', isBest: true),
        MatchPlayer(id: 'p2', name: 'Mostafa Samir', rating: 8.4, insight: 'Constant threat on the wing. 1 Goal.'),
        MatchPlayer(id: 'p3', name: 'Ziad Hamdy', rating: 7.6, insight: 'Solid defensive work rate.'),
        MatchPlayer(id: 'p4', name: 'Tariq Ziad', rating: 5.4, insight: 'Lost possession 6 times in dangerous areas.', isWorst: true),
      ],
      recommendations: [
        'Maintain high pressing intensity to exploit Falcons United\'s weak build-up play.',
        'Consider resting Hassan Ali in the 70th minute to prevent fatigue injuries.',
      ],
    ),
    MatchModel(
      id: 'm2',
      homeTeam: 'Sharks FC',
      awayTeam: 'Eagles Club',
      score: '0 - 0',
      date: 'Yesterday',
      status: 'FT',
      intensity: 65,
      homeColor: AppColors.primaryBlue,
      awayColor: AppColors.danger,
      summary: 'A slow-paced tactical stalemate with minimal chances created by either side.',
      dominantTeam: 'None',
      tactics: TacticalAnalysis(
        homePossession: 50,
        homeStyle: 'Balanced',
        homePressure: 'Mid Block',
        awayPossession: 50,
        awayStyle: 'Balanced',
        awayPressure: 'Mid Block',
      ),
      players: [
        MatchPlayer(id: 'p5', name: 'Omar Fathy', rating: 7.8, insight: 'Solid center-back performance, 5 clearances.', isBest: true),
        MatchPlayer(id: 'p6', name: 'Karim Wael', rating: 5.2, insight: 'Struggled to connect passes in the final third.', isWorst: true),
      ],
      recommendations: [
        'Work on final third creativity to break down mid-block defenses.',
      ],
    ),
    MatchModel(
      id: 'm3',
      homeTeam: 'Lions City',
      awayTeam: 'GoalSight FC',
      score: '1 - 2',
      date: 'Oct 12',
      status: 'FT',
      intensity: 85,
      homeColor: AppColors.warning,
      awayColor: AppColors.accentCyan,
      highlightText: 'Last minute winner',
      summary: 'A dramatic late surge by GoalSight FC secured 3 points in a tightly contested away fixture.',
      dominantTeam: 'GoalSight FC',
      tactics: TacticalAnalysis(
        homePossession: 45,
        homeStyle: 'Direct',
        homePressure: 'Low Block',
        awayPossession: 55,
        awayStyle: 'Possession-based',
        awayPressure: 'High Press',
      ),
      players: [
        MatchPlayer(id: 'p1', name: 'Hassan Ali', rating: 8.5, insight: 'Scored the decisive 90+2 minute goal.', isBest: true),
        MatchPlayer(id: 'p7', name: 'Youssef Ahmed', rating: 5.5, insight: 'Outpaced on the counter multiple times.', isWorst: true),
      ],
      recommendations: [
        'Review defensive transitions when pushing forward late in the game.',
      ],
    ),
  ];
});

// Clubs
final mockClubsProvider = Provider<List<FanClubItemData>>((ref) {
  return const [
    FanClubItemData(
      id: 'c1',
      name: 'GoalSight FC',
      stadium: 'GoalSight Arena',
      primaryColor: AppColors.accentCyan,
      isFavorite: true,
    ),
    FanClubItemData(
      id: 'c2',
      name: 'Falcons United',
      stadium: 'Sky Stadium',
      primaryColor: AppColors.primaryPurple,
    ),
    FanClubItemData(
      id: 'c3',
      name: 'Lions City',
      stadium: 'The Den',
      primaryColor: AppColors.warning,
    ),
    FanClubItemData(
      id: 'c4',
      name: 'Sharks FC',
      stadium: 'Oceanic Park',
      primaryColor: AppColors.primaryBlue,
    ),
    FanClubItemData(
      id: 'c5',
      name: 'Eagles Club',
      stadium: 'High Peak Arena',
      primaryColor: AppColors.danger,
    ),
    FanClubItemData(
      id: 'c6',
      name: 'Panthers',
      stadium: 'Jungle Stadium',
      primaryColor: AppColors.accentGreen,
    ),
    FanClubItemData(
      id: 'c7',
      name: 'Bulls',
      stadium: 'Red Arena',
      primaryColor: AppColors.textMuted,
    ),
    FanClubItemData(
      id: 'c8',
      name: 'Wolves',
      stadium: 'Moonlight Ground',
      primaryColor: AppColors.outline,
    ),
  ];
});

// Standings
final mockStandingsProvider = Provider<List<StandingTeamData>>((ref) {
  return const [
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
});
