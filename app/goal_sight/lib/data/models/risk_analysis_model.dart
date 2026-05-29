// ---------------------------------------------------------------------------
// GoalSight — RiskAnalysisModel
//
// Comprehensive risk profile for a single player.
// Used by Squad Intelligence, Player Profile, and Admin dashboards.
// ---------------------------------------------------------------------------

enum RiskLevel { low, medium, high, critical }

extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:      return 'Low Risk';
      case RiskLevel.medium:   return 'Moderate Risk';
      case RiskLevel.high:     return 'High Risk';
      case RiskLevel.critical: return 'Critical';
    }
  }

  /// 0–1 severity score used for sorting / color mapping
  double get severity {
    switch (this) {
      case RiskLevel.low:      return 0.15;
      case RiskLevel.medium:   return 0.45;
      case RiskLevel.high:     return 0.72;
      case RiskLevel.critical: return 0.95;
    }
  }
}

class RiskAnalysisModel {
  const RiskAnalysisModel({
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.fatigueRisk,
    required this.injuryRisk,
    required this.consistencyRisk,
    required this.tacticalRisk,
    required this.workloadScore,
    required this.riskLevel,
    required this.recommendations,
    required this.analyzedAt,
    this.nextMatchRiskFactor = 0.0,
    this.daysUntilFullRecovery = 0,
  });

  final String playerId;
  final String playerName;
  final String position;

  /// 0–100 — physical exhaustion risk
  final double fatigueRisk;

  /// 0–100 — probability of sustaining injury
  final double injuryRisk;

  /// 0–100 — performance volatility risk
  final double consistencyRisk;

  /// 0–100 — risk of tactical under-performance
  final double tacticalRisk;

  /// 0–100 — current workload vs. baseline capacity
  final double workloadScore;

  /// Overall composite risk level
  final RiskLevel riskLevel;

  /// AI-generated action recommendations
  final List<String> recommendations;

  final DateTime analyzedAt;

  /// Additional risk factor if playing in next 48 h
  final double nextMatchRiskFactor;

  /// Estimated days until full recovery/readiness
  final int daysUntilFullRecovery;

  /// Composite risk score (0–100)
  double get compositeScore =>
      (fatigueRisk * 0.35) +
      (injuryRisk * 0.35) +
      (consistencyRisk * 0.15) +
      (tacticalRisk * 0.15);

  /// Whether this player needs immediate attention
  bool get requiresAttention =>
      riskLevel == RiskLevel.high || riskLevel == RiskLevel.critical;

  RiskAnalysisModel copyWith({
    double? fatigueRisk,
    double? injuryRisk,
    double? consistencyRisk,
    double? tacticalRisk,
    double? workloadScore,
    RiskLevel? riskLevel,
    List<String>? recommendations,
  }) {
    return RiskAnalysisModel(
      playerId: playerId,
      playerName: playerName,
      position: position,
      fatigueRisk: fatigueRisk ?? this.fatigueRisk,
      injuryRisk: injuryRisk ?? this.injuryRisk,
      consistencyRisk: consistencyRisk ?? this.consistencyRisk,
      tacticalRisk: tacticalRisk ?? this.tacticalRisk,
      workloadScore: workloadScore ?? this.workloadScore,
      riskLevel: riskLevel ?? this.riskLevel,
      recommendations: recommendations ?? this.recommendations,
      analyzedAt: analyzedAt,
      nextMatchRiskFactor: nextMatchRiskFactor,
      daysUntilFullRecovery: daysUntilFullRecovery,
    );
  }
}
