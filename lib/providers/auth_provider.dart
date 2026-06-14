import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mchs_mobile_app/config/dio_client.dart';
import 'package:mchs_mobile_app/config/app_constants.dart';
import 'package:mchs_mobile_app/services/device_id_service.dart';
import 'package:mchs_mobile_app/services/auth_service.dart';
import 'package:mchs_mobile_app/models/user_model.dart';

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
  bool get isSuperAdmin => user?.isSuperAdmin ?? false;

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

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FlutterSecureStorage _storage;
  final DeviceIdService _deviceIdService;

  AuthNotifier(this._authService, this._storage, this._deviceIdService)
    : super(const AuthState(isLoading: true)) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final deviceId = await _deviceIdService.getDeviceId();
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

  Future<String> getDeviceId() async {
    if (state.deviceId != null) return state.deviceId!;
    final deviceId = await _deviceIdService.getDeviceId();
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
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(
    String username,
    String password, {
    String? lastName,
    String? firstName,
    String? patronymic,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deviceId = await getDeviceId();
      final user = await _authService.register(
        username,
        password,
        deviceId: deviceId,
        lastName: lastName,
        firstName: firstName,
        patronymic: patronymic,
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
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

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
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> convertGuestToUser(
    String username,
    String password, {
    String? lastName,
    String? firstName,
    String? patronymic,
  }) async {
    if (!state.isGuest) {
      state = state.copyWith(error: 'Вы уже зарегистрированы');
      return false;
    }
    return register(
      username,
      password,
      lastName: lastName,
      firstName: firstName,
      patronymic: patronymic,
    );
  }

  Future<void> logout() async {
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

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final storage = ref.watch(secureStorageProvider);
  final deviceIdService = ref.watch(deviceIdServiceProvider);
  return AuthNotifier(authService, storage, deviceIdService);
});
