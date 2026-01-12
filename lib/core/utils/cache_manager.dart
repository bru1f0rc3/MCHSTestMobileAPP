import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mchs_mobile_app/core/config/app_config.dart';

/// Класс для работы с кешем
class CacheManager {
  CacheManager._();

  static SharedPreferences? _prefs;

  /// Инициализация
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Получить данные из кеша
  static Future<T?> get<T>(String key) async {
    await init();
    
    final cacheKey = '${AppConfig.cachePrefix}$key';
    final data = _prefs!.getString(cacheKey);
    
    if (data == null) return null;

    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final timestamp = decoded['timestamp'] as int;
      final value = decoded['value'];

      // Проверка времени жизни кеша
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = (now - timestamp) ~/ 1000; // секунды

      if (age > AppConfig.cacheMaxAge) {
        // Кеш устарел, удаляем
        await remove(key);
        return null;
      }

      return value as T?;
    } catch (e) {
      // Если не удалось декодировать, удаляем кеш
      await remove(key);
      return null;
    }
  }

  /// Сохранить данные в кеш
  static Future<bool> set(String key, dynamic value) async {
    await init();
    
    final cacheKey = '${AppConfig.cachePrefix}$key';
    final now = DateTime.now().millisecondsSinceEpoch;

    final data = {
      'timestamp': now,
      'value': value,
    };

    return _prefs!.setString(cacheKey, jsonEncode(data));
  }

  /// Удалить данные из кеша
  static Future<bool> remove(String key) async {
    await init();
    
    final cacheKey = '${AppConfig.cachePrefix}$key';
    return _prefs!.remove(cacheKey);
  }

  /// Очистить весь кеш
  static Future<void> clearAll() async {
    await init();
    
    final keys = _prefs!.getKeys();
    final cacheKeys = keys.where((k) => k.startsWith(AppConfig.cachePrefix));
    
    for (final key in cacheKeys) {
      await _prefs!.remove(key);
    }
  }

  /// Проверить существование кеша
  static Future<bool> exists(String key) async {
    await init();
    
    final cacheKey = '${AppConfig.cachePrefix}$key';
    return _prefs!.containsKey(cacheKey);
  }

  /// Получить возраст кеша в секундах
  static Future<int?> getCacheAge(String key) async {
    await init();
    
    final cacheKey = '${AppConfig.cachePrefix}$key';
    final data = _prefs!.getString(cacheKey);
    
    if (data == null) return null;

    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final timestamp = decoded['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      return (now - timestamp) ~/ 1000; // секунды
    } catch (e) {
      return null;
    }
  }
}

/// Расширение для работы с кешем в Future
extension CacheFuture<T> on Future<T> {
  /// Кешировать результат Future
  Future<T> cache(String key) async {
    // Проверяем кеш
    final cached = await CacheManager.get<T>(key);
    if (cached != null) {
      return cached;
    }

    // Выполняем запрос и кешируем результат
    final result = await this;
    await CacheManager.set(key, result);
    return result;
  }

  /// Получить из кеша или выполнить Future
  static Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetchFunction,
  ) async {
    // Проверяем кеш
    final cached = await CacheManager.get<T>(key);
    if (cached != null) {
      return cached;
    }

    // Выполняем запрос и кешируем результат
    final result = await fetchFunction();
    await CacheManager.set(key, result);
    return result;
  }
}
