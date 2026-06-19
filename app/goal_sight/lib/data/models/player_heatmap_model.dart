// ---------------------------------------------------------------------------
// GoalSight — Player Match Heatmap
//
// One per-match movement heatmap for a player, labelled by the match it came
// from (e.g. "vs Zamalek · 12 May 2026"). Backed by match_player_analysis
// rows (heatmap_url) joined to their parent match_analyses.
// ---------------------------------------------------------------------------

class PlayerMatchHeatmap {
  const PlayerMatchHeatmap({
    required this.matchLabel,
    required this.dateLabel,
    required this.url,
  });

  /// e.g. "Al Ahly vs Zamalek" or "vs Zamalek".
  final String matchLabel;

  /// Human date label of the match (may be empty).
  final String dateLabel;

  /// URL of the heatmap PNG.
  final String url;
}
