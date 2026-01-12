import 'package:flutter/foundation.dart';
import 'package:mchs_mobile_app/core/config/app_config.dart';

/// Уровни логирования
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Сервис логирования
class Logger {
  Logger._();

  static const String _prefix = '[MCHS]';
  static const bool _enabled = AppConfig.enableLogging;

  /// Debug log
  static void debug(String message, {String? tag, dynamic data}) {
    if (!_enabled || !AppConfig.enableDebugMode) return;
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Info log
  static void info(String message, {String? tag, dynamic data}) {
    if (!_enabled) return;
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Warning log
  static void warning(String message, {String? tag, dynamic data}) {
    if (!_enabled) return;
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// Error log
  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;
    _log(
      LogLevel.error,
      message,
      tag: tag,
      data: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final tagStr = tag != null ? '[$tag]' : '';
    
    final logMessage = '$_prefix $timestamp $levelStr $tagStr $message';

    if (kDebugMode) {
      // ignore: avoid_print
      print(logMessage);
      
      if (data != null) {
        // ignore: avoid_print
        print('  Data: $data');
      }
      
      if (stackTrace != null) {
        // ignore: avoid_print
        print('  StackTrace:\n$stackTrace');
      }
    }

    // TODO: В production можно отправлять логи в сервис (Firebase Crashlytics, Sentry, etc.)
    if (AppConfig.currentEnvironment == Environment.production && 
        AppConfig.enableCrashReporting) {
      // _sendToRemoteLoggingService(logMessage, level, data, stackTrace);
    }
  }

  /// Логирование API запросов
  static void apiRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (!_enabled) return;
    
    final message = StringBuffer();
    message.writeln('→ API Request');
    message.writeln('  Method: $method');
    message.writeln('  URL: $url');
    
    if (headers != null && headers.isNotEmpty) {
      message.writeln('  Headers: $headers');
    }
    
    if (body != null) {
      message.writeln('  Body: $body');
    }

    debug(message.toString(), tag: 'API');
  }

  /// Логирование API ответов
  static void apiResponse({
    required String url,
    required int statusCode,
    dynamic body,
    Duration? duration,
  }) {
    if (!_enabled) return;
    
    final message = StringBuffer();
    message.writeln('← API Response');
    message.writeln('  URL: $url');
    message.writeln('  Status: $statusCode');
    
    if (duration != null) {
      message.writeln('  Duration: ${duration.inMilliseconds}ms');
    }
    
    if (body != null) {
      message.writeln('  Body: $body');
    }

    debug(message.toString(), tag: 'API');
  }

  /// Логирование навигации
  static void navigation(String route, {Map<String, dynamic>? params}) {
    if (!_enabled) return;
    
    final message = StringBuffer();
    message.write('Navigate to: $route');
    
    if (params != null && params.isNotEmpty) {
      message.write(' with params: $params');
    }

    debug(message.toString(), tag: 'Navigation');
  }

  /// Логирование событий State Management
  static void state(String event, {dynamic data}) {
    if (!_enabled || !AppConfig.enableDebugMode) return;
    
    final message = StringBuffer();
    message.write('State: $event');
    
    if (data != null) {
      message.write(' → $data');
    }

    debug(message.toString(), tag: 'State');
  }
}
