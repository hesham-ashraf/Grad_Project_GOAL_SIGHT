class ManagerModel {
  final String id;
  final String name;
  final String email;
  final String imageUrl;
  final int uploadCount;
  final DateTime lastActive;
  final bool isActive;
  final int matchesAnalyzed;
  final double tacticalRating;
  final String? clubId;

  const ManagerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.uploadCount,
    required this.lastActive,
    required this.isActive,
    required this.matchesAnalyzed,
    required this.tacticalRating,
    this.clubId,
  });

  factory ManagerModel.fromJson(Map<String, dynamic> json) {
    return ManagerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      imageUrl: json['imageUrl'] as String,
      uploadCount: json['uploadCount'] as int,
      lastActive: DateTime.parse(json['lastActive'] as String),
      isActive: json['isActive'] as bool,
      matchesAnalyzed: json['matchesAnalyzed'] as int,
      tacticalRating: (json['tacticalRating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'imageUrl': imageUrl,
      'uploadCount': uploadCount,
      'lastActive': lastActive.toIso8601String(),
      'isActive': isActive,
      'matchesAnalyzed': matchesAnalyzed,
      'tacticalRating': tacticalRating,
    };
  }
}
