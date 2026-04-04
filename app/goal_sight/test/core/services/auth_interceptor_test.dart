import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_sight/core/services/auth_interceptor.dart';
import 'package:goal_sight/core/services/secure_storage_service.dart';

class FakeSecureStorageService extends SecureStorageService {
  const FakeSecureStorageService(this._token);

  final String? _token;

  @override
  Future<String?> readToken() async => _token;
}

void main() {
  test('AuthInterceptor attaches bearer token when available', () async {
    final interceptor =
        AuthInterceptor(const FakeSecureStorageService('jwt-token'));

    final options = RequestOptions(path: '/auth/login');
    final handler = RequestInterceptorHandler();

    await interceptor.onRequest(options, handler);

    expect(options.headers['Authorization'], 'Bearer jwt-token');
  });
}
