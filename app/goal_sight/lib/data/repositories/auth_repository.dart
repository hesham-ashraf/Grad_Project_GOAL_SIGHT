import '../../core/constants/app_roles.dart';
import '../../core/services/secure_storage_service.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

abstract class IAuthRepository {
  Future<UserModel> login({required String email, required String password});

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<UserModel?> restoreSession();

  Future<void> logout();

  Future<String?> getToken();
}

class AuthRepository implements IAuthRepository {
  AuthRepository(this._remoteDataSource, this._secureStorageService);

  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorageService;

  @override
  Future<UserModel> login(
      {required String email, required String password}) async {
    final response =
        await _remoteDataSource.login(email: email, password: password);
    await _secureStorageService.saveToken(response.token);
    await _secureStorageService.saveRole(response.user.role.value);
    return response.user;
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final response = await _remoteDataSource.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    await _secureStorageService.saveToken(response.token);
    await _secureStorageService.saveRole(response.user.role.value);
    return response.user;
  }

  @override
  Future<UserModel?> restoreSession() async {
    final token = await _secureStorageService.readToken();
    final storedRole = await _secureStorageService.readRole();

    if (token == null || token.isEmpty || storedRole == null) {
      return null;
    }

    return UserModel(
      id: 'session-user',
      name: 'Authenticated User',
      email: 'session@goalsight.ai',
      role: parseUserRole(storedRole),
    );
  }

  @override
  Future<void> logout() {
    return _secureStorageService.clearSession();
  }

  @override
  Future<String?> getToken() {
    return _secureStorageService.readToken();
  }
}
