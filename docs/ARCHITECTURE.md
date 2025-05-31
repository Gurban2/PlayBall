# Архитектура проекта PlayBall

## 📋 Обзор

PlayBall - это Flutter приложение для организации волейбольных игр, использующее Firebase в качестве бэкенда и Riverpod для управления состоянием.

## 🏗️ Структура проекта

```
lib/
├── main.dart                 # Точка входа в приложение
├── models/                   # Модели данных
│   ├── user_model.dart
│   ├── room_model.dart
│   └── ...
├── services/                 # Бизнес-логика и работа с данными
│   ├── user_service.dart     # Работа с пользователями
│   ├── room_service.dart     # Работа с комнатами
│   ├── auth_service.dart     # Аутентификация
│   └── storage_service.dart  # Работа с файлами
├── screens/                  # UI экраны
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   └── ...
├── widgets/                  # Переиспользуемые виджеты
│   ├── room_card.dart        # Карточка комнаты
│   ├── player_card.dart      # Карточка игрока
│   └── ...
├── providers/               # Riverpod провайдеры
├── utils/                   # Утилиты и вспомогательные классы
│   ├── permissions_manager.dart  # Управление правами
│   ├── error_handler.dart        # Обработка ошибок
│   ├── date_formatter.dart       # Форматирование дат
│   ├── route_names.dart          # Маршруты
│   └── constants.dart
└── firebase_options.dart    # Конфигурация Firebase
```

## 🔧 Архитектурные решения

### 1. Разделение сервисов

**Проблема**: Монолитный `firestore_service.dart` (2300+ строк)

**Решение**: Разбили на специализированные сервисы:
- `UserService` - управление пользователями
- `RoomService` - управление комнатами и играми
- `AuthService` - аутентификация
- `StorageService` - работа с файлами

**Преимущества**:
- Легче тестировать
- Лучше разделение ответственности
- Упрощается поддержка кода

### 2. Централизованное управление правами

**Реализация**: `PermissionsManager`

Функции:
- Проверка прав доступа (`hasPermission`)
- Валидация действий (`canJoinRoom`, `canLeaveRoom`)
- Получение доступных действий (`getAvailableRoomActions`)

```dart
// Пример использования
final canEdit = PermissionsManager.hasPermission(
  user, 
  Permission.editRoom, 
  room: room
);
```

### 3. Переиспользуемые UI компоненты

**Компоненты**:
- `RoomCard` - карточка комнаты с действиями
- `PlayerCard` - карточка игрока
- `TeamMemberCard` - карточка участника команды
- `ConfirmationDialog` - диалог подтверждения

**Преимущества**:
- Консистентный UI
- Легче поддерживать
- Переиспользование кода

### 4. Централизованная обработка ошибок

**Реализация**: `ErrorHandler`

Типы ошибок:
- `ErrorType.authentication` - ошибки входа
- `ErrorType.firestore` - ошибки базы данных
- `ErrorType.validation` - ошибки валидации
- `ErrorType.network` - сетевые ошибки

```dart
// Пример использования
try {
  await roomService.createRoom(room);
} catch (e) {
  final appError = ErrorHandler.handleError(e);
  ErrorHandler.showErrorSnackBar(context, appError);
}
```

### 5. Форматирование дат

**Реализация**: `DateFormatter`

Методы:
- `formatDisplayDate()` - "Сегодня, 14:30"
- `formatRelativeTime()` - "2 часа назад"
- `formatDuration()` - "1ч 30мин"

## 🚀 Улучшения производительности

### 1. Пагинация

Все списки используют пагинацию:
```dart
Future<List<RoomModel>> getActiveRooms({
  int limit = 20,
  DocumentSnapshot? lastDocument,
})
```

### 2. Реактивные обновления

Использование Stream для реального времени:
```dart
Stream<List<RoomModel>> watchActiveRooms() {
  return _firestore
      .collection('rooms')
      .where('status', isEqualTo: 'planned')
      .snapshots()
      .map((snapshot) => ...);
}
```

