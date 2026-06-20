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
    this.heatmapUrl,
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

  /// URL of this player's movement heatmap PNG for this match (model output).
  final String? heatmapUrl;

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
      heatmapUrl: json['heatmap_url']?.toString(),
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
    this.analyzedVideoUrl,
    this.heatmapUrl,
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

  /// Signed URL for the analyzed/annotated video produced by the AI pipeline.
  /// Null while processing or when no video artifact exists.
  final String? analyzedVideoUrl;

  /// URL of the overall match movement heatmap PNG (model output). Null when
  /// the pipeline hasn't produced one (UI falls back to a synthetic heatmap).
  final String? heatmapUrl;

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

  /// Returns a copy with selected fields replaced. Used to attach the analysis
  /// service's fresh per-job video URL so the viewer never shows a stale clip.
  MatchAnalysisModel copyWith({String? analyzedVideoUrl}) => MatchAnalysisModel(
        matchId: matchId,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        score: score,
        date: date,
        status: status,
        players: players,
        homeAnalysis: homeAnalysis,
        awayAnalysis: awayAnalysis,
        summary: summary,
        recommendations: recommendations,
        highlightText: highlightText,
        intensity: intensity,
        analyzedVideoUrl: analyzedVideoUrl ?? this.analyzedVideoUrl,
        heatmapUrl: heatmapUrl,
      );

  /// Builds the full analysis directly from the analysis service's raw model
  /// JSONs (the `raw` block of `GET /jobs/{id}/result`). This is the offline
  /// path used when Supabase persistence is unavailable, so the manager can
  /// still open the result the model just produced.
  factory MatchAnalysisModel.fromServiceResult({
    required String jobId,
    required Map<String, dynamic> raw,
    required int myTeamId,
    required String homeTeam,
    required String awayTeam,
    String date = 'TBD',
    String? analyzedVideoUrl,
    Map<String, String> heatmapUrls = const {},
  }) {
    Map<String, dynamic> asMap(dynamic v) =>
        (v as Map?)?.cast<String, dynamic>() ?? const {};
    List<Map<String, dynamic>> asList(dynamic v) =>
        (v as List?)?.map((e) => asMap(e)).toList() ?? const [];

    final finalReport = asMap(raw['final_report']);
    final analytics = asMap(raw['player_analytics']);
    final possession = asMap(raw['possession']);
    final tactical = asMap(raw['team_tactical']);

    final perf = asList(analytics['players']);
    final frPlayers = asList(finalReport['players']);
    final impactByTrack = {
      for (final p in frPlayers) (p['track_id'] as num?)?.toInt(): p,
    };
    final motm = (finalReport['man_of_the_match'] as num?)?.toInt();
    final worst = (finalReport['weakest_player'] as num?)?.toInt();

    // Per-team rating lists (for avg) and the top-rated track (for the best
    // player heatmap).
    final ratingsByTeam = <int, List<double>>{};
    final bestTrackByTeam = <int, int>{};
    final bestRatingByTeam = <int, double>{};
    for (final p in perf) {
      final tid = (p['track_id'] as num?)?.toInt();
      final team = (p['team_id'] as num?)?.toInt();
      final rating = (p['player_rating'] as num? ?? 0).toDouble();
      if (team != null) {
        ratingsByTeam.putIfAbsent(team, () => []).add(rating);
        if (tid != null && rating >= (bestRatingByTeam[team] ?? -1)) {
          bestRatingByTeam[team] = rating;
          bestTrackByTeam[team] = tid;
        }
      }
    }
    double teamAvg(int t) {
      final l = ratingsByTeam[t];
      if (l == null || l.isEmpty) return 0;
      return l.reduce((a, b) => a + b) / l.length;
    }

    final players = <PlayerModel>[];
    for (final p in perf) {
      final tid = (p['track_id'] as num?)?.toInt();
      final team = (p['team_id'] as num?)?.toInt();
      final fr = impactByTrack[tid] ?? const {};
      final isBest = team != null && bestTrackByTeam[team] == tid;
      players.add(PlayerModel(
        id: tid?.toString() ?? '',
        name: (p['player_display_name'] ?? p['player_name'] ?? 'Player $tid')
            .toString(),
        position: (p['role'] ?? '').toString(),
        rating: (p['player_rating'] as num? ?? 0).toDouble(),
        fatigue: _fatiguePct(p['fatigue_level']?.toString()),
        performanceStatus: _perfFromLabel(p['performance_status']?.toString()),
        insight: (p['insight'] ?? '').toString(),
        contribution: ContributionType.balanced,
        impact: (fr['impact'] ?? '').toString(),
        isMOTM: tid != null && tid == motm,
        isWorst: tid != null && tid == worst,
        heatmapUrl: isBest ? heatmapUrls['team${team}_best_player'] : null,
      ));
    }

    final styleByTeam = {
      for (final t in asList(finalReport['teams']))
        (t['team_id'] as num?)?.toInt(): t,
    };
    final tacByTeam = {
      for (final t in asList(tactical['teams']))
        (t['team_id'] as num?)?.toInt(): t,
    };
    final poss = {
      0: (possession['team_0_possession'] as num?)?.round() ?? 0,
      1: (possession['team_1_possession'] as num?)?.round() ?? 0,
    };
    TeamAnalysisModel teamModel(int mt, String name) {
      final st = (styleByTeam[mt] as Map?)?.cast<String, dynamic>() ?? const {};
      final tac = (tacByTeam[mt] as Map?)?.cast<String, dynamic>() ?? const {};
      final zone = tac['attacking_zone'];
      return TeamAnalysisModel(
        teamName: name,
        possession: poss[mt] ?? 0,
        style: (st['style'] ?? '').toString(),
        pressureStyle: (st['pressure'] ?? '').toString(),
        compactness: (st['compactness'] ?? '').toString(),
        attackingZones: [if (zone != null) zone.toString()],
        avgRating: teamAvg(mt),
        topPlayers: const [],
        worstPlayers: const [],
      );
    }

    // Intensity from the teams' average on-ball speed (km/h → 0-100).
    final speeds = asList(tactical['teams'])
        .map((t) => (t['metrics'] as Map?)?['avg_speed_kmh'])
        .whereType<num>()
        .map((e) => e.toDouble())
        .toList();
    final intensity = speeds.isEmpty
        ? 0
        : (speeds.reduce((a, b) => a + b) / speeds.length / 12 * 100)
            .round()
            .clamp(0, 100);

    final otherTeam = 1 - myTeamId;
    return MatchAnalysisModel(
      matchId: jobId,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      score: '',
      date: date,
      status: 'FT',
      intensity: intensity,
      analyzedVideoUrl: analyzedVideoUrl,
      heatmapUrl: heatmapUrls['team$myTeamId'],
      recommendations:
          (finalReport['recommendations'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      summary: MatchSummaryModel(
        dominantTeam: (finalReport['dominant_team'] ?? '').toString(),
        homeAvgRating: teamAvg(myTeamId),
        awayAvgRating: teamAvg(otherTeam),
        motmPlayerId: motm?.toString() ?? '',
        worstPlayerId: worst?.toString() ?? '',
        keyMoments: const [],
        overallNarrative: (finalReport['summary'] ?? '').toString(),
      ),
      homeAnalysis: teamModel(myTeamId, homeTeam),
      awayAnalysis: teamModel(otherTeam, awayTeam),
      players: players,
    );
  }

  static PerformanceStatus _perfFromLabel(String? label) =>
      PerformanceStatus.values.firstWhere(
        (e) => e.name == (label ?? '').toLowerCase(),
        orElse: () => PerformanceStatus.average,
      );

  static int _fatiguePct(String? label) {
    switch ((label ?? '').toLowerCase()) {
      case 'high':
        return 85;
      case 'medium':
        return 60;
      case 'low':
        return 30;
      default:
        return 0;
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
      analyzedVideoUrl: json['analyzed_video_url']?.toString(),
      heatmapUrl: json['heatmap_url']?.toString(),
    );
  }
}
