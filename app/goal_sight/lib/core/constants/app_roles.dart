enum UserRole { fan, manager, admin }

extension UserRoleX on UserRole {
  String get value {
    if (this == UserRole.admin) return 'admin';
    if (this == UserRole.manager) return 'manager';
    return 'fan';
  }

  String get label {
    if (this == UserRole.admin) return 'Admin';
    if (this == UserRole.manager) return 'Manager';
    return 'Fan';
  }
}

UserRole parseUserRole(String rawRole) {
  final normalized = rawRole.trim().toLowerCase();
  if (normalized == 'admin') return UserRole.admin;
  if (normalized == 'manager') return UserRole.manager;
  return UserRole.fan;
}
