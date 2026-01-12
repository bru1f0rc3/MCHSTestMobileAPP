import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/core/constants/app_constants.dart';
import 'package:mchs_mobile_app/core/models/api_response.dart';
import 'package:mchs_mobile_app/core/network/dio_client.dart';

/// User Service Provider
final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(dioProvider));
});

/// User Service - для управления пользователями (админ)
class UserService {
  final Dio _dio;

  UserService(this._dio);

  /// Get all users (admin only)
  Future<ApiResponse<PagedResponse<UserDto>>> getAll({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.users,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => PagedResponse.fromJson(
          json,
          (item) => UserDto.fromJson(item),
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get user by ID (admin only)
  Future<ApiResponse<UserDto>> getById(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.users}/$id');
      return ApiResponse.fromJson(
        response.data,
        (json) => UserDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Create user (admin only)
  Future<ApiResponse<UserDto>> create(CreateUserRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.users,
        data: request.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => UserDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update user (admin only)
  Future<ApiResponse<bool>> update(int id, UpdateUserRequest request) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.users}/$id',
        data: request.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => json as bool,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete user (admin only)
  Future<ApiResponse<bool>> delete(int id) async {
    try {
      final response = await _dio.delete('${ApiConfig.users}/$id');
      return ApiResponse.fromJson(
        response.data,
        (json) => json as bool,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get roles (admin only)
  Future<ApiResponse<List<RoleDto>>> getRoles() async {
    try {
      final response = await _dio.get(ApiConfig.roles);
      return ApiResponse.fromJson(
        response.data,
        (json) => (json as List).map((e) => RoleDto.fromJson(e)).toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// User DTO
class UserDto {
  final int id;
  final String username;
  final String role;
  final DateTime createdAt;

  UserDto({
    required this.id,
    required this.username,
    required this.role,
    required this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      role: json['role'] ?? json['roleName'] ?? 'guest',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isGuest => role.toLowerCase() == 'guest';
}

/// Create User Request
class CreateUserRequest {
  final String username;
  final String password;
  final int roleId;

  CreateUserRequest({
    required this.username,
    required this.password,
    required this.roleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'roleId': roleId,
    };
  }
}

/// Update User Request
class UpdateUserRequest {
  final String? username;
  final int? roleId;

  UpdateUserRequest({
    this.username,
    this.roleId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (username != null) map['username'] = username;
    if (roleId != null) map['roleId'] = roleId;
    return map;
  }
}

/// Role DTO
class RoleDto {
  final int id;
  final String name;

  RoleDto({
    required this.id,
    required this.name,
  });

  factory RoleDto.fromJson(Map<String, dynamic> json) {
    return RoleDto(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}
