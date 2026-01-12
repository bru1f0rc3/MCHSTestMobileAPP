import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mchs_mobile_app/core/config/app_config.dart';
import 'package:mchs_mobile_app/core/errors/exceptions.dart';

/// Dio client provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: Duration(seconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
      sendTimeout: Duration(seconds: AppConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors
  dio.interceptors.add(AuthInterceptor(ref));
  
  if (AppConfig.enableLogging) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) {
        // Можно интегрировать с logger пакетом
        if (AppConfig.enableDebugMode) {
          print(obj);
        }
      },
    ));
  }

  // Retry interceptor для автоматических повторных попыток
  dio.interceptors.add(RetryInterceptor(dio));

  return dio;
});

/// Secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    webOptions: WebOptions(
      dbName: 'mchs_app',
      publicKey: 'mchs_app_key',
    ),
  );
});

/// Auth interceptor for adding token to requests
class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login/register endpoints
    final noAuthEndpoints = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.guest,
    ];

    if (!noAuthEndpoints.contains(options.path)) {
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.read(key: StorageKeys.token);

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired, clear storage and redirect to login
      final storage = _ref.read(secureStorageProvider);
      await storage.deleteAll();
      // TODO: Navigate to login screen
    }
    handler.next(err);
  }
}

/// Retry Interceptor для автоматических повторных попыток
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxRetries;
  final int retryDelay;

  RetryInterceptor(
    this._dio, {
    this.maxRetries = AppConfig.maxRetries,
    this.retryDelay = AppConfig.retryDelay,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Retry только для определенных типов ошибок
    if (_shouldRetry(err)) {
      int retryCount = 0;
      
      // Получаем количество попыток из extra
      if (err.requestOptions.extra.containsKey('retryCount')) {
        retryCount = err.requestOptions.extra['retryCount'] as int;
      }

      if (retryCount < maxRetries) {
        // Увеличиваем счетчик попыток
        err.requestOptions.extra['retryCount'] = retryCount + 1;

        // Ждем перед повторной попыткой (с экспоненциальной задержкой)
        final delay = retryDelay * (retryCount + 1);
        await Future.delayed(Duration(seconds: delay));

        try {
          // Повторяем запрос
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          // Если снова ошибка, передаем ее дальше
          return handler.next(e);
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry только для network errors и timeout
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

/// API Exception (устаревший, используйте exceptions.dart)
@Deprecated('Используйте AppException из core/errors/exceptions.dart')
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<String>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromDioError(DioException error) {
    final appException = ExceptionHandler.handleDioError(error);
    return ApiException(
      message: appException.message,
      statusCode: appException is ServerException ? appException.statusCode : null,
      errors: appException is ValidationException ? appException.errors : null,
    );
  }

  @override
  String toString() => message;
}
