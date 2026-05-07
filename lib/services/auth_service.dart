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
        data: {'username': username, 'password': password},
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

  Future<UserModel?> register(
    String username,
    String password, {
    required String email,
    required String verificationCode,
    String? deviceId,
    String? lastName,
    String? firstName,
    String? patronymic,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'username': username,
          'password': password,
          'email': email.trim(),
          'verificationCode': verificationCode.trim(),
          if (deviceId != null) 'deviceId': deviceId,
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
    } catch (e) {
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

  Future<bool> changePassword(
    String oldPassword,
    String newPassword, {
    required String verificationCode,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.changePassword,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'verificationCode': verificationCode.trim(),
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

  Future<bool> sendVerificationCode({
    required String email,
    required String purpose,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.sendCode,
        data: {'email': email.trim(), 'purpose': purpose},
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

  Future<String?> requestForgotPasswordCode(String loginOrEmail) async {
    try {
      final response = await _dio.post(
        ApiConfig.forgotPasswordRequestCode,
        data: {'loginOrEmail': loginOrEmail.trim()},
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => ForgotPasswordResponse.fromJson(json),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.maskedEmail;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> confirmForgotPassword({
    required String loginOrEmail,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.forgotPasswordConfirm,
        data: {
          'loginOrEmail': loginOrEmail.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
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

  Future<String?> requestChangePasswordCode() async {
    try {
      final response = await _dio.post(ApiConfig.requestChangePasswordCode);
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return (apiResponse.data!['maskedEmail'] as String?) ?? '';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> requestCurrentEmailChangeCode() async {
    try {
      final response = await _dio.post(ApiConfig.requestCurrentEmailCode);
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return (apiResponse.data!['maskedEmail'] as String?) ?? '';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> verifyCurrentEmailCode({
    required String currentEmailCode,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.verifyCurrentEmailCode,
        data: {'code': currentEmailCode.trim()},
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

  Future<String?> requestNewEmailCode({required String newEmail}) async {
    try {
      final response = await _dio.post(
        ApiConfig.requestNewEmailCode,
        data: {'newEmail': newEmail.trim()},
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return (apiResponse.data!['maskedEmail'] as String?) ?? '';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> confirmNewEmail(String code, String newEmail) async {
    try {
      final response = await _dio.post(
        ApiConfig.confirmNewEmail,
        data: {'code': code.trim(), 'newEmail': newEmail.trim()},
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json as bool,
      );
      if (apiResponse.success && (apiResponse.data ?? false)) {
        return null;
      }
      return apiResponse.message ?? 'Не удалось подтвердить новую почту';
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map<String, dynamic>) {
        final msg = (payload['message'] ?? '').toString();
        if (msg.isNotEmpty) return msg;
      }
      return 'Ошибка сети при подтверждении новой почты';
    } catch (_) {
      return 'Не удалось подтвердить новую почту';
    }
  }

  Future<String?> requestDeleteAccountCode() async {
    try {
      final response = await _dio.post(ApiConfig.requestDeleteAccountCode);
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return (apiResponse.data!['maskedEmail'] as String?) ?? '';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteAccount({required String code}) async {
    try {
      final response = await _dio.post(
        ApiConfig.deleteAccount,
        data: {'code': code.trim()},
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
