import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/config/app_constants.dart';
import 'package:mchs_mobile_app/models/api_response.dart';
import 'package:mchs_mobile_app/config/dio_client.dart';
import 'package:mchs_mobile_app/models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider));
});

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<UserModel?> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {'username': username.trim(), 'password': password},
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.toUserModel(apiResponse.data!.token);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> register(
    String username,
    String password, {
    String? deviceId,
    String? lastName,
    String? firstName,
    String? patronymic,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'username': username.trim(),
          'password': password,
          if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
          if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
          if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
          if (patronymic != null && patronymic.isNotEmpty)
            'patronymic': patronymic,
        },
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.toUserModel(apiResponse.data!.token);
      }
      throw Exception(apiResponse.message ?? 'Ошибка регистрации');
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map<String, dynamic>) {
        final msg = (payload['message'] ?? '').toString();
        if (msg.isNotEmpty) throw Exception(msg);
      }
      throw Exception('Ошибка регистрации');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>?> updateProfile({
    String? lastName,
    String? firstName,
    String? patronymic,
  }) async {
    try {
      final response = await _dio.put(
        ApiConfig.me,
        data: {
          'lastName': lastName ?? '',
          'firstName': firstName ?? '',
          'patronymic': patronymic ?? '',
        },
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> loginAsGuest({String? deviceId}) async {
    try {
      final response = await _dio.post(
        ApiConfig.guest,
        data: {if (deviceId != null) 'deviceId': deviceId},
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.toUserModel(apiResponse.data!.token);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<GuestStatusResponse?> getGuestStatus(String deviceId) async {
    try {
      final response = await _dio.post(
        ApiConfig.guestStatus,
        data: {'deviceId': deviceId},
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => GuestStatusResponse.fromJson(json),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _dio.post(
        ApiConfig.changePassword,
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json as bool,
      );
      return apiResponse.success && (apiResponse.data ?? false);
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final response = await _dio.post(ApiConfig.deleteAccount);
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json as bool,
      );
      return apiResponse.success && (apiResponse.data ?? false);
    } catch (_) {
      return false;
    }
  }

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
    } catch (_) {
      return null;
    }
  }
}
