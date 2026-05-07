import 'package:flutter_test/flutter_test.dart';
import 'package:mchs_mobile_app/models/user_model.dart';

void main() {
  group('User.fromJson', () {
    test('parses full json', () {
      final user = User.fromJson({
        'id': 5,
        'username': 'admin',
        'role': 'admin',
        'email': 'admin@example.com',
        'lastName': 'Иванов',
        'firstName': 'Иван',
        'patronymic': 'Иванович',
        'createdAt': '2025-01-01T10:00:00Z',
      });

      expect(user.id, 5);
      expect(user.username, 'admin');
      expect(user.role, 'admin');
      expect(user.email, 'admin@example.com');
      expect(user.fullName, 'Иванов Иван Иванович');
    });

    test('uses userId fallback', () {
      final user = User.fromJson({'userId': 3, 'username': 'u'});
      expect(user.id, 3);
    });

    test('defaults role to guest', () {
      final user = User.fromJson({'id': 1, 'username': 'u'});
      expect(user.role, 'guest');
    });
  });

  group('User flags', () {
    test('isAdmin true for admin role', () {
      final user = User(id: 1, username: 'a', role: 'admin', createdAt: DateTime.now());
      expect(user.isAdmin, isTrue);
      expect(user.isGuest, isFalse);
    });

    test('isAdmin case-insensitive', () {
      final user = User(id: 1, username: 'a', role: 'ADMIN', createdAt: DateTime.now());
      expect(user.isAdmin, isTrue);
    });

    test('isGuest true for guest role', () {
      final user = User(id: 1, username: 'g', role: 'guest', createdAt: DateTime.now());
      expect(user.isGuest, isTrue);
      expect(user.isAdmin, isFalse);
    });
  });

  group('User.shortName', () {
    test('returns username when no last name', () {
      final user = User(id: 1, username: 'login1', role: 'user', createdAt: DateTime.now());
      expect(user.shortName, 'login1');
    });

    test('returns last name with initials', () {
      final user = User(
        id: 1,
        username: 'u',
        role: 'user',
        lastName: 'Петров',
        firstName: 'Алексей',
        patronymic: 'Сергеевич',
        createdAt: DateTime.now(),
      );
      expect(user.shortName, 'Петров А. С.');
    });

    test('skips missing patronymic', () {
      final user = User(
        id: 1,
        username: 'u',
        role: 'user',
        lastName: 'Петров',
        firstName: 'Алексей',
        createdAt: DateTime.now(),
      );
      expect(user.shortName, 'Петров А.');
    });
  });

  group('User.fullName', () {
    test('returns username when no name parts', () {
      final user = User(id: 1, username: 'login1', role: 'user', createdAt: DateTime.now());
      expect(user.fullName, 'login1');
    });

    test('joins all parts', () {
      final user = User(
        id: 1,
        username: 'u',
        role: 'user',
        lastName: 'Иванов',
        firstName: 'Иван',
        patronymic: 'Иванович',
        createdAt: DateTime.now(),
      );
      expect(user.fullName, 'Иванов Иван Иванович');
    });

    test('skips empty parts', () {
      final user = User(
        id: 1,
        username: 'u',
        role: 'user',
        lastName: 'Иванов',
        firstName: '',
        patronymic: '   ',
        createdAt: DateTime.now(),
      );
      expect(user.fullName, 'Иванов');
    });
  });

  group('User.copyWith', () {
    test('updates only specified fields', () {
      final user = User(id: 1, username: 'old', role: 'user', createdAt: DateTime.now());

      final updated = user.copyWith(username: 'new', role: 'admin');

      expect(updated.id, 1);
      expect(updated.username, 'new');
      expect(updated.role, 'admin');
    });
  });

  group('AuthResponse.fromJson', () {
    test('parses full json', () {
      final auth = AuthResponse.fromJson({
        'userId': 1,
        'username': 'user',
        'role': 'admin',
        'token': 'jwt-token',
        'expiresAt': '2026-01-01T00:00:00Z',
      });

      expect(auth.userId, 1);
      expect(auth.username, 'user');
      expect(auth.role, 'admin');
      expect(auth.token, 'jwt-token');
      expect(auth.isAdmin, isTrue);
    });

    test('uses defaults when fields missing', () {
      final auth = AuthResponse.fromJson({});
      expect(auth.userId, 0);
      expect(auth.username, '');
      expect(auth.role, 'guest');
      expect(auth.token, '');
    });

    test('toUserModel preserves data', () {
      final auth = AuthResponse(
        userId: 1,
        username: 'user',
        role: 'user',
        token: 'token-1',
        expiresAt: DateTime.utc(2026, 1, 1),
      );

      final model = auth.toUserModel();

      expect(model.id, 1);
      expect(model.username, 'user');
      expect(model.role, 'user');
      expect(model.token, 'token-1');
    });

    test('toUserModel uses token override', () {
      final auth = AuthResponse(
        userId: 1,
        username: 'user',
        role: 'user',
        token: 'old',
        expiresAt: DateTime.utc(2026, 1, 1),
      );

      final model = auth.toUserModel('new-token');

      expect(model.token, 'new-token');
    });
  });

  group('UserModel', () {
    test('isAdmin checks role', () {
      final m = UserModel(id: 1, username: 'u', role: 'admin', token: 't');
      expect(m.isAdmin, isTrue);
    });

    test('isGuest checks role', () {
      final m = UserModel(id: 1, username: 'u', role: 'guest', token: 't');
      expect(m.isGuest, isTrue);
    });
  });

  group('CreateUserRequest.toJson', () {
    test('omits empty optional fields', () {
      final r = CreateUserRequest(username: 'u', password: 'p', roleId: 1);
      final json = r.toJson();
      expect(json['username'], 'u');
      expect(json['password'], 'p');
      expect(json['roleId'], 1);
      expect(json.containsKey('lastName'), isFalse);
    });

    test('includes optional fields when set', () {
      final r = CreateUserRequest(
        username: 'u',
        password: 'p',
        roleId: 1,
        lastName: 'Иванов',
      );
      expect(r.toJson()['lastName'], 'Иванов');
    });
  });

  group('UpdateUserRequest.toJson', () {
    test('returns empty map when nothing set', () {
      expect(UpdateUserRequest().toJson(), <String, dynamic>{});
    });

    test('includes only set fields', () {
      final r = UpdateUserRequest(username: 'new', roleId: 2);
      final json = r.toJson();
      expect(json, {'username': 'new', 'roleId': 2});
    });
  });
}
