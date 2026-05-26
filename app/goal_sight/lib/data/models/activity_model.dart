class ActivityModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String action;
  final String description;
  final DateTime timestamp;
  final String? relatedEntityId;

  const ActivityModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.action,
    required this.description,
    required this.timestamp,
    this.relatedEntityId,
  });
}
