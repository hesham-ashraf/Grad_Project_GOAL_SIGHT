import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../data/models/club_model.dart';
import '../data/models/match_model.dart';
import '../../presentation/widgets/fan/standings_row.dart';

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
final mockClubsProvider = Provider<List<ClubModel>>((ref) {
  return const [
    ClubModel(
      id: 'c1',
      name: 'GoalSight FC',
      stadium: 'GoalSight Arena',
      league: 'GoalSight Premier League',
      primaryColor: AppColors.accentCyan,
      foundedYear: 1998,
      country: 'Egypt',
      isFavorite: true,
      coach: 'Ahmed Nour',
      stats: ClubStats(
        matchesPlayed: 10, wins: 8, draws: 1, losses: 1,
        goalsScored: 24, goalsConceded: 7, ranking: 1, points: 25,
      ),
      players: [
        ClubPlayer(id: 'p1', name: 'Hassan Ali', position: 'CAM', rating: 8.9, nationality: '🇪🇬', age: 27, appearances: 10, goals: 6, assists: 8),
        ClubPlayer(id: 'p2', name: 'Mostafa Samir', position: 'LW', rating: 8.4, nationality: '🇪🇬', age: 24, appearances: 10, goals: 7, assists: 3),
        ClubPlayer(id: 'p3', name: 'Ziad Hamdy', position: 'CB', rating: 7.6, nationality: '🇪🇬', age: 29, appearances: 10, goals: 0, assists: 1),
        ClubPlayer(id: 'p4', name: 'Tariq Ziad', position: 'DM', rating: 7.0, nationality: '🇪🇬', age: 26, appearances: 8, goals: 1, assists: 2),
        ClubPlayer(id: 'p5', name: 'Karim Wael', position: 'GK', rating: 7.8, nationality: '🇪🇬', age: 31, appearances: 10, goals: 0, assists: 0),
        ClubPlayer(id: 'p6', name: 'Omar Fathy', position: 'RB', rating: 7.2, nationality: '🇪🇬', age: 23, appearances: 9, goals: 0, assists: 3),
      ],
    ),
    ClubModel(
      id: 'c2',
      name: 'Falcons United',
      stadium: 'Sky Stadium',
      league: 'GoalSight Premier League',
      primaryColor: AppColors.primaryPurple,
      foundedYear: 2003,
      country: 'Egypt',
      coach: 'Samy Hassan',
      stats: ClubStats(
        matchesPlayed: 10, wins: 6, draws: 4, losses: 0,
        goalsScored: 18, goalsConceded: 9, ranking: 2, points: 22,
      ),
      players: [
        ClubPlayer(id: 'p7', name: 'Adel Ragab', position: 'ST', rating: 8.1, nationality: '🇪🇬', age: 25, appearances: 10, goals: 9, assists: 2),
        ClubPlayer(id: 'p8', name: 'Youssef Ahmed', position: 'CM', rating: 7.5, nationality: '🇪🇬', age: 28, appearances: 10, goals: 2, assists: 4),
        ClubPlayer(id: 'p9', name: 'Nasser Ibrahim', position: 'CB', rating: 7.8, nationality: '🇪🇬', age: 30, appearances: 10, goals: 1, assists: 0),
        ClubPlayer(id: 'p10', name: 'Sherif Gamal', position: 'LB', rating: 6.9, nationality: '🇪🇬', age: 22, appearances: 9, goals: 0, assists: 2),
        ClubPlayer(id: 'p11', name: 'Mahmoud Saif', position: 'GK', rating: 7.4, nationality: '🇪🇬', age: 33, appearances: 10, goals: 0, assists: 0),
      ],
    ),
    ClubModel(
      id: 'c3',
      name: 'Lions City',
      stadium: 'The Den',
      league: 'GoalSight Premier League',
      primaryColor: AppColors.warning,
      foundedYear: 1995,
      country: 'Egypt',
      coach: 'Khalid Mostafa',
      stats: ClubStats(
        matchesPlayed: 10, wins: 5, draws: 4, losses: 1,
        goalsScored: 16, goalsConceded: 11, ranking: 3, points: 19,
      ),
      players: [
        ClubPlayer(id: 'p12', name: 'Tamer Said', position: 'ST', rating: 7.9, nationality: '🇪🇬', age: 26, appearances: 10, goals: 7, assists: 1),
        ClubPlayer(id: 'p13', name: 'Amr Khaled', position: 'AM', rating: 7.3, nationality: '🇪🇬', age: 24, appearances: 9, goals: 3, assists: 5),
        ClubPlayer(id: 'p14', name: 'Walid Nour', position: 'CB', rating: 7.0, nationality: '🇪🇬', age: 32, appearances: 10, goals: 0, assists: 0),
      ],
    ),
    ClubModel(
      id: 'c4',
      name: 'Sharks FC',
      stadium: 'Oceanic Park',
      league: 'GoalSight Premier League',
      primaryColor: AppColors.primaryBlue,
      foundedYear: 2008,
      country: 'Egypt',
      coach: 'Hany Zakaria',
      stats: ClubStats(
        matchesPlayed: 10, wins: 4, draws: 4, losses: 2,
        goalsScored: 13, goalsConceded: 12, ranking: 4, points: 16,
      ),
      players: [
        ClubPlayer(id: 'p15', name: 'Bassem Nabil', position: 'RW', rating: 7.7, nationality: '🇪🇬', age: 23, appearances: 10, goals: 5, assists: 3),
        ClubPlayer(id: 'p16', name: 'Ibrahim Sameh', position: 'CB', rating: 7.2, nationality: '🇪🇬', age: 28, appearances: 10, goals: 1, assists: 0),
      ],
    ),
    ClubModel(
      id: 'c5',
      name: 'Eagles Club',
      stadium: 'High Peak Arena',
      league: 'GoalSight Premier League',
      primaryColor: AppColors.danger,
      foundedYear: 2001,
      country: 'Egypt',
      coach: 'Ramy Fares',
      stats: ClubStats(
        matchesPlayed: 10, wins: 3, draws: 5, losses: 2,
        goalsScored: 11, goalsConceded: 13, ranking: 5, points: 14,
      ),
      players: [
        ClubPlayer(id: 'p17', name: 'Saad Magdy', position: 'ST', rating: 7.1, nationality: '🇪🇬', age: 27, appearances: 10, goals: 5, assists: 1),
        ClubPlayer(id: 'p18', name: 'Fady Emam', position: 'CM', rating: 6.8, nationality: '🇪🇬', age: 25, appearances: 9, goals: 1, assists: 4),
      ],
    ),
    ClubModel(
      id: 'c6',
      name: 'Panthers',
      stadium: 'Jungle Stadium',
      league: 'GoalSight Premier League',
      primaryColor: AppColors.accentGreen,
      foundedYear: 2010,
      country: 'Egypt',
      coach: 'Nader Ali',
      stats: ClubStats(
        matchesPlayed: 10, wins: 3, draws: 2, losses: 5,
        goalsScored: 10, goalsConceded: 14, ranking: 6, points: 11,
      ),
      players: [
        ClubPlayer(id: 'p19', name: 'George Maher', position: 'LW', rating: 7.0, nationality: '🇪🇬', age: 22, appearances: 10, goals: 4, assists: 2),
        ClubPlayer(id: 'p20', name: 'Andrew Nabil', position: 'GK', rating: 6.5, nationality: '🇪🇬', age: 30, appearances: 10, goals: 0, assists: 0),
      ],
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
