// ---------------------------------------------------------------------------
// GoalSight — Match Analysis Models
//
// These models mirror the exact JSON shape produced by the AI backend.
// When Supabase is connected, swap the mock provider with a real repository
// and call [MatchAnalysisModel.fromJson] / [PlayerModel.fromJson], etc.
// Zero UI changes will be required.
// ---------------------------------------------------------------------------

// ─── Player ──────────────────────────────────────────────────────────────────

enum PerformanceStatus { excellent, good, average, poor, terrible }

enum ContributionType { attack, defense, balanced }

class PlayerModel {
  const PlayerModel({
    required this.id,
    required this.name,
    required this.position,
    required this.rating,
    required this.fatigue,
    required this.performanceStatus,
    required this.insight,
    required this.contribution,
    required this.impact,
    this.goals = 0,
    this.assists = 0,
    this.tackles = 0,
    this.keyPasses = 0,
    this.isMOTM = false,
    this.isWorst = false,
  });

  final String id;
  final String name;
  final String position;

  /// AI-assigned match rating (0–10)
  final double rating;

  /// Fatigue index (0–100). Higher = more fatigued.
  final int fatigue;

  final PerformanceStatus performanceStatus;

  /// Short AI-generated insight for this player.
  final String insight;

  final ContributionType contribution;

  /// Overall impact label, e.g. "Game Changer", "Reliable", "Liability"
  final String impact;

  // Optional computed stats
  final int goals;
  final int assists;
  final int tackles;
  final int keyPasses;

  final bool isMOTM;
  final bool isWorst;

  // ── Convenience ────────────────────────────────────────────────────────────

  String get statusLabel {
    switch (performanceStatus) {
      case PerformanceStatus.excellent:
        return 'Excellent';
      case PerformanceStatus.good:
        return 'Good';
      case PerformanceStatus.average:
        return 'Average';
      case PerformanceStatus.poor:
        return 'Poor';
      case PerformanceStatus.terrible:
        return 'Terrible';
    }
  }

  String get contributionLabel {
    switch (contribution) {
      case ContributionType.attack:
        return 'Attack';
      case ContributionType.defense:
        return 'Defense';
      case ContributionType.balanced:
        return 'Balanced';
    }
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      fatigue: (json['fatigue'] as num? ?? 0).toInt(),
      performanceStatus: PerformanceStatus.values.firstWhere(
        (e) => e.name == json['performance_status'],
        orElse: () => PerformanceStatus.average,
      ),
      insight: json['insight']?.toString() ?? '',
      contribution: ContributionType.values.firstWhere(
        (e) => e.name == json['contribution'],
        orElse: () => ContributionType.balanced,
      ),
      impact: json['impact']?.toString() ?? '',
      goals: (json['goals'] as num? ?? 0).toInt(),
      assists: (json['assists'] as num? ?? 0).toInt(),
      tackles: (json['tackles'] as num? ?? 0).toInt(),
      keyPasses: (json['key_passes'] as num? ?? 0).toInt(),
      isMOTM: json['is_motm'] == true,
      isWorst: json['is_worst'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': position,
        'rating': rating,
        'fatigue': fatigue,
        'performance_status': performanceStatus.name,
        'insight': insight,
        'contribution': contribution.name,
        'impact': impact,
        'goals': goals,
        'assists': assists,
        'tackles': tackles,
        'key_passes': keyPasses,
        'is_motm': isMOTM,
        'is_worst': isWorst,
      };
}

// ─── Team ─────────────────────────────────────────────────────────────────────

class TeamAnalysisModel {
  const TeamAnalysisModel({
    required this.teamName,
    required this.possession,
    required this.style,
    required this.pressureStyle,
    required this.compactness,
    required this.attackingZones,
    required this.avgRating,
    required this.topPlayers,
    required this.worstPlayers,
  });

  final String teamName;

  /// Possession percentage (0–100)
  final int possession;

  /// E.g. "Possession-based", "Counter-attack", "Direct", "Balanced"
  final String style;

  /// E.g. "High Press", "Mid Block", "Low Block", "Gegenpressing"
  final String pressureStyle;

  /// E.g. "Compact", "Wide", "Deep", "Aggressive"
  final String compactness;

  /// List of zones where the team primarily attacked, e.g. ["Left Wing", "Central"]
  final List<String> attackingZones;

  final double avgRating;

  /// Player IDs of top performers in this team
  final List<String> topPlayers;

  /// Player IDs of worst performers in this team
  final List<String> worstPlayers;

