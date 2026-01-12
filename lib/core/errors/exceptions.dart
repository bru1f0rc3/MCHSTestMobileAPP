import 'package:dio/dio.dart';
import 'package:mchs_mobile_app/core/config/app_config.dart';

/// Базовый класс для всех ошибок приложения
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Ошибки сети
class NetworkException extends AppException {
  NetworkException({
    String? message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message ?? ErrorMessages.noInternet,
          code: code,
          originalError: originalError,
        );
}

/// Ошибка таймаута
class TimeoutException extends AppException {
  TimeoutException({
    String? message,
    dynamic originalError,
  }) : super(
          message: message ?? ErrorMessages.timeout,
          code: 'TIMEOUT',
          originalError: originalError,
        );
}

/// Ошибка сервера
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    String? message,
    this.statusCode,
    String? code,
    dynamic originalError,
  }) : super(
          message: message ?? ErrorMessages.serverError,
          code: code,
          originalError: originalError,
        );
}

/// Ошибка авторизации
class UnauthorizedException extends AppException {
  UnauthorizedException({
    String? message,
    dynamic originalError,
  }) : super(
          message: message ?? ErrorMessages.unauthorized,
          code: 'UNAUTHORIZED',
          originalError: originalError,
        );
}

/// Ошибка доступа
class ForbiddenException extends AppException {
  ForbiddenException({
    String? message,
    dynamic originalError,
  }) : super(
          message: message ?? ErrorMessages.forbidden,
          code: 'FORBIDDEN',
          originalError: originalError,
        );
}

/// Данные не найдены
class NotFoundException extends AppException {
  NotFoundException({
    String? message,
    dynamic originalError,
  }) : super(
          message: message ?? ErrorMessages.notFound,
          code: 'NOT_FOUND',
          originalError: originalError,
        );
}

/// Ошибка валидации
class ValidationException extends AppException {
  final List<String>? errors;

  ValidationException({
    String? message,
    this.errors,
    dynamic originalError,
  }) : super(
          message: message ?? 'Ошибка валидации',
          code: 'VALIDATION_ERROR',
          originalError: originalError,
        );
}

/// Неизвестная ошибка
class UnknownException extends AppException {
  UnknownException({
    String? message,
    dynamic originalError,
  }) : super(
          message: message ?? ErrorMessages.unknownError,
          code: 'UNKNOWN',
          originalError: originalError,
        );
}

/// Утилита для преобразования DioException в AppException
class ExceptionHandler {
  ExceptionHandler._();

  static AppException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(originalError: error);

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Проверьте подключение к интернету',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleHttpError(error);

      case DioExceptionType.cancel:
        return UnknownException(
          message: 'Запрос был отменен',
          originalError: error,
        );

      default:
        return UnknownException(originalError: error);
    }
  }

  static AppException _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String? message;
    List<String>? errors;

    // Попытка извлечь сообщение из ответа
    if (data is Map<String, dynamic>) {
      message = data['message'] as String?;
      if (data['errors'] is List) {
        errors = (data['errors'] as List).map((e) => e.toString()).toList();
      }
    }

    switch (statusCode) {
      case 400:
        return ValidationException(
          message: message ?? 'Неверные данные',
          errors: errors,
          originalError: error,
        );

      case 401:
        return UnauthorizedException(
          message: message,
          originalError: error,
        );

      case 403:
        return ForbiddenException(
          message: message,
          originalError: error,
        );

      case 404:
        return NotFoundException(
          message: message,
          originalError: error,
        );

      case 500:
      case 502:
      case 503:
        return ServerException(
          message: message ?? 'Сервер временно недоступен',
          statusCode: statusCode,
          originalError: error,
        );

      default:
        return ServerException(
          message: message ?? 'Ошибка сервера',
          statusCode: statusCode,
          originalError: error,
        );
    }
  }

  static AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    } else if (error is DioException) {
      return handleDioError(error);
    } else {
      return UnknownException(
        message: error.toString(),
        originalError: error,
      );
    }
  }
}
