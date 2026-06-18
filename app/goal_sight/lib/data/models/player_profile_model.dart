// ---------------------------------------------------------------------------
// GoalSight — Player Profile Model
//
// Extended player data aggregated from multiple match analyses.
// Includes historical ratings, trends, fatigue tracking, and AI insights.
// ---------------------------------------------------------------------------

enum PerformanceTrend { improving, declining, stable }

class PlayerMatchHistory {
  const PlayerMatchHistory({
    required this.matchId,
    required this.matchDate,
    required this.homeTeam,
    required this.awayTeam,
    required this.playerRating,
    required this.performanceStatus,
    required this.goals,
    required this.assists,
    required this.tackles,
    required this.keyPasses,
  });

  final String matchId;
  final DateTime matchDate;
  final String homeTeam;
  final String awayTeam;
  final double playerRating;
  final String performanceStatus;
  final int goals;
  final int assists;
  final int tackles;
  final int keyPasses;
}

class PlayerProfileModel {
  const PlayerProfileModel({
    required this.id,
    required this.name,
    required this.position,
    required this.currentRating,
    required this.averageRating,
    required this.fatigue,
    required this.activityLevel,
    required this.primaryContribution,
    required this.secondaryContribution,
    required this.insights,
    required this.ratingsHistory,
    required this.matchHistory,
    required this.trend,
    required this.totalMatches,
    required this.totalGoals,
    required this.totalAssists,
    required this.totalTackles,
    this.status = 'Stable',
    this.improvementRate = 0.0,
    this.jerseyNumber,
    this.age,
    this.heightCm,
    this.weightKg,
    this.nationality,
    this.marketValue,
    this.isCaptain = false,
  });

  final String id;
  final String name;
  final String position;

  // ── Player bio / physical attributes ──────────────────────────────────────
  /// Shirt number (1–99), if assigned.
  final int? jerseyNumber;

  /// Age in years.
  final int? age;

  /// Height in centimetres.
  final int? heightCm;

  /// Weight in kilograms.
  final int? weightKg;

  /// Nationality (free text, e.g. "Egypt").
  final String? nationality;

  /// Estimated market value label (e.g. "€45M"), if known.
  final String? marketValue;

  /// Whether this player is the squad captain.
  final bool isCaptain;

  /// Latest match rating (0–10)
  final double currentRating;

  /// Average rating across all matches
  final double averageRating;

  /// Current fatigue level (0–100)
  final int fatigue;

  /// Activity level (0–100). Higher = more touches, passes, actions.
  final int activityLevel;

  /// Primary contribution type (Attack / Defense / Balanced)
  final String primaryContribution;

  /// Secondary contribution type
  final String secondaryContribution;

  /// AI-generated insights (e.g., "Strong in transitions", "Low defensive contribution")
  final List<String> insights;

  /// Historical ratings for trend visualization
  final List<double> ratingsHistory;

  /// Match-by-match history
  final List<PlayerMatchHistory> matchHistory;

  /// Performance trend (improving/declining/stable)
  final PerformanceTrend trend;

  /// Total matches played (in season/tracking period)
  final int totalMatches;

  /// Career/season statistics
  final int totalGoals;
  final int totalAssists;
  final int totalTackles;

  /// Status label (e.g., "In Form", "Needs Improvement", "Recovering")
  final String status;

  /// Week-over-week improvement rate (-100 to 100)
  final double improvementRate;

  String get trendLabel {
    switch (trend) {
      case PerformanceTrend.improving:
        return 'Improving';
      case PerformanceTrend.declining:
        return 'Declining';
      case PerformanceTrend.stable:
        return 'Stable';
    }
  }

  String get positionShort {
    final parts = position.split('/');
    return parts.first;
  }

  double get goalsPerMatch => totalMatches > 0 ? totalGoals / totalMatches : 0;
  double get assistsPerMatch => totalMatches > 0 ? totalAssists / totalMatches : 0;
  double get tacklesPerMatch => totalMatches > 0 ? totalTackles / totalMatches : 0;
}
