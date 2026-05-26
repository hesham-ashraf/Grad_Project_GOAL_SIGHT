class PlayerAnalysisModel {
  final String id;
  final String name;
  final String position;
  final String imageUrl;
  final double overallRating;
  final double fatigueLevel; // 0 to 100
  final double injuryRisk; // 0 to 100
  final double workRate; // 0 to 100
  final double tacticalImpact; // 0 to 100
  final List<String> keyStrengths;
  final List<String> weaknesses;
  final Map<String, double> recentRatings; // e.g., {'Match 1': 7.5}

  const PlayerAnalysisModel({
    required this.id,
    required this.name,
    required this.position,
    required this.imageUrl,
    required this.overallRating,
    required this.fatigueLevel,
    required this.injuryRisk,
    required this.workRate,
    required this.tacticalImpact,
    required this.keyStrengths,
    required this.weaknesses,
    required this.recentRatings,
  });
}
