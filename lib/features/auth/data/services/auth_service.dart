import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/core/constants/app_constants.dart';
import 'package:mchs_mobile_app/core/models/api_response.dart';
import 'package:mchs_mobile_app/core/network/dio_client.dart';
import 'package:mchs_mobile_app/features/auth/data/models/user_model.dart';

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider));
});

/// Auth Service
class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  /// Login
  Future<UserModel?> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {
          'username': username,
          'password': password,
        },
      );
      
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json),
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.toUserModel(apiResponse.data!.token);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Register - поддерживает deviceId для сохранения прогресса гостя
  Future<UserModel?> register(
    String username, 
    String password, {
    String? email,
    String? deviceId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'username': username,
          'password': password,
          if (email != null) 'email': email,
          if (deviceId != null) 'deviceId': deviceId,
        },
      );
      
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json),
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.toUserModel(apiResponse.data!.token);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Register as guest - использует deviceId для идентификации устройства
  Future<UserModel?> loginAsGuest({String? deviceId}) async {
    try {
      final response = await _dio.post(
        ApiConfig.guest,
        data: {
          if (deviceId != null) 'deviceId': deviceId,
        },
      );
      
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json),
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.toUserModel(apiResponse.data!.token);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _dio.post(
        ApiConfig.changePassword,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
      
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json as bool,
      );
      
      return apiResponse.success && (apiResponse.data ?? false);
    } catch (e) {
      return false;
    }
  }

  /// Get current user info
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConfig.me);
      
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
