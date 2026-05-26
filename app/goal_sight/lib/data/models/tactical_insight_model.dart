class TacticalInsightModel {
  final String id;
  final String title;
  final String description;
  final String category; // e.g., 'Weakness', 'Strength', 'Opportunity'
  final double impactScore; // 0.0 to 10.0
  final DateTime generatedAt;
  final String relatedMatchId;

  const TacticalInsightModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.impactScore,
    required this.generatedAt,
    required this.relatedMatchId,
  });
}
