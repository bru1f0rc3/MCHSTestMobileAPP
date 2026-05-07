import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  ErrorHandler._();
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    if (error is FormatException) {
      return 'Ошибка формата данных';
    }
    if (error is TypeError) {
      return 'Ошибка обработки данных';
    }
    if (error is String) {
      return error;
    }
    return error?.toString() ?? 'Неизвестная ошибка';
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Превышено время ожидания соединения';
      case DioExceptionType.sendTimeout:
        return 'Превышено время отправки запроса';
      case DioExceptionType.receiveTimeout:
        return 'Превышено время получения ответа';
      case DioExceptionType.badCertificate:
        return 'Ошибка сертификата безопасности';
      case DioExceptionType.badResponse:
        return _handleBadResponse(
          error.response?.statusCode,
          error.response?.data,
        );
      case DioExceptionType.cancel:
        return 'Запрос был отменен';
      case DioExceptionType.connectionError:
        return 'Ошибка подключения к серверу. Проверьте интернет-соединение';
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') == true) {
          return 'Нет подключения к интернету';
        }
        return 'Неизвестная сетевая ошибка';
    }
  }

  static String _handleBadResponse(int? statusCode, dynamic data) {
    String? serverMessage;
    if (data is Map) {
      serverMessage =
          data['message'] as String? ??
          data['error'] as String? ??
          data['Message'] as String?;
    }

    switch (statusCode) {
      case 400:
        return serverMessage ?? 'Неверный запрос';
      case 401:
        return 'Необходимо войти в систему';
      case 403:
        return 'Доступ запрещен';
      case 404:
        return serverMessage ?? 'Данные не найдены';
      case 409:
        return serverMessage ?? 'Конфликт данных';
      case 422:
        return serverMessage ?? 'Ошибка валидации данных';
      case 429:
        return 'Слишком много запросов. Подождите немного';
      case 500:
        return 'Внутренняя ошибка сервера';
      case 502:
        return 'Сервер временно недоступен';
      case 503:
        return 'Сервис временно недоступен';
      default:
        return serverMessage ?? 'Ошибка сервера ($statusCode)';
    }
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.error_outline, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, maxLines: 6, softWrap: true),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.check_circle_outline, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, maxLines: 6, softWrap: true),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.warning_amber_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, maxLines: 6, softWrap: true),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Да',
    String cancelText = 'Отмена',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
