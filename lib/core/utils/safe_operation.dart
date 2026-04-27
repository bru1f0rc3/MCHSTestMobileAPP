import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_handler.dart';

class AsyncResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const AsyncResult._({this.data, this.error, required this.isSuccess});

  factory AsyncResult.success(T data) =>
      AsyncResult._(data: data, isSuccess: true);
  factory AsyncResult.failure(String error) =>
      AsyncResult._(error: error, isSuccess: false);

  R fold<R>(R Function(T data) onSuccess, R Function(String error) onFailure) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    }
    return onFailure(error ?? 'Неизвестная ошибка');
  }
}

class SafeOperation {
  SafeOperation._();
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
              Flexible(child: Text(loadingMessage ?? 'Загрузка...')),
            ],
          ),
        ),
      ),
    );

    try {
      await operation();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      if (successMessage != null && context.mounted) {
        ErrorHandler.showSuccessSnackBar(context, successMessage);
      }

      onSuccess?.call();
      return true;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      final errorMessage = ErrorHandler.getErrorMessage(e);
      final fullError = errorPrefix != null
          ? '$errorPrefix: $errorMessage'
          : errorMessage;

      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(context, fullError);
      }

      onError?.call(fullError);
      return false;
    }
  }

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

extension SafeContextExtension on BuildContext {
  bool get isMounted => mounted;
  void safeCall(VoidCallback callback) {
    if (mounted) {
      callback();
    }
  }
}

extension SafeRefExtension on WidgetRef {
  T? safeRead<T>(ProviderListenable<T> provider) {
    try {
      return read(provider);
    } catch (e) {
      return null;
    }
  }
}
