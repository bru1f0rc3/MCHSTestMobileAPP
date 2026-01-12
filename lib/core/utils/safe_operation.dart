import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_handler.dart';

/// Результат асинхронной операции
class AsyncResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const AsyncResult._({this.data, this.error, required this.isSuccess});

  factory AsyncResult.success(T data) => AsyncResult._(data: data, isSuccess: true);
  factory AsyncResult.failure(String error) => AsyncResult._(error: error, isSuccess: false);

  R fold<R>(R Function(T data) onSuccess, R Function(String error) onFailure) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    }
    return onFailure(error ?? 'Неизвестная ошибка');
  }
}

/// Утилиты для безопасного выполнения операций
class SafeOperation {
  SafeOperation._();

  /// Выполнить асинхронную операцию с обработкой ошибок
  static Future<AsyncResult<T>> execute<T>(
    Future<T> Function() operation, {
    String? errorPrefix,
  }) async {
    try {
      final result = await operation();
      return AsyncResult.success(result);
    } catch (e) {
      final errorMessage = ErrorHandler.getErrorMessage(e);
      return AsyncResult.failure(
        errorPrefix != null ? '$errorPrefix: $errorMessage' : errorMessage,
      );
    }
  }

  /// Выполнить операцию с индикатором загрузки и обработкой ошибок
  static Future<bool> executeWithUI<T>(
    BuildContext context,
    WidgetRef ref,
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    String? errorPrefix,
    VoidCallback? onSuccess,
    void Function(String error)? onError,
  }) async {
    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Flexible(
                child: Text(loadingMessage ?? 'Загрузка...'),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await operation();
      
      // Закрываем индикатор загрузки
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Показываем сообщение об успехе
      if (successMessage != null && context.mounted) {
        ErrorHandler.showSuccessSnackBar(context, successMessage);
      }
      
      onSuccess?.call();
      return true;
    } catch (e) {
      // Закрываем индикатор загрузки
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      final errorMessage = ErrorHandler.getErrorMessage(e);
      final fullError = errorPrefix != null ? '$errorPrefix: $errorMessage' : errorMessage;
      
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(context, fullError);
      }
      
      onError?.call(fullError);
      return false;
    }
  }

  /// Выполнить операцию с подтверждением
  static Future<bool> executeWithConfirmation<T>(
    BuildContext context,
    WidgetRef ref, {
    required String confirmTitle,
    required String confirmMessage,
    required Future<T> Function() operation,
    String? loadingMessage,
    String? successMessage,
    String? errorPrefix,
    bool isDangerous = false,
    VoidCallback? onSuccess,
  }) async {
    final confirmed = await ErrorHandler.showConfirmDialog(
      context,
      title: confirmTitle,
      message: confirmMessage,
      isDangerous: isDangerous,
    );

    if (!confirmed || !context.mounted) {
      return false;
    }

    return executeWithUI(
      context,
      ref,
      operation,
      loadingMessage: loadingMessage,
      successMessage: successMessage,
      errorPrefix: errorPrefix,
      onSuccess: onSuccess,
    );
  }
}

/// Расширение для BuildContext
extension SafeContextExtension on BuildContext {
  /// Проверить, что контекст все еще действителен
  bool get isMounted => mounted;
  
  /// Безопасно выполнить callback если контекст действителен
  void safeCall(VoidCallback callback) {
    if (mounted) {
      callback();
    }
  }
}

/// Расширение для WidgetRef
extension SafeRefExtension on WidgetRef {
  /// Безопасно прочитать провайдер
  T? safeRead<T>(ProviderListenable<T> provider) {
    try {
      return read(provider);
    } catch (e) {
      return null;
    }
  }
}
