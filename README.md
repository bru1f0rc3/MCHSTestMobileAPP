# MCHS Mobile App

Мобильное приложение для системы обучения и тестирования сотрудников МЧС России.

---

## Возможности

**Для пользователей:**
- Авторизация (вход, регистрация, гостевой доступ, восстановление пароля)
- Просмотр лекций — текст, PDF, видео
- Прохождение тестов с таймером и просмотр результатов
- История попыток и личная статистика
- Профиль с настройками безопасности
- Светлая и тёмная тема

**Для администраторов:**
- Управление пользователями, лекциями и тестами
- Импорт тестов из PDF
- Отчёты и аналитика

---

## Технологии

| Категория | Технология |
|---|---|
| UI | Flutter 3.9.2, Material Design 3 |
| Состояние | Riverpod 2 + riverpod_generator |
| Навигация | GoRouter 13 |
| HTTP | Dio 5 |
| Хранилище | SharedPreferences, Flutter Secure Storage |
| Модели | Freezed + json_serializable |
| PDF | flutter_pdfview, Syncfusion PDF Viewer |
| Видео | video_player + Chewie |

---

## Структура проекта

```
lib/
├── main.dart
├── screens/       # Все экраны приложения
├── models/        # Модели данных (User, Test, Lecture и т.д.)
├── services/      # API-сервисы (Dio)
├── providers/     # Провайдеры состояния (Riverpod)
├── widgets/       # Переиспользуемые виджеты
├── theme/         # Светлая и тёмная тема
├── utils/         # Утилиты (валидаторы, логгер, кеш и т.д.)
└── config/        # Конфигурация (API URL, роутер, Dio, константы)
```

---

## Установка и запуск

**Требования:** Flutter SDK 3.9.2+, Dart 3.x

```bash
# 1. Клонировать репозиторий
git clone https://github.com/bru1f0rc3/MCHSTestMobileAPP.git
cd MCHSTestMobileAPP-master

# 2. Установить зависимости
flutter pub get

# 3. Сгенерировать код (Freezed, Riverpod, JSON)
dart run build_runner build --delete-conflicting-outputs

# 4. Запустить
flutter run
```

---

## Конфигурация

Базовый URL API задаётся в `lib/config/app_config.dart`:

```dart
static const String baseUrl = 'http://91.184.241.59:5000/api';
```

---

## Backend API

[C# Backend — MCHSTestSystemAPI](https://github.com/bru1f0rc3/MCHSTestSystemAPI.git)
