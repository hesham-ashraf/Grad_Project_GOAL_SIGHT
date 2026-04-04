class SystemOverviewModel {
  const SystemOverviewModel({
    required this.totalUsers,
    required this.totalMatches,
    required this.activeMatches,
  });

  final int totalUsers;
  final int totalMatches;
  final int activeMatches;

  factory SystemOverviewModel.fromJson(Map<String, dynamic> json) {
    return SystemOverviewModel(
      totalUsers: (json['totalUsers'] ?? 0) as int,
      totalMatches: (json['totalMatches'] ?? 0) as int,
      activeMatches: (json['activeMatches'] ?? 0) as int,
    );
  }
}