  factory TeamAnalysisModel.fromJson(Map<String, dynamic> json) {
    return TeamAnalysisModel(
      teamName: json['team_name']?.toString() ?? '',
      possession: (json['possession'] as num? ?? 0).toInt(),
      style: json['style']?.toString() ?? '',
      pressureStyle: json['pressure_style']?.toString() ?? '',
      compactness: json['compactness']?.toString() ?? '',
      attackingZones: List<String>.from(json['attacking_zones'] ?? []),
      avgRating: (json['avg_rating'] as num? ?? 0).toDouble(),
      topPlayers: List<String>.from(json['top_players'] ?? []),
      worstPlayers: List<String>.from(json['worst_players'] ?? []),
    );
  }
}

// ─── Match Summary ────────────────────────────────────────────────────────────

class MatchSummaryModel {
  const MatchSummaryModel({
    required this.dominantTeam,
    required this.homeAvgRating,
    required this.awayAvgRating,
    required this.motmPlayerId,
    required this.worstPlayerId,
    required this.keyMoments,
    required this.overallNarrative,
  });

  final String dominantTeam;
  final double homeAvgRating;
  final double awayAvgRating;

  /// Player ID of man of the match
  final String motmPlayerId;

  /// Player ID of worst player
  final String worstPlayerId;

  /// Key match moments, e.g. ["45+2' Red card for Tariq", "88' Penalty miss"]
  final List<String> keyMoments;

  /// Full AI narrative summary paragraph
  final String overallNarrative;

  factory MatchSummaryModel.fromJson(Map<String, dynamic> json) {
    return MatchSummaryModel(
      dominantTeam: json['dominant_team']?.toString() ?? '',
      homeAvgRating: (json['home_avg_rating'] as num? ?? 0).toDouble(),
      awayAvgRating: (json['away_avg_rating'] as num? ?? 0).toDouble(),
      motmPlayerId: json['motm_player_id']?.toString() ?? '',
      worstPlayerId: json['worst_player_id']?.toString() ?? '',
      keyMoments: List<String>.from(json['key_moments'] ?? []),
      overallNarrative: json['overall_narrative']?.toString() ?? '',
    );
  }
}

// ─── Match Analysis (Full AI Output) ─────────────────────────────────────────

class MatchAnalysisModel {
  const MatchAnalysisModel({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
    required this.date,
    required this.status,
    required this.players,
    required this.homeAnalysis,
    required this.awayAnalysis,
    required this.summary,
    required this.recommendations,
    this.highlightText,
    this.intensity = 0,
  });

  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final String score;
  final String date;
  final String status;

  final List<PlayerModel> players;
  final TeamAnalysisModel homeAnalysis;
  final TeamAnalysisModel awayAnalysis;
  final MatchSummaryModel summary;

  /// Ordered list of AI-generated coaching recommendations
  final List<String> recommendations;

  /// Optional short highlight label, e.g. "Last minute winner"
  final String? highlightText;

  /// Match intensity score (0–100)
  final int intensity;

  // ── Derived helpers ────────────────────────────────────────────────────────

  PlayerModel? get motm =>
      _findPlayer(summary.motmPlayerId) ??
      players.where((p) => p.isMOTM).firstOrNull;

  PlayerModel? get worstPlayer =>
      _findPlayer(summary.worstPlayerId) ??
      players.where((p) => p.isWorst).firstOrNull;

  List<PlayerModel> get homePlayers => players
      .where((p) => homeAnalysis.topPlayers.contains(p.id) ||
          homeAnalysis.worstPlayers.contains(p.id) ||
          // fallback: first half of players belong to home
          players.indexOf(p) < (players.length / 2).ceil())
      .toList();

  PlayerModel? _findPlayer(String id) {
    try {
      return players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory MatchAnalysisModel.fromJson(Map<String, dynamic> json) {
    return MatchAnalysisModel(
      matchId: json['match_id']?.toString() ?? '',
      homeTeam: json['teamA']?.toString() ?? '',
      awayTeam: json['teamB']?.toString() ?? '',
      score: json['score']?.toString() ?? '',
      date: json['date']?.toString() ?? 'TBD',
      status: json['status']?.toString() ?? 'FT',
      players: (json['players'] as List? ?? [])
          .map((p) => PlayerModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      homeAnalysis: TeamAnalysisModel.fromJson(
          json['home_team'] as Map<String, dynamic>? ?? {}),
      awayAnalysis: TeamAnalysisModel.fromJson(
          json['away_team'] as Map<String, dynamic>? ?? {}),
      summary: MatchSummaryModel.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      highlightText: json['highlight_text']?.toString(),
      intensity: (json['intensity'] as num? ?? 0).toInt(),
    );
  }
}
