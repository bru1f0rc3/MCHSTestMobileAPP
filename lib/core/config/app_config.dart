/// Environment configuration
enum Environment {
  development,
  staging,
  production,
}

/// App Configuration
class AppConfig {
  AppConfig._();

  // Текущее окружение
  static Environment currentEnvironment = Environment.development;

  // App Info
  static const String appName = 'MCHS';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // API URLs для разных окружений
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'http://localhost:5172/api'; // Android emulator
        // return 'http://localhost:5000/api'; // iOS simulator
        // return 'http://YOUR_IP:5000/api'; // Real device
      case Environment.staging:
        return 'https://staging-api.mchs.com/api';
      case Environment.production:
        return 'https://api.mchs.com/api';
    }
  }

  // Feature flags
  static const bool enableDebugMode = true;
  static const bool enableLogging = true;
  static const bool enableCrashReporting = false;

  // Timeout settings (в секундах)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;

  // Retry configuration
  static const int maxRetries = 3;
  static const int retryDelay = 1; // секунд

  // Cache configuration
  static const int cacheMaxAge = 3600; // секунд (1 час)
  static const int cacheMaxSize = 100; // количество элементов
  static const String cachePrefix = 'cache_';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Test configuration
  static const double passingScore = 70.0;
  static const int testTimeWarningThreshold = 300; // секунд (5 минут)

  // Animation durations (в миллисекундах)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 2.0;

  // Support
  static const String supportEmail = 'support@mchs.com';
  static const String supportPhone = '+7 (XXX) XXX-XX-XX';

  // Links
  static const String privacyPolicyUrl = 'https://mchs.com/privacy';
  static const String termsOfServiceUrl = 'https://mchs.com/terms';
}

/// Storage Keys
class StorageKeys {
  StorageKeys._();

  // Auth
  static const String token = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String username = 'username';
  static const String role = 'user_role';
  static const String isLoggedIn = 'is_logged_in';
  static const String tokenExpiry = 'token_expiry';

  // Settings
  static const String theme = 'theme_mode';
  static const String language = 'language';
  static const String notificationsEnabled = 'notifications_enabled';

  // Cache
  static const String cachePrefix = 'cache_';
  static const String lastSyncTime = 'last_sync_time';
}

/// API Endpoints
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String guest = '/auth/guest';
  static const String changePassword = '/auth/change-password';
  static const String me = '/auth/me';

  // Users
  static const String users = '/users';
  static String userById(int id) => '/users/$id';

  // Lectures
  static const String lectures = '/lectures';
  static String lectureById(int id) => '/lectures/$id';

  // Tests
  static const String tests = '/tests';
  static const String availableTests = '/tests/available';
  static String testById(int id) => '/tests/$id';
  static String testByIdFull(int id) => '/tests/$id/full';
  static String testsByLecture(int lectureId) => '/tests/by-lecture/$lectureId';

  // Testing
  static const String testing = '/testing';
  static const String startTest = '/testing/start';
  static const String submitTest = '/testing/submit';
  static const String testResults = '/testing/results';
  static String testResultById(int id) => '/testing/results/$id';

  // Reports
  static const String reports = '/reports';
  static const String userProgress = '/reports/user-progress';
  static const String testStatistics = '/reports/test-statistics';

  // Roles
  static const String roles = '/roles';
}

/// Error Messages
class ErrorMessages {
  ErrorMessages._();

  // Network errors
  static const String noInternet = 'Нет подключения к интернету';
  static const String timeout = 'Превышено время ожидания';
  static const String serverError = 'Ошибка сервера';
  static const String unknownError = 'Произошла неизвестная ошибка';

  // Auth errors
  static const String invalidCredentials = 'Неверное имя пользователя или пароль';
  static const String userExists = 'Пользователь с таким именем уже существует';
  static const String unauthorized = 'Необходима авторизация';
  static const String forbidden = 'Доступ запрещен';

  // Validation errors
  static const String emptyField = 'Поле не может быть пустым';
  static const String invalidEmail = 'Неверный формат email';
  static const String shortPassword = 'Пароль должен содержать минимум 6 символов';
  static const String shortUsername = 'Имя пользователя должно содержать минимум 3 символа';

  // Data errors
  static const String notFound = 'Данные не найдены';
  static const String loadFailed = 'Не удалось загрузить данные';
  static const String saveFailed = 'Не удалось сохранить данные';
}

/// Success Messages
class SuccessMessages {
  SuccessMessages._();

  // Support
  static const String supportEmail = 'support@mchs.com';
  static const String supportPhone = '+7 (XXX) XXX-XX-XX';

  // Links
  static const String privacyPolicyUrl = 'https://mchs.com/privacy';
  static const String termsOfServiceUrl = 'https://mchs.com/terms';
}
