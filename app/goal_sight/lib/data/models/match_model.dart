class MatchModel {
  const MatchModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    required this.score,
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final String status;
  final String score;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final home = (json['homeTeam'] ?? 'Home').toString();
    final away = (json['awayTeam'] ?? 'Away').toString();
    final homeScore = (json['homeScore'] ?? 0).toString();
    final awayScore = (json['awayScore'] ?? 0).toString();

    return MatchModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      homeTeam: home,
      awayTeam: away,
      status: (json['status'] ?? 'scheduled').toString(),
      score: '${homeScore} - ${awayScore}',
    );
  }
}
