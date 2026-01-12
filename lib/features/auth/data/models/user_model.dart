/// User model
class User {
  final int id;
  final String username;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      role: json['role'] ?? json['roleName'] ?? 'guest',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isGuest => role.toLowerCase() == 'guest';

  User copyWith({
    int? id,
    String? username,
    String? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// User Model (for auth state)
class UserModel {
  final int id;
  final String username;
  final String role;
  final String token;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.token,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isGuest => role.toLowerCase() == 'guest';
}

/// Auth Response
class AuthResponse {
  final int userId;
  final String username;
  final String role;
  final String token;
  final DateTime expiresAt;

  AuthResponse({
    required this.userId,
    required this.username,
    required this.role,
    required this.token,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      role: json['role'] ?? 'guest',
      token: json['token'] ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(days: 1)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'role': role,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  
  UserModel toUserModel(String token) {
    return UserModel(
      id: userId,
      username: username,
      role: role,
      token: token,
    );
  }
  
  User toUser() {
    return User(
      id: userId,
      username: username,
      role: role,
      createdAt: DateTime.now(),
    );
  }
}

/// Login Request
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

/// Register Request
class RegisterRequest {
  final String username;
  final String password;

  RegisterRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

/// Change Password Request
class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
  }
}

/// Create User Request (admin)
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

/// Update User Request (admin)
class UpdateUserRequest {
  final String? username;
  final String? password;
  final int? roleId;

  UpdateUserRequest({
    this.username,
    this.password,
    this.roleId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (username != null) map['username'] = username;
    if (password != null) map['password'] = password;
    if (roleId != null) map['roleId'] = roleId;
    return map;
  }
}
