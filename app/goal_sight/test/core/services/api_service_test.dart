import 'package:flutter_test/flutter_test.dart';
import 'package:goal_sight/core/constants/api_constants.dart';
import 'package:goal_sight/core/services/api_service.dart';
import 'package:goal_sight/core/services/auth_interceptor.dart';
import 'package:goal_sight/core/services/secure_storage_service.dart';

class FakeSecureStorageService extends SecureStorageService {
  const FakeSecureStorageService(this._token);

  final String? _token;

  @override
  Future<String?> readToken() async => _token;
}

void main() {
  test('ApiService uses configured baseUrl and auth interceptor', () {
    final service = ApiService(const FakeSecureStorageService('mock-token'));

    expect(service.dio.options.baseUrl, ApiConstants.baseUrl);
    expect(
      service.dio.interceptors
          .any((interceptor) => interceptor is AuthInterceptor),
      isTrue,
    );
  });
}
