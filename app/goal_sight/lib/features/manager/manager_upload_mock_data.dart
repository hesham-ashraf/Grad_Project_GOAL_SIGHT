import 'dart:math';
import '../../data/models/match_analysis_model.dart';

/// Generates realistic mock match analysis data for the upload flow simulation.
/// In production, this would be replaced by actual AI backend output.

final _random = Random();

final List<String> _teamNames = [
  'Red Lions',
  'Blue Hawks',
  'Green Falcons',
  'Golden Eagles',
  'Silver Stars',
  'Purple Panthers',
  'Orange Strikers',
  'White Wolves',
];

final List<String> _playerNames = [
  'Ahmed Hassan',
  'Mohamed Ali',
  'Tariq Samir',
  'Omar Salah',
  'Mahmoud Karim',
  'Hassan Ibrahim',
  'Youssef Amr',
  'Karim Nasser',
  'Ibrahim Aziz',
  'Samir Malik',
  'Zaki Rashid',
  'Noor Abdullah',
];

final List<String> _positions = ['FW', 'MF', 'DF', 'GK'];

final List<String> _styles = [
  'Possession-based',
  'Counter-attack',
  'Balanced',
  'Direct',
];

final List<String> _pressureStyles = [
  'High Press',
  'Mid Block',
  'Low Block',
  'Gegenpressing',
];

final List<String> _compactness = ['Compact', 'Wide', 'Deep', 'Aggressive'];

final List<String> _zones = [
  'Left Wing',
  'Right Wing',
  'Central',
  'Deep Midfield',
];

final List<String> _impacts = [
  'Game Changer',
  'Reliable',
  'Steady',
  'Inconsistent',
  'Liability',
];

/// Generates a random match analysis to simulate upload completion.
MatchAnalysisModel generateMockMatchAnalysis() {
  final homeTeam = _teamNames[_random.nextInt(_teamNames.length)];
  final awayTeam = _teamNames.firstWhere((t) => t != homeTeam);

  final homeScore = _random.nextInt(5);
  final awayScore = _random.nextInt(5);
  final score = '$homeScore - $awayScore';

  final date = DateTime.now().toIso8601String().split('T')[0];

  final homePlayers = _generateTeamPlayers(homeTeam, 6);
  final awayPlayers = _generateTeamPlayers(awayTeam, 6);
  final allPlayers = [...homePlayers, ...awayPlayers];

  final homeAvgRating = (homePlayers.fold<double>(0, (sum, p) => sum + p.rating) /
      homePlayers.length);
  final awayAvgRating = (awayPlayers.fold<double>(0, (sum, p) => sum + p.rating) /
      awayPlayers.length);

  final dominantTeam = homeAvgRating > awayAvgRating ? homeTeam : awayTeam;
  final motmPlayer = homePlayers.reduce(
      (curr, next) => curr.rating > next.rating ? curr : next);
  final worstPlayer = awayPlayers.reduce(
      (curr, next) => curr.rating < next.rating ? curr : next);

  final homeTopPlayers =
      homePlayers.map((p) => p.id).toList();
  final homeWorstPlayers =
      awayPlayers.map((p) => p.id).toList();

  return MatchAnalysisModel(
    matchId: 'upload-${DateTime.now().millisecondsSinceEpoch}',
    homeTeam: homeTeam,
    awayTeam: awayTeam,
    score: score,
    date: date,
    status: 'FT',
    players: allPlayers,
    homeAnalysis: TeamAnalysisModel(
      teamName: homeTeam,
      possession: _random.nextInt(40) + 30,
      style: _styles[_random.nextInt(_styles.length)],
      pressureStyle: _pressureStyles[_random.nextInt(_pressureStyles.length)],
      compactness: _compactness[_random.nextInt(_compactness.length)],
      attackingZones: {
        _zones[_random.nextInt(_zones.length)],
        _zones[_random.nextInt(_zones.length)],
      }.toList(),
      avgRating: homeAvgRating,
      topPlayers: homeTopPlayers,
      worstPlayers: homeWorstPlayers,
    ),
    awayAnalysis: TeamAnalysisModel(
      teamName: awayTeam,
      possession: 100 - (homeAvgRating > 7.0 ? 60 : 50),
      style: _styles[_random.nextInt(_styles.length)],
      pressureStyle: _pressureStyles[_random.nextInt(_pressureStyles.length)],
      compactness: _compactness[_random.nextInt(_compactness.length)],
      attackingZones: {
        _zones[_random.nextInt(_zones.length)],
        _zones[_random.nextInt(_zones.length)],
      }.toList(),
      avgRating: awayAvgRating,
      topPlayers: awayPlayers.map((p) => p.id).toList(),
      worstPlayers: homePlayers.map((p) => p.id).toList(),
    ),
    summary: MatchSummaryModel(
      dominantTeam: dominantTeam,
      homeAvgRating: homeAvgRating,
      awayAvgRating: awayAvgRating,
      motmPlayerId: motmPlayer.id,
      worstPlayerId: worstPlayer.id,
      keyMoments: _generateKeyMoments(homeScore, awayScore),
      overallNarrative: _generateNarrative(dominantTeam, homeTeam, awayTeam),
    ),
    recommendations: _generateRecommendations(),
    highlightText: _generateHighlight(homeScore, awayScore),
    intensity: _random.nextInt(40) + 40,
  );
}

