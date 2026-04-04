import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_roles.dart';
import '../models/auth_response_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      if (!ApiConstants.enableMockFallback) rethrow;
      final normalizedEmail = email.toLowerCase();
      final role = normalizedEmail.contains('admin')
          ? UserRole.admin
          : normalizedEmail.contains('manager')
              ? UserRole.manager
              : UserRole.fan;
      return AuthResponseModel.fromJson({
        'token': 'mock-jwt-token',
        'user': {
          'id': '1',
          'name': role == UserRole.admin
              ? 'Admin User'
              : role == UserRole.manager
                  ? 'Manager User'
                  : 'Fan User',
          'email': email,
          'role': role.value,
        },
      });
    }
  }

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.registerEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role.value,
        },
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      if (!ApiConstants.enableMockFallback) rethrow;
      return AuthResponseModel.fromJson({
        'token': 'mock-jwt-token',
        'user': {
          'id': '2',
          'name': name,
          'email': email,
          'role': role.value,
        },
      });
    }
  }
}
