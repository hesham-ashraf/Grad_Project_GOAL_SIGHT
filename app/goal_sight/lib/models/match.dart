class Match {
  final int? id;
  final String teamA;
  final String teamB;
  final int scoreA;
  final int scoreB;
  final DateTime matchDate;
  final String? notes;
  // Additional analysis data
  final int? possessionA;
  final int? possessionB;
  final int? shotsA;
  final int? shotsB;
  final int? shotsOnTargetA;
  final int? shotsOnTargetB;
  final int? passesA;
  final int? passesB;
  final int? passAccuracyA;
  final int? passAccuracyB;
  final int? foulsA;
  final int? foulsB;
  final int? cornersA;
  final int? cornersB;

  Match({
    this.id,
    required this.teamA,
    required this.teamB,
    required this.scoreA,
    required this.scoreB,
    required this.matchDate,
    this.notes,
    this.possessionA,
    this.possessionB,
    this.shotsA,
    this.shotsB,
    this.shotsOnTargetA,
    this.shotsOnTargetB,
    this.passesA,
    this.passesB,
    this.passAccuracyA,
    this.passAccuracyB,
    this.foulsA,
    this.foulsB,
    this.cornersA,
    this.cornersB,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamA': teamA,
      'teamB': teamB,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'matchDate': matchDate.toIso8601String(),
      'notes': notes,
      'possessionA': possessionA,
      'possessionB': possessionB,
      'shotsA': shotsA,
      'shotsB': shotsB,
      'shotsOnTargetA': shotsOnTargetA,
      'shotsOnTargetB': shotsOnTargetB,
      'passesA': passesA,
      'passesB': passesB,
      'passAccuracyA': passAccuracyA,
      'passAccuracyB': passAccuracyB,
      'foulsA': foulsA,
      'foulsB': foulsB,
      'cornersA': cornersA,
      'cornersB': cornersB,
    };
  }

  factory Match.fromMap(Map<String, dynamic> map) {
    return Match(
      id: map['id'] as int?,
      teamA: map['teamA'] as String,
      teamB: map['teamB'] as String,
      scoreA: map['scoreA'] as int,
      scoreB: map['scoreB'] as int,
      matchDate: DateTime.parse(map['matchDate'] as String),
      notes: map['notes'] as String?,
      possessionA: map['possessionA'] as int?,
      possessionB: map['possessionB'] as int?,
      shotsA: map['shotsA'] as int?,
      shotsB: map['shotsB'] as int?,
      shotsOnTargetA: map['shotsOnTargetA'] as int?,
      shotsOnTargetB: map['shotsOnTargetB'] as int?,
      passesA: map['passesA'] as int?,
      passesB: map['passesB'] as int?,
      passAccuracyA: map['passAccuracyA'] as int?,
      passAccuracyB: map['passAccuracyB'] as int?,
      foulsA: map['foulsA'] as int?,
      foulsB: map['foulsB'] as int?,
      cornersA: map['cornersA'] as int?,
      cornersB: map['cornersB'] as int?,
    );
  }

  Match copyWith({
    int? id,
    String? teamA,
    String? teamB,
    int? scoreA,
    int? scoreB,
    DateTime? matchDate,
    String? notes,
    int? possessionA,
    int? possessionB,
    int? shotsA,
    int? shotsB,
    int? shotsOnTargetA,
    int? shotsOnTargetB,
    int? passesA,
    int? passesB,
    int? passAccuracyA,
    int? passAccuracyB,
    int? foulsA,
    int? foulsB,
    int? cornersA,
    int? cornersB,
  }) {
    return Match(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      matchDate: matchDate ?? this.matchDate,
      notes: notes ?? this.notes,
      possessionA: possessionA ?? this.possessionA,
      possessionB: possessionB ?? this.possessionB,
      shotsA: shotsA ?? this.shotsA,
      shotsB: shotsB ?? this.shotsB,
      shotsOnTargetA: shotsOnTargetA ?? this.shotsOnTargetA,
      shotsOnTargetB: shotsOnTargetB ?? this.shotsOnTargetB,
      passesA: passesA ?? this.passesA,
      passesB: passesB ?? this.passesB,
      passAccuracyA: passAccuracyA ?? this.passAccuracyA,
      passAccuracyB: passAccuracyB ?? this.passAccuracyB,
      foulsA: foulsA ?? this.foulsA,
      foulsB: foulsB ?? this.foulsB,
      cornersA: cornersA ?? this.cornersA,
      cornersB: cornersB ?? this.cornersB,
    );
  }
}

