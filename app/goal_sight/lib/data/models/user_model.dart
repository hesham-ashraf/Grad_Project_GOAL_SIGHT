import '../../core/constants/app_roles.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.clubId,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  /// The club this user belongs to. Set for admin and manager; null for fan.
  final String? clubId;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'User').toString(),
      email: (json['email'] ?? '').toString(),
      role: parseUserRole((json['role'] ?? 'manager').toString()),
      clubId: json['club_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.value,
      'club_id': clubId,
    };
  }
}
