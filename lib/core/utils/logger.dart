import 'package:flutter/foundation.dart';
import 'package:mchs_mobile_app/core/config/app_config.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  Logger._();

  static const String _prefix = '[MCHS]';
  static const bool _enabled = AppConfig.enableLogging;
  static void debug(String message, {String? tag, dynamic data}) {
    if (!_enabled || !AppConfig.enableDebugMode) return;
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  static void info(String message, {String? tag, dynamic data}) {
    if (!_enabled) return;
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  static void warning(String message, {String? tag, dynamic data}) {
    if (!_enabled) return;
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

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
      print(logMessage);

      if (data != null) {
        print('  Data: $data');
      }

      if (stackTrace != null) {
        print('  StackTrace:\n$stackTrace');
      }
    }
    if (AppConfig.currentEnvironment == Environment.production &&
        AppConfig.enableCrashReporting) {}
  }

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

  static void navigation(String route, {Map<String, dynamic>? params}) {
    if (!_enabled) return;

    final message = StringBuffer();
    message.write('Navigate to: $route');

    if (params != null && params.isNotEmpty) {
      message.write(' with params: $params');
    }

    debug(message.toString(), tag: 'Navigation');
  }

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
