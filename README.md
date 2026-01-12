# MCHS Mobile App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9.2-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License">
</p>

Мобильное приложение для системы обучения и тестирования сотрудников МЧС России. Приложение предоставляет удобный интерфейс для прохождения тестов, изучения учебных материалов и отслеживания прогресса обучения.

---

## Скриншоты

<!-- Добавьте скриншоты вашего приложения -->
<!-- <p align="center">
  <img src="screenshots/home.png" width="200">
  <img src="screenshots/tests.png" width="200">
  <img src="screenshots/lectures.png" width="200">
</p> -->

---

## Возможности

### Для пользователей
- **Авторизация** — безопасный вход в систему с сохранением сессии
- **Лекции** — просмотр учебных материалов, PDF-документов и видео
- **Тестирование** — прохождение тестов по различным темам
- **История результатов** — отслеживание прогресса и результатов тестирования
- **Профиль** — управление личными данными
- **Тёмная тема** — поддержка светлой и тёмной темы оформления

### Для администраторов
- **Управление пользователями** — добавление, редактирование, блокировка
- **Управление лекциями** — создание и редактирование учебных материалов
- **Управление тестами** — создание тестов, импорт вопросов
- **Отчёты** — просмотр статистики и аналитики

---

## Архитектура

Проект построен на основе **Clean Architecture** с использованием feature-first подхода:

```
lib/
├── main.dart                 # Точка входа
├── core/                     # Общие компоненты
│   ├── config/               # Конфигурация приложения
│   ├── constants/            # Константы
│   ├── errors/               # Обработка ошибок
│   ├── models/               # Общие модели
│   ├── network/              # Сетевой слой (Dio)
│   ├── providers/            # Глобальные провайдеры
│   ├── router/               # Навигация (GoRouter)
│   ├── theme/                # Темы оформления
│   ├── utils/                # Утилиты
│   └── widgets/              # Переиспользуемые виджеты
└── features/                 # Функциональные модули
    ├── admin/                # Админ-панель
    ├── auth/                 # Авторизация
    ├── home/                 # Главный экран
    ├── lectures/             # Лекции
    ├── profile/              # Профиль пользователя
    ├── shell/                # Основная оболочка (навигация)
    └── testing/              # Тестирование
```

---

## Технологии

| Категория | Технология |
|-----------|------------|
| **Фреймворк** | Flutter 3.9.2 |
| **Язык** | Dart |
| **State Management** | Riverpod |
| **Навигация** | GoRouter |
| **Сеть** | Dio |
| **Локальное хранилище** | SharedPreferences, Flutter Secure Storage |
| **PDF** | Syncfusion PDF Viewer |
| **Видео** | Chewie + Video Player |
| **Генерация кода** | Freezed, JSON Serializable |

---

## Установка и запуск

### Требования
- Flutter SDK 3.9.2+
- Dart SDK 3.x
- Android Studio / VS Code
- Эмулятор или физическое устройство

### Шаги установки

1. **Клонируйте репозиторий**
   ```bash
   git clone https://github.com/bru1f0rc3/MCHSTestMobileAPP.git
   cd mchs_mobile_app
   ```

2. **Установите зависимости**
   ```bash
   flutter pub get
   ```

3. **Сгенерируйте код (Freezed, JSON)**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Запустите приложение**
   ```bash
   flutter run
   ```

### Сборка релиза

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## Конфигурация

Настройки API и окружения находятся в `lib/core/config/`. Перед запуском убедитесь, что указан корректный адрес сервера.

---

## Основные модули

### Авторизация (`features/auth/`)
Модуль отвечает за вход в систему, регистрацию и управление токенами доступа.

### Лекции (`features/lectures/`)
Просмотр учебных материалов в различных форматах: текст, PDF, видео.

### Тестирование (`features/testing/`)
- Список доступных тестов
- Прохождение тестов с таймером
- Просмотр результатов
- История попыток

### Админ-панель (`features/admin/`)
Полный функционал для управления системой:
- Dashboard со статистикой
- CRUD операции для пользователей, лекций и тестов
- Импорт тестов из файлов
- Генерация отчётов

---

## Темы оформления

Приложение поддерживает светлую и тёмную тему. Переключение доступно в настройках профиля. Тема автоматически синхронизируется с системными настройками устройства.

---

## Лицензия

Этот проект распространяется под лицензией MIT. Подробности см. в файле [LICENSE](LICENSE).

---

## Автор

**bru1f0rc3**

- GitHub: [@bru1f0rc3](https://github.com/bru1f0rc3)

---

## Ссылка на BackendAPI

[C# BackendAPI](https://github.com/bru1f0rc3/MCHSTestSystemAPI.git)
