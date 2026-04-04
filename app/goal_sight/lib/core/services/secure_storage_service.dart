import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

class SecureStorageService {
  const SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) {
    return _storage.write(key: StorageKeys.jwtToken, value: token);
  }

  Future<String?> readToken() {
    return _storage.read(key: StorageKeys.jwtToken);
  }

  Future<void> saveRole(String role) {
    return _storage.write(key: StorageKeys.userRole, value: role);
  }

  Future<String?> readRole() {
    return _storage.read(key: StorageKeys.userRole);
  }

  Future<void> clearSession() {
    return _storage.deleteAll();
  }
}
