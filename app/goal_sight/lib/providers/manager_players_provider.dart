// ---------------------------------------------------------------------------
//GoalSight — Manager Players Provider
//
//Converts club roster data to detailed player profiles for manager view.
//Loads all players from the manager's assigned club.
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/player_profile_model.dart';
import '../data/models/club_model.dart';
import 'clubs_provider.dart';

//Manager's club ID - currently manages GoalSight FC
const String _managerClubId = 'club_001';

//Fetch the manager's club
final managerClubProvider = Provider<ClubModel?>((ref) {
  final clubs = ref.watch(mockClubsProvider);
  try {
    return clubs.firstWhere((c) => c.id == _managerClubId);
  } catch (_) {
    return null;
  }
});

//Convert a ClubPlayer to PlayerProfileModel with realistic historical data
PlayerProfileModel _clubPlayerToProfileModel(ClubPlayer player) {
  // Generate realistic ratings history based on performance tier
  final List<double> ratingsHistory;
  switch (player.performanceTier) {
    case PlayerPerformanceTier.elite:
      ratingsHistory = [
        player.rating - 0.3,
        player.rating - 0.1,
        player.rating,
        player.rating + 0.1,
        player.rating - 0.1,
        player.rating,
        player.rating
      ];
      break;
    case PlayerPerformanceTier.good:
      ratingsHistory = [
        player.rating - 0.2,
        player.rating,
        player.rating - 0.1,
        player.rating + 0.1,
        player.rating,
        player.rating - 0.1,
        player.rating
      ];
      break;
    case PlayerPerformanceTier.average:
      ratingsHistory = [
        player.rating - 0.1,
        player.rating,
        player.rating - 0.2,
        player.rating - 0.1,
        player.rating + 0.1,
        player.rating,
        player.rating - 0.1
      ];
      break;
    case PlayerPerformanceTier.poor:
      ratingsHistory = [
        player.rating + 0.3,
        player.rating + 0.1,
        player.rating,
        player.rating - 0.2,
        player.rating - 0.3,
        player.rating - 0.1,
        player.rating
      ];
      break;
    case PlayerPerformanceTier.critical:
      ratingsHistory = [
        player.rating + 0.5,
        player.rating + 0.2,
        player.rating,
        player.rating - 0.4,
        player.rating - 0.6,
        player.rating - 0.4,
        player.rating
      ];
      break;
  }

  // Calculate improvement rate
  final avgRating =
      ratingsHistory.reduce((a, b) => a + b) / ratingsHistory.length;
  final improvementRate =
      ((player.rating - (ratingsHistory.isNotEmpty ? ratingsHistory.first : player.rating)) /
          (ratingsHistory.isNotEmpty ? ratingsHistory.first : player.rating)) *
      100;

  // Determine trend
  final PerformanceTrend trend;
  if (improvementRate > 5) {
    trend = PerformanceTrend.improving;
  } else if (improvementRate < -5) {
    trend = PerformanceTrend.declining;
  } else {
    trend = PerformanceTrend.stable;
  }

  // Determine status based on rating
  final String status;
  if (player.rating >= 8.5) {
    status = 'Explosive Form';
  } else if (player.rating >= 8.0) {
    status = 'Elite Form';
  } else if (player.rating >= 7.5) {
    status = 'In Form';
  } else if (player.rating >= 7.0) {
    status = 'Solid';
  } else {
    status = 'Needs Improvement';
  }

  // Calculate fatigue (higher rating = lower fatigue)
  final fatigue = (110 - (player.rating * 12)).clamp(20, 95).toInt();

  // Activity level based on position and appearances
  final activityLevel = ((player.appearances / 12) * 85 + 15)
      .clamp(0, 100)
      .toInt();

  // Determine contribution type
  final String primaryContribution;
  final String secondaryContribution;
  
  if (player.position.contains('ST') ||
      player.position.contains('W') ||
      player.position.contains('CAM')) {
    primaryContribution = 'Attack';
    secondaryContribution = 'Balanced';
  } else if (player.position.contains('CB') ||
      player.position.contains('LB') ||
      player.position.contains('RB') ||
      player.position.contains('GK')) {
    primaryContribution = 'Defense';
    secondaryContribution = 'Balanced';
  } else if (player.position.contains('CM') || player.position.contains('DM')) {
    primaryContribution = 'Balanced';
    secondaryContribution = 'Defense';
  } else {
    primaryContribution = 'Balanced';
    secondaryContribution = 'Balanced';
  }

  // Generate match history
  final List<PlayerMatchHistory> matchHistory = [];
  for (int i = 0; i < 3; i++) {
    final matchDate = DateTime.now().subtract(Duration(days: 7 - (i * 3)));
    final baseRating = player.rating - (i * 0.15);
    
    matchHistory.add(
      PlayerMatchHistory(
        matchId: 'match_${player.id}_$i',
        matchDate: matchDate,
        homeTeam: 'GoalSight FC',
        awayTeam: ['Blue Strikers', 'Yellow Hawks', 'Red Lions'][i],
        playerRating: baseRating,
        performanceStatus: baseRating >= 8.0
            ? 'Excellent'
            : baseRating >= 7.5
                ? 'Good'
                : baseRating >= 7.0
                    ? 'Average'
                    : 'Poor',
        goals: player.position.contains('ST') || player.position.contains('W')
            ? (i == 0 ? 1 : 0)
            : 0,
        assists: player.position.contains('CAM') || player.position.contains('W')
            ? (i == 1 ? 1 : 0)
            : 0,
        tackles: player.position.contains('CB') ||
                player.position.contains('LB') ||
                player.position.contains('RB') ||
                player.position.contains('DM')
            ? 4 + i
            : 1,
        keyPasses: player.position.contains('CAM') || player.position.contains('CM')
            ? 3 + i
            : 1,
      ),
    );
  }

  // Generate insights
  final List<String> insights = [];
  if (player.rating >= 8.0) {
    insights.add(player.performanceSummary);
  }
  if (player.goals > 0) {
    insights.add('${player.goals} goals this season');
  }
  if (player.assists > 0) {
    insights.add('${player.assists} assists this season');
  }
  if (player.tackles > 0) {
    insights.add('${player.tackles} tackles this season');
  }
  if (insights.isEmpty) {
    insights.add(player.performanceSummary);
  }

  return PlayerProfileModel(
    id: player.id,
    name: player.name,
    position: player.position,
    currentRating: player.rating,
    averageRating: avgRating,
    fatigue: fatigue,
    activityLevel: activityLevel,
    primaryContribution: primaryContribution,
    secondaryContribution: secondaryContribution,
    status: status,
    improvementRate: improvementRate,
    trend: trend,
    totalMatches: player.appearances,
    totalGoals: player.goals,
    totalAssists: player.assists,
    totalTackles: player.tackles,
    ratingsHistory: ratingsHistory,
    insights: insights,
    matchHistory: matchHistory,
  );
}

//All players from the manager's club with detailed profiles
final managerPlayersProvider = Provider<List<PlayerProfileModel>>((ref) {
  final club = ref.watch(managerClubProvider);
  
  if (club == null) {
    return [];
  }

  // Convert all club players to detailed player profiles
  return club.players
      .map((player) => _clubPlayerToProfileModel(player))
      .toList();
});
