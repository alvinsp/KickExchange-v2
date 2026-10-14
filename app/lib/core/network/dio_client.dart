import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../security/secure_storage_helper.dart';

class DioClient {
  final Dio dio;
  final SecureStorageHelper secureStorage;

  DioClient({
    Dio? dioClient,
    required this.secureStorage,
    String? baseUrl,
  }) : dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiEndpoints.defaultBaseUrl,
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 6),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await secureStorage.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }
}
