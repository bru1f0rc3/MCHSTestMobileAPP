class Validators {
  Validators._();
  static final RegExp _emailRegex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email обязателен';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Введите корректный email';
    }
    return null;
  }

  static String? required(String? value, [String fieldName = 'Поле']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName обязательно для заполнения';
    }
    return null;
  }

  static String? minLength(
    String? value,
    int minLength, [
    String fieldName = 'Поле',
  ]) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName обязательно для заполнения';
    }
    if (value.trim().length < minLength) {
      return '$fieldName должно содержать минимум $minLength символов';
    }
    return null;
  }

  static String? maxLength(
    String? value,
    int maxLength, [
    String fieldName = 'Поле',
  ]) {
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName не должно превышать $maxLength символов';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пароль обязателен';
    }
    if (value.length < 6) {
      return 'Пароль должен содержать минимум 6 символов';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Подтверждение пароля обязательно';
    }
    if (value != originalPassword) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Имя пользователя обязательно';
    }
    if (value.trim().length < 3) {
      return 'Имя пользователя должно содержать минимум 3 символа';
    }
    if (value.trim().length > 50) {
      return 'Имя пользователя не должно превышать 50 символов';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_а-яА-ЯёЁ]+$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return 'Имя пользователя может содержать только буквы, цифры и _';
    }
    return null;
  }

  static String? title(String? value, [String fieldName = 'Название']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName обязательно';
    }
    if (value.trim().length < 3) {
      return '$fieldName должно содержать минимум 3 символа';
    }
    if (value.trim().length > 200) {
      return '$fieldName не должно превышать 200 символов';
    }
    return null;
  }

  static String? description(String? value, {int maxLength = 1000}) {
    if (value != null && value.trim().length > maxLength) {
      return 'Описание не должно превышать $maxLength символов';
    }
    return null;
  }

  static String? questionText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Текст вопроса обязателен';
    }
    if (value.trim().length < 5) {
      return 'Вопрос должен содержать минимум 5 символов';
    }
    if (value.trim().length > 1000) {
      return 'Вопрос не должен превышать 1000 символов';
    }
    return null;
  }

  static String? answerText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Текст ответа обязателен';
    }
    if (value.trim().length > 500) {
      return 'Ответ не должен превышать 500 символов';
    }
    return null;
  }

  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
