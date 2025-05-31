# 🔧 Руководство по рефакторингу PlayBall

Это руководство описывает пошаговое применение архитектурных улучшений для проекта PlayBall.

## 📋 Статус улучшений

### ✅ Реализовано

1. **Разделение сервисов**
   - ✅ `UserService` - работа с пользователями
   - ✅ `RoomService` - работа с комнатами
   - ⏸️ Миграция из `firestore_service.dart` (в процессе)

2. **Системы управления**
   - ✅ `PermissionsManager` - централизованные права доступа
   - ✅ `ErrorHandler` - централизованная обработка ошибок
   - ✅ `DateFormatter` - единообразное форматирование дат

3. **UI компоненты**
   - ✅ `RoomCard` - переиспользуемая карточка комнаты
   - ⏸️ Рефакторинг существующих виджетов

4. **Навигация**
   - ✅ `RouteNames` и `RoutePaths` - централизованные маршруты
   - ✅ `RouteUtils` - утилиты для типобезопасной навигации

5. **Документация**
   - ✅ `ARCHITECTURE.md` - архитектурная документация
   - ✅ `REFACTORING_GUIDE.md` - руководство по рефакторингу

### 🚧 В процессе

1. **Миграция с старых сервисов**
2. **Рефакторинг крупных экранов**
3. **Обновление существующих виджетов**

### 📋 Планируется

1. **Загрузочные состояния**
2. **Индикаторы прогресса**
3. **Улучшенная обработка ошибок в UI**
4. **Локализация**

## 🚀 Пошаговая миграция

### Этап 1: Обновление сервисов (1-2 дня)

#### 1.1 Замена вызовов FirestoreService на UserService

**Найти и заменить**:
```dart
// Старый код
FirestoreService().getUserById(userId)

// Новый код  
UserService().getUserById(userId)
```

**Файлы для обновления**:
- `lib/screens/profile_screen.dart`
- `lib/screens/player_profile_screen.dart`
- `lib/providers/user_provider.dart` (если есть)

#### 1.2 Замена вызовов для комнат

```dart
// Старый код
FirestoreService().createRoom(room)
FirestoreService().getRoomById(roomId)

// Новый код
RoomService().createRoom(room)
RoomService().getRoomById(roomId)
```

**Файлы для обновления**:
- `lib/screens/create_room_screen.dart`
- `lib/screens/room_screen.dart`
- `lib/screens/home_screen.dart`

### Этап 2: Внедрение управления правами (1 день)

#### 2.1 Обновление экранов с проверками прав

**В `room_screen.dart`**:
```dart
// Старый код
if (currentUser?.role == UserRole.admin || room.organizerId == currentUser?.id) {
  // показать кнопку редактирования
}

// Новый код
if (PermissionsManager.hasPermission(currentUser!, Permission.editRoom, room: room)) {
  // показать кнопку редактирования
}
```

#### 2.2 Замена проверок присоединения к комнате

```dart
// Старый код
if (!room.isFull && !room.players.contains(userId)) {
  // показать кнопку "Присоединиться"
}

// Новый код
if (PermissionsManager.canJoinRoom(currentUser!, room)) {
  // показать кнопку "Присоединиться"
}
```

### Этап 3: Замена UI компонентов (2-3 дня)

#### 3.1 Замена карточек комнат

**В `home_screen.dart` или `schedule_screen.dart`**:
```dart
// Старый код
Card(
  child: ListTile(
    title: Text(room.title),
    subtitle: Text(room.location),
    // ... много кода
  ),
)

// Новый код  
RoomCard(
  room: room,
  currentUser: currentUser,
  onTap: () => context.go(RouteUtils.roomPath(room.id)),
  onJoin: () => _joinRoom(room.id),
  onLeave: () => _leaveRoom(room.id),
)
```

#### 3.2 Обновление навигации

```dart
// Старый код
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RoomScreen(roomId: roomId),
  ),
);

// Новый код
context.go(RouteUtils.roomPath(roomId));
```

### Этап 4: Обработка ошибок (1 день)

#### 4.1 Замена try-catch блоков

