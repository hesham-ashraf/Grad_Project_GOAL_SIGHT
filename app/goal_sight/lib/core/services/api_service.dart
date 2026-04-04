import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'auth_interceptor.dart';
import 'secure_storage_service.dart';

class ApiService {
  ApiService(SecureStorageService secureStorageService)
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
          ),
        ) {
    dio.interceptors.add(AuthInterceptor(secureStorageService));
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  final Dio dio;
}
