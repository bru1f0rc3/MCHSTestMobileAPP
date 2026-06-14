class User {
  final int id;
  final String username;
  final String role;
  final String? email;
  final String? lastName;
  final String? firstName;
  final String? patronymic;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.email,
    this.lastName,
    this.firstName,
    this.patronymic,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['userId'] ?? 0,
      username: json['username'] ?? '',
      role: json['role'] ?? json['roleName'] ?? 'guest',
      email: json['email'] as String?,
      lastName: json['lastName'] as String?,
      firstName: json['firstName'] as String?,
      patronymic: json['patronymic'] as String?,
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
      'email': email,
      'lastName': lastName,
      'firstName': firstName,
      'patronymic': patronymic,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isSuperAdmin => role.toLowerCase() == 'superadmin';
  bool get isAdmin =>
      role.toLowerCase() == 'admin' || role.toLowerCase() == 'superadmin';
  bool get isGuest => role.toLowerCase() == 'guest';
  String get shortName {
    final ln = (lastName ?? '').trim();
    if (ln.isEmpty) return username;
    final fn = (firstName ?? '').trim();
    final pn = (patronymic ?? '').trim();
    final buf = StringBuffer(ln);
    if (fn.isNotEmpty) buf.write(' ${fn[0]}.');
    if (pn.isNotEmpty) buf.write(' ${pn[0]}.');
    return buf.toString();
  }

  String get fullName {
    final parts = [lastName, firstName, patronymic]
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim())
        .toList();
    return parts.isEmpty ? username : parts.join(' ');
  }

  User copyWith({
    int? id,
    String? username,
    String? role,
    String? email,
    String? lastName,
    String? firstName,
    String? patronymic,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      email: email ?? this.email,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      patronymic: patronymic ?? this.patronymic,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

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

  bool get isSuperAdmin => role.toLowerCase() == 'superadmin';
  bool get isAdmin =>
      role.toLowerCase() == 'admin' || role.toLowerCase() == 'superadmin';
  bool get isGuest => role.toLowerCase() == 'guest';
}

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

  bool get isSuperAdmin => role.toLowerCase() == 'superadmin';
  bool get isAdmin =>
      role.toLowerCase() == 'admin' || role.toLowerCase() == 'superadmin';

  UserModel toUserModel([String? tokenOverride]) {
    return UserModel(
      id: userId,
      username: username,
      role: role,
      token: tokenOverride ?? token,
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

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}

class RegisterRequest {
  final String username;
  final String password;
  final String? lastName;
  final String? firstName;
  final String? patronymic;
  final String? deviceId;

  RegisterRequest({
    required this.username,
    required this.password,
    this.lastName,
    this.firstName,
    this.patronymic,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      if (lastName != null && lastName!.isNotEmpty) 'lastName': lastName,
      if (firstName != null && firstName!.isNotEmpty) 'firstName': firstName,
      if (patronymic != null && patronymic!.isNotEmpty)
        'patronymic': patronymic,
      if (deviceId != null && deviceId!.isNotEmpty) 'deviceId': deviceId,
    };
  }
}

class UpdateProfileRequest {
  final String? lastName;
  final String? firstName;
  final String? patronymic;

  UpdateProfileRequest({this.lastName, this.firstName, this.patronymic});

  Map<String, dynamic> toJson() {
    return {
      'lastName': lastName ?? '',
      'firstName': firstName ?? '',
      'patronymic': patronymic ?? '',
    };
  }
}

class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequest({required this.oldPassword, required this.newPassword});

  Map<String, dynamic> toJson() {
    return {'oldPassword': oldPassword, 'newPassword': newPassword};
  }
}

class GuestStatusResponse {
  final bool hasExistingAccount;
  final bool isGuestAccount;
  final String? username;

  const GuestStatusResponse({
    required this.hasExistingAccount,
    required this.isGuestAccount,
    this.username,
  });

  factory GuestStatusResponse.fromJson(Map<String, dynamic> json) {
    return GuestStatusResponse(
      hasExistingAccount: (json['hasExistingAccount'] ?? false) as bool,
      isGuestAccount: (json['isGuestAccount'] ?? false) as bool,
      username: json['username'] as String?,
    );
  }
}

class CreateUserRequest {
  final String username;
  final String password;
  final int roleId;
  final String? lastName;
  final String? firstName;
  final String? patronymic;

  CreateUserRequest({
    required this.username,
    required this.password,
    required this.roleId,
    this.lastName,
    this.firstName,
    this.patronymic,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'roleId': roleId,
      if (lastName != null && lastName!.isNotEmpty) 'lastName': lastName,
      if (firstName != null && firstName!.isNotEmpty) 'firstName': firstName,
      if (patronymic != null && patronymic!.isNotEmpty)
        'patronymic': patronymic,
    };
  }
}

class UpdateUserRequest {
  final String? username;
  final String? password;
  final int? roleId;
  final String? lastName;
  final String? firstName;
  final String? patronymic;

  UpdateUserRequest({
    this.username,
    this.password,
    this.roleId,
    this.lastName,
    this.firstName,
    this.patronymic,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (username != null) map['username'] = username;
    if (password != null) map['password'] = password;
    if (roleId != null) map['roleId'] = roleId;
    if (lastName != null) map['lastName'] = lastName;
    if (firstName != null) map['firstName'] = firstName;
    if (patronymic != null) map['patronymic'] = patronymic;
    return map;
  }
}
