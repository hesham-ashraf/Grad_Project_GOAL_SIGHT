import 'package:flutter_test/flutter_test.dart';
import 'package:goal_sight/core/constants/app_roles.dart';
import 'package:goal_sight/data/models/user_model.dart';
import 'package:goal_sight/data/repositories/auth_repository.dart';
import 'package:goal_sight/features/auth/auth_controller.dart';
import 'package:goal_sight/features/auth/auth_state.dart';

class FakeAuthRepository implements IAuthRepository {
  UserModel? sessionUser;
  String? token;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<UserModel> login(
      {required String email, required String password}) async {
    token = 'token';
    return UserModel(
      id: '1',
      name: 'Test User',
      email: email,
      role: UserRole.manager,
    );
  }

  @override
  Future<void> logout() async {
    token = null;
    sessionUser = null;
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    token = 'token';
    return UserModel(id: '2', name: name, email: email, role: role);
  }

  @override
  Future<UserModel?> restoreSession() async {
    return sessionUser;
  }
}

void main() {
  group('AuthController', () {
    test('login transitions to authenticated', () async {
      final repo = FakeAuthRepository();
      final controller = AuthController(repo);

      await controller.login(email: 'manager@test.com', password: '123456');

      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.user?.email, 'manager@test.com');
      expect(controller.state.token, 'token');
    });

    test('restoreSession sets unauthenticated when no session', () async {
      final repo = FakeAuthRepository();
      final controller = AuthController(repo);

      await controller.restoreSession();

      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.user, isNull);
    });
  });
}
