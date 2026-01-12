// DEPRECATED: Используйте lib/core/config/app_config.dart
// Этот файл оставлен для обратной совместимости

import 'package:mchs_mobile_app/core/config/app_config.dart';

/// API Configuration
/// @deprecated Используйте AppConfig из lib/core/config/app_config.dart
class ApiConfig {
  ApiConfig._();
  
  // Base URL for API
  static String get baseUrl => AppConfig.baseUrl;
  
  // Timeout settings
  static Duration get connectTimeout => Duration(seconds: AppConfig.connectTimeout);
  static Duration get receiveTimeout => Duration(seconds: AppConfig.receiveTimeout);
  static Duration get sendTimeout => Duration(seconds: AppConfig.sendTimeout);
  
  // Endpoints - используйте ApiEndpoints
  static String get auth => ApiEndpoints.auth;
  static String get login => ApiEndpoints.login;
  static String get register => ApiEndpoints.register;
  static String get guest => ApiEndpoints.guest;
  static String get changePassword => ApiEndpoints.changePassword;
  static String get me => ApiEndpoints.me;
  
  static String get users => ApiEndpoints.users;
  static String get lectures => ApiEndpoints.lectures;
  static String get tests => ApiEndpoints.tests;
  static String get availableTests => ApiEndpoints.availableTests;
  static String get testing => ApiEndpoints.testing;
  static String get reports => ApiEndpoints.reports;
  static String get roles => ApiEndpoints.roles;
}

/// Storage Keys
/// @deprecated Используйте StorageKeys из lib/core/config/app_config.dart
class StorageKeys {
  StorageKeys._();
  
  static const String token = 'auth_token';
  static const String userId = 'user_id';
  static const String username = 'username';
  static const String role = 'user_role';
  static const String isLoggedIn = 'is_logged_in';
  static const String tokenExpiry = 'token_expiry';
}

/// App Constants
/// @deprecated Используйте AppConfig из lib/core/config/app_config.dart
class AppConstants {
  AppConstants._();
  
  static String get appName => AppConfig.appName;
  static String get appVersion => AppConfig.appVersion;
  
  // Pagination
  static int get defaultPageSize => AppConfig.defaultPageSize;
  static int get maxPageSize => AppConfig.maxPageSize;
  
  // Test passing threshold
  static double get passingScore => AppConfig.passingScore;
  
  // Animation durations
  static Duration get shortAnimation => Duration(milliseconds: AppConfig.shortAnimationDuration);
  static Duration get mediumAnimation => Duration(milliseconds: AppConfig.mediumAnimationDuration);
  static Duration get longAnimation => Duration(milliseconds: AppConfig.longAnimationDuration);
}
