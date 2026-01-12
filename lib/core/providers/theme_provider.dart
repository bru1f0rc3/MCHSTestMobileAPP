import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mchs_mobile_app/core/network/dio_client.dart';

/// Ключ для хранения темы
const _themeKey = 'app_theme_mode';

/// Состояние темы
class ThemeState {
  final ThemeMode themeMode;
  final bool isLoading;

  const ThemeState({
    this.themeMode = ThemeMode.light,
    this.isLoading = true,
  });

  bool get isDark => themeMode == ThemeMode.dark;

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isLoading,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier для управления темой
class ThemeNotifier extends StateNotifier<ThemeState> {
  final FlutterSecureStorage _storage;

  ThemeNotifier(this._storage) : super(const ThemeState()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final savedTheme = await _storage.read(key: _themeKey);
      final themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      state = ThemeState(themeMode: themeMode, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleTheme() async {
    final newMode = state.isDark ? ThemeMode.light : ThemeMode.dark;
    state = state.copyWith(themeMode: newMode);
    await _storage.write(
      key: _themeKey,
      value: newMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.write(
      key: _themeKey,
      value: mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

/// Провайдер темы
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ThemeNotifier(storage);
});
