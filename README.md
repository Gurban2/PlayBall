# PlayBall

Приложение для создания и организации волейбольных игр. Разработано с использованием Flutter и Firebase.

## Особенности приложения

* Создание и управление спортивными играми
* Регистрация и аутентификация пользователей
* Редактирование профиля пользователя
* Различные роли пользователей (администратор, организатор, обычный пользователь)
* Формирование команд и отслеживание статистики игр
* Real-time обновления через Firestore
* Рейтинг игроков

## Быстрый запуск

### Способ 1: Через скрипт (Windows)
```bash
run_app.bat
```

### Способ 2: Через командную строку
```bash
flutter pub get
flutter run -d chrome
```

## Настройка проекта

### Предварительные требования

1. **Flutter SDK** (https://flutter.dev/docs/get-started/install)
2. **Firebase CLI** (для развертывания правил)
```bash
npm install -g firebase-tools
```

### Настройка Firebase

1. Создайте проект в [Firebase Console](https://console.firebase.google.com/)
2. Включите Authentication (Email/Password)
3. Создайте базу данных Firestore
4. Разверните правила безопасности:
```bash
deploy_firestore_rules.bat
```

## Структура проекта

```
lib/
├── models/             # Модели данных (User, Room, Team)
├── screens/            # Экраны приложения
├── services/           # Сервисы (Auth, Firestore)
├── providers/          # Провайдеры состояния (Riverpod)
├── utils/              # Утилиты и константы
└── main.dart           # Точка входа
```

## Роли пользователей

* **user** - обычный пользователь (может участвовать в играх)
* **organizer** - может создавать и организовывать игры (лимит 3 активные игры)
* **admin** - имеет полный доступ ко всем функциям

### Изменение роли (для тестирования)
1. Войдите в приложение
2. Перейдите в профиль
3. Нажмите "Стать организатором"
4. Вернитесь на главный экран - появится кнопка создания игры ➕

## Технический стек

* **Flutter** - кроссплатформенный фреймворк
* **Firebase Authentication** - аутентификация пользователей
* **Cloud Firestore** - база данных в реальном времени
* **Flutter Riverpod** - управление состоянием
* **Go Router** - навигация
* **Material Design 3** - современный UI

## Схема базы данных (Firestore)

### Коллекция "users"
```json
{
  "id": "string",
  "email": "string",
  "name": "string",
  "role": "user|organizer|admin",
  "rating": "number",
  "gamesPlayed": "number",
  "wins": "number",
  "losses": "number",
  "createdAt": "timestamp"
}
```

### Коллекция "rooms"
```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "location": "string",
  "startTime": "timestamp",
  "endTime": "timestamp",
  "organizerId": "string",
  "participants": "array",
  "maxParticipants": "number",
  "status": "planned|active|completed|cancelled",
  "pricePerPerson": "number",
  "numberOfTeams": "number",
  "createdAt": "timestamp"
}
```

## Диагностика

Если возникают проблемы:
1. Нажмите иконку жука 🐛 на главном экране
2. Проверьте консоль браузера (F12)
3. Убедитесь, что Firebase правильно настроен

## Разработка

Для разработки используйте:
```bash
flutter run -d chrome --hot
```

Hot reload: `r`
Hot restart: `R`
Quit: `q` 