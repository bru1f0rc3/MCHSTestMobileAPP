import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mchs_mobile_app/config/app_config.dart';
import 'package:mchs_mobile_app/config/exceptions.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: AppConfig.connectTimeout),
      receiveTimeout: const Duration(seconds: AppConfig.receiveTimeout),
      sendTimeout: const Duration(seconds: AppConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref));

  if (AppConfig.enableLogging) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) {
          if (AppConfig.enableDebugMode) {
            developer.log(obj.toString(), name: 'DIO');
          }
        },
      ),
    );
  }
  dio.interceptors.add(RetryInterceptor(dio));

  return dio;
});
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    webOptions: WebOptions(dbName: 'mchs_app', publicKey: 'mchs_app_key'),
  );
});

class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final noAuthEndpoints = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.guest,
      ApiEndpoints.guestStatus,
    ];

    if (!noAuthEndpoints.contains(options.path)) {
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.read(key: StorageKeys.token);

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        developer.log('No token for ${options.path}', name: 'AUTH');
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      developer.log('401 on ${err.requestOptions.path}', name: 'AUTH');
    }
    handler.next(err);
  }
}

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
    if (_shouldRetry(err)) {
      int retryCount = 0;
      if (err.requestOptions.extra.containsKey('retryCount')) {
        retryCount = err.requestOptions.extra['retryCount'] as int;
      }

      if (retryCount < maxRetries) {
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        final delay = retryDelay * (retryCount + 1);
        await Future.delayed(Duration(seconds: delay));

        try {
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<String>? errors;

  ApiException({required this.message, this.statusCode, this.errors});

  factory ApiException.fromDioError(DioException error) {
    final appException = ExceptionHandler.handleDioError(error);
    return ApiException(
      message: appException.message,
      statusCode: appException is ServerException
          ? appException.statusCode
          : null,
      errors: appException is ValidationException ? appException.errors : null,
    );
  }

  @override
  String toString() => message;
}
