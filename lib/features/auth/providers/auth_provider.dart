import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mchs_mobile_app/core/network/dio_client.dart';
import 'package:mchs_mobile_app/core/constants/app_constants.dart';
import 'package:mchs_mobile_app/features/auth/data/services/auth_service.dart';
import 'package:mchs_mobile_app/features/auth/data/models/user_model.dart';
import 'package:uuid/uuid.dart';

/// Auth State
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final String? deviceId;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
    this.deviceId,
  });

  bool get isGuest => user?.isGuest ?? false;
  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? error,
    String? deviceId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

/// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FlutterSecureStorage _storage;
  static const _deviceIdKey = 'device_id';

  AuthNotifier(this._authService, this._storage) : super(const AuthState(isLoading: true)) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Загружаем или создаем deviceId
    String? deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
    
    final token = await _storage.read(key: StorageKeys.token);
    if (token != null && token.isNotEmpty) {
      final userId = await _storage.read(key: StorageKeys.userId);
      final username = await _storage.read(key: StorageKeys.username);
      final role = await _storage.read(key: StorageKeys.role);

      if (userId != null && username != null && role != null) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          deviceId: deviceId,
          user: UserModel(
            id: int.parse(userId),
            username: username,
            role: role,
            token: token,
          ),
        );
        return;
      }
    }
    
    state = state.copyWith(deviceId: deviceId, isLoading: false);
  }

  /// Получить deviceId
  Future<String> getDeviceId() async {
    if (state.deviceId != null) {
      return state.deviceId!;
    }
    
    String? deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
    
    state = state.copyWith(deviceId: deviceId);
    return deviceId;
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.login(username, password);
      
      if (user != null) {
        await _saveUserData(user);
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: user,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Неверное имя пользователя или пароль',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Регистрация - если пользователь был гостем, его прогресс сохранится
  Future<bool> register(String username, String password, {String? email}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final deviceId = await getDeviceId();
      final user = await _authService.register(
        username, 
        password,
        email: email,
        deviceId: deviceId, // Передаем deviceId для сохранения прогресса гостя
      );
      
      if (user != null) {
        await _saveUserData(user);
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: user,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось зарегистрироваться. Имя пользователя занято.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Вход как гость - использует deviceId для возврата к существующему аккаунту
  Future<bool> loginAsGuest() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final deviceId = await getDeviceId();
      final user = await _authService.loginAsGuest(deviceId: deviceId);
      
      if (user != null) {
        await _saveUserData(user);
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: user,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось войти как гость',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Конвертация гостя в полноценного пользователя
  Future<bool> convertGuestToUser(String username, String password, {String? email}) async {
    if (!state.isGuest) {
      state = state.copyWith(error: 'Вы уже зарегистрированы');
      return false;
    }
    
    return register(username, password, email: email);
  }

  Future<void> logout() async {
    // Сохраняем deviceId при выходе
    final deviceId = state.deviceId;
    await _storage.delete(key: StorageKeys.token);
    await _storage.delete(key: StorageKeys.userId);
    await _storage.delete(key: StorageKeys.username);
    await _storage.delete(key: StorageKeys.role);
    
    state = AuthState(deviceId: deviceId);
  }

  Future<void> _saveUserData(UserModel user) async {
    await _storage.write(key: StorageKeys.token, value: user.token);
    await _storage.write(key: StorageKeys.userId, value: user.id.toString());
    await _storage.write(key: StorageKeys.username, value: user.username);
    await _storage.write(key: StorageKeys.role, value: user.role);
  }
}

/// Auth State Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(authService, storage);
});
