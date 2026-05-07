import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mchs_mobile_app/config/app_config.dart';

class CacheManager {
  CacheManager._();

  static SharedPreferences? _prefs;
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<T?> get<T>(String key) async {
    await init();

    final cacheKey = '${AppConfig.cachePrefix}$key';
    final data = _prefs!.getString(cacheKey);

    if (data == null) return null;

    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final timestamp = decoded['timestamp'] as int;
      final value = decoded['value'];
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = (now - timestamp) ~/ 1000;

      if (age > AppConfig.cacheMaxAge) {
        await remove(key);
        return null;
      }

      return value as T?;
    } catch (e) {
      await remove(key);
      return null;
    }
  }

  static Future<bool> set(String key, dynamic value) async {
    await init();

    final cacheKey = '${AppConfig.cachePrefix}$key';
    final now = DateTime.now().millisecondsSinceEpoch;

    final data = {'timestamp': now, 'value': value};

    return _prefs!.setString(cacheKey, jsonEncode(data));
  }

  static Future<bool> remove(String key) async {
    await init();

    final cacheKey = '${AppConfig.cachePrefix}$key';
    return _prefs!.remove(cacheKey);
  }

  static Future<void> clearAll() async {
    await init();

    final keys = _prefs!.getKeys();
    final cacheKeys = keys.where((k) => k.startsWith(AppConfig.cachePrefix));

    for (final key in cacheKeys) {
      await _prefs!.remove(key);
    }
  }

  static Future<bool> exists(String key) async {
    await init();

    final cacheKey = '${AppConfig.cachePrefix}$key';
    return _prefs!.containsKey(cacheKey);
  }

  static Future<int?> getCacheAge(String key) async {
    await init();

    final cacheKey = '${AppConfig.cachePrefix}$key';
    final data = _prefs!.getString(cacheKey);

    if (data == null) return null;

    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final timestamp = decoded['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      return (now - timestamp) ~/ 1000;
    } catch (e) {
      return null;
    }
  }
}

extension CacheFuture<T> on Future<T> {
  Future<T> cache(String key) async {
    final cached = await CacheManager.get<T>(key);
    if (cached != null) {
      return cached;
    }
    final result = await this;
    await CacheManager.set(key, result);
    return result;
  }

  static Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetchFunction,
  ) async {
    final cached = await CacheManager.get<T>(key);
    if (cached != null) {
      return cached;
    }
    final result = await fetchFunction();
    await CacheManager.set(key, result);
    return result;
  }
}
