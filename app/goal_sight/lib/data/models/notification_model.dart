enum NotificationType {
  uploadComplete,
  uploadFailed,
  highRiskPlayer,
  managerAdded;

  static NotificationType fromDb(String raw) {
    switch (raw) {
      case 'upload_complete':
        return NotificationType.uploadComplete;
      case 'upload_failed':
        return NotificationType.uploadFailed;
      case 'high_risk_player':
        return NotificationType.highRiskPlayer;
      case 'manager_added':
        return NotificationType.managerAdded;
      default:
        return NotificationType.uploadComplete;
    }
  }
}

class NotificationModel {
  final String id;
  final String recipientId;
  final String? clubId;
  final NotificationType type;
  final String title;
  final String body;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    this.clubId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        recipientId: recipientId,
        clubId: clubId,
        type: type,
        title: title,
        body: body,
        relatedId: relatedId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