```dart
// Старый код
try {
  await FirestoreService().createRoom(room);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Комната создана')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Ошибка: $e')),
  );
}

// Новый код
try {
  await RoomService().createRoom(room);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Комната создана')),
  );
} catch (e) {
  final appError = ErrorHandler.handleError(e);
  ErrorHandler.showErrorSnackBar(context, appError);
}
```

#### 4.2 Добавление валидации

```dart
// В формах создания комнаты
final titleError = ErrorHandler.validateRoomTitle(titleController.text);
if (titleError != null) {
  ErrorHandler.showErrorSnackBar(context, titleError);
  return;
}
```

### Этап 5: Форматирование дат (0.5 дня)

```dart
// Старый код
Text('${room.startTime.day}.${room.startTime.month}.${room.startTime.year}')

// Новый код
Text(DateFormatter.formatDisplayDate(room.startTime))
```

## 🛠️ Автоматизация миграции

### Скрипт поиска и замены

Создайте файл `migrate.sh`:

```bash
#!/bin/bash

# Замена FirestoreService на специализированные сервисы
find lib -name "*.dart" -exec sed -i 's/FirestoreService().getUserById/UserService().getUserById/g' {} \;
find lib -name "*.dart" -exec sed -i 's/FirestoreService().createRoom/RoomService().createRoom/g' {} \;
find lib -name "*.dart" -exec sed -i 's/FirestoreService().getRoomById/RoomService().getRoomById/g' {} \;

echo "Миграция завершена. Проверьте изменения вручную."
```

### VS Code сниппеты

Добавьте в `.vscode/snippets/dart.json`:

```json
{
  "Permission Check": {
    "prefix": "perm",
    "body": [
      "if (PermissionsManager.hasPermission(${1:user}, Permission.${2:action}, room: ${3:room})) {",
      "  ${4:// Разрешенное действие}",
      "}"
    ],
    "description": "Проверка прав доступа"
  },
  "Error Handler": {
    "prefix": "errorhandle",
    "body": [
      "try {",
      "  ${1:// Код который может вызвать ошибку}",
      "} catch (e) {",
      "  final appError = ErrorHandler.handleError(e);",
      "  ErrorHandler.showErrorSnackBar(context, appError);",
      "}"
    ],
    "description": "Обработка ошибок"
  }
}
```

## 🧪 Тестирование после миграции

### Запуск тестов

```bash
# Unit тесты
flutter test test/unit/

# Widget тесты (могут падать до обновления)
flutter test test/widget/

# Проверка анализа кода
flutter analyze
```

### Чек-лист проверки

- [ ] Все unit тесты проходят
- [ ] Нет ошибок анализа кода
- [ ] Приложение запускается без крашей
- [ ] Основные функции работают:
  - [ ] Вход в систему
  - [ ] Создание комнаты
  - [ ] Присоединение к комнате
  - [ ] Просмотр профиля
  - [ ] Навигация между экранами

## 🔍 Мониторинг после внедрения

### Метрики для отслеживания

1. **Производительность**
   - Время загрузки экранов
   - Размер приложения
   - Использование памяти

2. **Качество кода**
   - Количество строк кода в файлах
   - Сложность методов
   - Покрытие тестами

3. **Пользовательский опыт**
   - Количество ошибок
   - Время отклика UI
   - Удобство навигации

### Инструменты

```bash
# Анализ размера файлов
find lib -name "*.dart" -exec wc -l {} + | sort -nr | head -20

# Проверка зависимостей
flutter deps

# Производительность
flutter build apk --analyze-size
```

## 📚 Дополнительные ресурсы

- [ARCHITECTURE.md](ARCHITECTURE.md) - подробная архитектурная документация
- [Flutter Best Practices](https://flutter.dev/docs/development/ui/layout/best-practices)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

## 🆘 Получение помощи

При возникновении проблем:

1. Проверьте консоль на ошибки
2. Убедитесь что все импорты обновлены
3. Проверьте что новые файлы добавлены в проект
4. Обратитесь к документации архитектуры

---

*Последнее обновление: Декабрь 2024* 