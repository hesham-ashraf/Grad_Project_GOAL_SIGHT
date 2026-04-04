class LiveMatchUpdateModel {
  const LiveMatchUpdateModel({
    required this.matchId,
    required this.message,
    required this.timestamp,
  });

  final String matchId;
  final String message;
  final DateTime timestamp;

  factory LiveMatchUpdateModel.fromJson(Map<String, dynamic> json) {
    final rawTime = json['timestamp'];
    final parsed = rawTime is String ? DateTime.tryParse(rawTime) : null;
    return LiveMatchUpdateModel(
      matchId: (json['matchId'] ?? '').toString(),
      message: (json['message'] ?? 'Match update').toString(),
      timestamp: parsed ?? DateTime.now(),
    );
  }
}