List<PlayerModel> _generateTeamPlayers(String teamName, int count) {
  final players = <PlayerModel>[];
  for (int i = 0; i < count; i++) {
    const performanceValues = PerformanceStatus.values;
    final performance = performanceValues[_random.nextInt(performanceValues.length)];
    final rating = _ratingForPerformance(performance);

    players.add(
      PlayerModel(
        id: '${teamName.replaceAll(' ', '')}_p${i + 1}',
        name: _playerNames[_random.nextInt(_playerNames.length)],
        position: _positions[_random.nextInt(_positions.length)],
        rating: rating,
        fatigue: _random.nextInt(60) + 20,
        performanceStatus: performance,
        insight: _generatePlayerInsight(performance),
        contribution: [
          ContributionType.attack,
          ContributionType.defense,
          ContributionType.balanced,
        ][_random.nextInt(3)],
        impact: _impacts[_random.nextInt(_impacts.length)],
        goals: _random.nextInt(3),
        assists: _random.nextInt(2),
        tackles: _random.nextInt(8),
        keyPasses: _random.nextInt(5),
      ),
    );
  }
  return players;
}

double _ratingForPerformance(PerformanceStatus status) {
  switch (status) {
    case PerformanceStatus.excellent:
      return (_random.nextDouble() * 0.9 + 8.5);
    case PerformanceStatus.good:
      return (_random.nextDouble() * 0.8 + 7.0);
    case PerformanceStatus.average:
      return (_random.nextDouble() * 0.8 + 5.5);
    case PerformanceStatus.poor:
      return (_random.nextDouble() * 0.8 + 4.0);
    case PerformanceStatus.terrible:
      return (_random.nextDouble() * 1.0 + 2.0);
  }
}

String _generatePlayerInsight(PerformanceStatus status) {
  const Map<PerformanceStatus, List<String>> insights = {
    PerformanceStatus.excellent: [
      'Dominant display throughout',
      'Controlled the game',
      'Clinical performance',
      'Outstanding contribution',
    ],
    PerformanceStatus.good: [
      'Solid all-around game',
      'Made important plays',
      'Reliable presence',
      'Good decision-making',
    ],
    PerformanceStatus.average: [
      'Mixed performance',
      'Had good and bad moments',
      'Occasional lapses',
      'Acceptable display',
    ],
    PerformanceStatus.poor: [
      'Struggled throughout',
      'Below expected standard',
      'Needed support',
      'Inconsistent performance',
    ],
    PerformanceStatus.terrible: [
      'Major concerns',
      'Underperformed significantly',
      'Limited impact',
      'Needs review',
    ],
  };
  final list = insights[status]!;
  return list[_random.nextInt(list.length)];
}

List<String> _generateKeyMoments(int homeScore, int awayScore) {
  final moments = <String>[];
  var homeGoals = homeScore;
  var awayGoals = awayScore;
  var minute = 5;

  while (homeGoals > 0 || awayGoals > 0) {
    if (homeGoals > 0 && _random.nextBool()) {
      moments.add("$minute' Goal - Home team");
      homeGoals--;
    } else if (awayGoals > 0) {
      moments.add("$minute' Goal - Away team");
      awayGoals--;
    }
    minute += _random.nextInt(20) + 10;
  }

  return moments.isEmpty
      ? ['Match remained goalless']
      : moments.take(4).toList();
}

String _generateNarrative(
    String dominant, String home, String away) {
  const narratives = [
    'Dominant display with clinical finishing.',
    'Tight contest decided by key moments.',
    'Strong control but missed chances.',
    'Competitive match with end-to-end action.',
    'Well-organized defense limited opposition.',
  ];
  return narratives[_random.nextInt(narratives.length)];
}

String? _generateHighlight(int homeScore, int awayScore) {
  if ((homeScore + awayScore) >= 4) return 'High-scoring affair';
  if ((homeScore - awayScore).abs() >= 2) return 'Dominant performance';
  if (homeScore == awayScore && homeScore == 0) return 'Defensive masterclass';
  return null;
}

List<String> _generateRecommendations() {
  const recommendations = [
    'Focus on set-piece defense',
    'Improve transition game',
    'Increase pressing intensity',
    'Work on possession retention',
    'Rotate fatigued players',
    'Enhance attacking movement',
    'Strengthen midfield discipline',
    'Review goalkeeping distribution',
  ];
  final list = <String>[];
  for (int i = 0; i < 3; i++) {
    final rec = recommendations[_random.nextInt(recommendations.length)];
    if (!list.contains(rec)) list.add(rec);
  }
  return list;
}
