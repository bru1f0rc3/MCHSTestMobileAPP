import 'package:flutter_test/flutter_test.dart';
import 'package:mchs_mobile_app/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('first.last@mail.ru'), isNull);
    });

    test('returns error for empty value', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('   '), isNotNull);
    });

    test('returns error for invalid format', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('user@'), isNotNull);
      expect(Validators.email('@example.com'), isNotNull);
      expect(Validators.email('user@example'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('returns null for valid password', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('superSecret123'), isNull);
    });

    test('returns error for empty', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
    });

    test('returns error when shorter than 6', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('abc'), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('returns null when passwords match', () {
      expect(Validators.confirmPassword('pass123', 'pass123'), isNull);
    });

    test('returns error when passwords differ', () {
      expect(Validators.confirmPassword('pass123', 'pass321'), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.confirmPassword('', 'pass123'), isNotNull);
      expect(Validators.confirmPassword(null, 'pass123'), isNotNull);
    });
  });

  group('Validators.username', () {
    test('returns null for valid username', () {
      expect(Validators.username('user1'), isNull);
      expect(Validators.username('Иван_Петров'), isNull);
      expect(Validators.username('admin_2024'), isNull);
    });

    test('returns error for empty', () {
      expect(Validators.username(''), isNotNull);
      expect(Validators.username(null), isNotNull);
    });

    test('returns error when shorter than 3', () {
      expect(Validators.username('ab'), isNotNull);
    });

    test('returns error when longer than 50', () {
      expect(Validators.username('a' * 51), isNotNull);
    });

    test('returns error for invalid characters', () {
      expect(Validators.username('user name'), isNotNull);
      expect(Validators.username('user@name'), isNotNull);
      expect(Validators.username('user-name'), isNotNull);
    });
  });

  group('Validators.required', () {
    test('returns null for non-empty value', () {
      expect(Validators.required('hello'), isNull);
    });

    test('returns error for empty', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required(null), isNotNull);
    });
  });

  group('Validators.minLength', () {
    test('returns null when length is enough', () {
      expect(Validators.minLength('hello', 3), isNull);
      expect(Validators.minLength('abc', 3), isNull);
    });

    test('returns error when too short', () {
      expect(Validators.minLength('ab', 3), isNotNull);
    });
  });

  group('Validators.title', () {
    test('returns null for valid title', () {
      expect(Validators.title('Лекция о пожарах'), isNull);
    });

    test('returns error when too short', () {
      expect(Validators.title('ab'), isNotNull);
    });

    test('returns error when too long', () {
      expect(Validators.title('a' * 201), isNotNull);
    });

    test('returns error for empty', () {
      expect(Validators.title(''), isNotNull);
      expect(Validators.title(null), isNotNull);
    });
  });

  group('Validators.questionText', () {
    test('returns null for valid question', () {
      expect(Validators.questionText('Что делать при пожаре?'), isNull);
    });

    test('returns error when too short', () {
      expect(Validators.questionText('что'), isNotNull);
    });
  });

  group('Validators.answerText', () {
    test('returns null for valid answer', () {
      expect(Validators.answerText('Вызвать 112'), isNull);
    });

    test('returns error for empty', () {
      expect(Validators.answerText(''), isNotNull);
      expect(Validators.answerText(null), isNotNull);
    });

    test('returns error when too long', () {
      expect(Validators.answerText('a' * 501), isNotNull);
    });
  });

  group('Validators.combine', () {
    test('returns first error', () {
      final result = Validators.combine([
        () => null,
        () => 'second error',
        () => 'third error',
      ]);
      expect(result, 'second error');
    });

    test('returns null when all pass', () {
      final result = Validators.combine([() => null, () => null]);
      expect(result, isNull);
    });
  });
}