### 3. Кэширование

- Провайдеры Riverpod кэшируют данные
- Локальное кэширование в SharedPreferences (планируется)

## 🔒 Безопасность

### 1. Проверка прав

Все действия проверяются через `PermissionsManager`:
```dart
if (PermissionsManager.hasPermission(user, Permission.deleteRoom, room: room)) {
  // Разрешить удаление
}
```

### 2. Валидация данных

Централизованная валидация в `ErrorHandler`:
- Email
- Пароли
- Названия комнат
- Количество участников

## 📱 Навигация

### Централизованные маршруты

**Файлы**:
- `route_names.dart` - названия и пути
- `app_router.dart` - конфигурация GoRouter

**Утилиты**:
```dart
// Типобезопасная навигация
context.go(RouteUtils.roomPath(roomId));
context.go(RouteUtils.playerProfilePath(playerId, playerName: name));
```

## 🧪 Тестирование

### Структура тестов

```
test/
├── unit/                # Unit тесты моделей и сервисов
├── widget/              # Widget тесты экранов
├── integration/         # Интеграционные тесты
└── mocks/              # Моки для тестирования
```

### Покрытие

- **Unit тесты**: 27 тестов (100% успешно)
- **Widget тесты**: ProfileScreen, TeamMembersScreen
- **Integration тесты**: Базовая навигация

## 📊 Мониторинг и аналитика

### Логирование ошибок

```dart
// Автоматическое логирование в ErrorHandler
static AppError handleError(dynamic error) {
  // Логирование в Firebase Crashlytics (планируется)
  return appError;
}
```

### Аналитика маршрутов

```dart
String routeName = RouteUtils.getRouteNameForAnalytics(path);
// Отправка в Firebase Analytics (планируется)
```

## 🔮 Планы развития

### Краткосрочные (1-2 недели)

1. **Рефакторинг экранов**
   - Разбить крупные экраны на компоненты
   - Вынести бизнес-логику в провайдеры

2. **Улучшение UI**
   - Добавить индикаторы загрузки
   - Улучшить обработку состояний
   - Responsive дизайн

3. **Тестирование**
   - Увеличить покрытие unit тестов
   - Добавить моки для Firebase

### Среднесрочные (1-2 месяца)

1. **Производительность**
   - Внедрить кэширование
   - Оптимизировать запросы к Firestore
   - Ленивая загрузка данных

2. **Функциональность**
   - Push уведомления
   - Чат в комнатах
   - Рейтинговая система

3. **Качество кода**
   - CI/CD pipeline
   - Автоматические тесты
   - Code review процесс

### Долгосрочные (3-6 месяцев)

1. **Масштабирование**
   - Микросервисная архитектура
   - Кэширование Redis
   - CDN для медиа

2. **Новые платформы**
   - Web версия
   - Desktop приложение
   - API для третьих лиц

## 📝 Соглашения

### Именование

- **Файлы**: `snake_case.dart`
- **Классы**: `PascalCase`
- **Переменные**: `camelCase`
- **Константы**: `UPPER_SNAKE_CASE`

### Структура файлов

```dart
// 1. Импорты Flutter
import 'package:flutter/material.dart';

// 2. Импорты сторонних пакетов
import 'package:riverpod/riverpod.dart';

// 3. Локальные импорты
import '../models/user_model.dart';
import '../services/user_service.dart';
```

### Комментарии

- Публичные методы должны иметь документацию
- Сложная логика должна быть прокомментирована
- TODO комментарии с указанием автора и даты

## 🚨 Известные проблемы

1. **Firestore Rules** - нужно настроить более детальные правила безопасности
2. **Offline поддержка** - нет кэширования для работы без интернета  
3. **Изображения** - нет оптимизации и ресайза изображений
4. **Локализация** - пока только русский язык

## 🤝 Вклад в проект

1. Следовать архитектурным принципам
2. Писать тесты для нового кода
3. Обновлять документацию
4. Использовать централизованные утилиты

---

*Последнее обновление: Декабрь 2024* 