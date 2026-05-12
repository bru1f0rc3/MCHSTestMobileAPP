import 'package:mchs_mobile_app/config/app_config.dart';
export 'package:mchs_mobile_app/config/app_config.dart';

class ApiConfig {
  ApiConfig._();
  static String get baseUrl => AppConfig.baseUrl;
  static Duration get connectTimeout =>
      const Duration(seconds: AppConfig.connectTimeout);
  static Duration get receiveTimeout =>
      const Duration(seconds: AppConfig.receiveTimeout);
  static Duration get sendTimeout =>
      const Duration(seconds: AppConfig.sendTimeout);
  static String get auth => ApiEndpoints.auth;
  static String get login => ApiEndpoints.login;
  static String get register => ApiEndpoints.register;
  static String get guest => ApiEndpoints.guest;
  static String get guestStatus => ApiEndpoints.guestStatus;
  static String get changePassword => ApiEndpoints.changePassword;
  static String get deleteAccount => ApiEndpoints.deleteAccount;
  static String get me => ApiEndpoints.me;

  static String get users => ApiEndpoints.users;
  static String get lectures => ApiEndpoints.lectures;
  static String get tests => ApiEndpoints.tests;
  static String get availableTests => ApiEndpoints.availableTests;
  static String get testing => ApiEndpoints.testing;
  static String get reports => ApiEndpoints.reports;
  static String get roles => ApiEndpoints.roles;
}

class AppConstants {
  AppConstants._();

  static String get appName => AppConfig.appName;
  static String get appVersion => AppConfig.appVersion;
  static int get defaultPageSize => AppConfig.defaultPageSize;
  static int get maxPageSize => AppConfig.maxPageSize;
  static double get passingScore => AppConfig.passingScore;
  static Duration get shortAnimation =>
      const Duration(milliseconds: AppConfig.shortAnimationDuration);
  static Duration get mediumAnimation =>
      const Duration(milliseconds: AppConfig.mediumAnimationDuration);
  static Duration get longAnimation =>
      const Duration(milliseconds: AppConfig.longAnimationDuration);
}
