# PlayBall

Приложение для создания и организации спортивных игр. Разработано с использованием Flutter и Firebase.

## Особенности приложения

* Создание и управление спортивными играми
* Регистрация и аутентификация пользователей
* Редактирование профиля пользователя
* Различные роли пользователей (администратор, организатор, обычный пользователь)
* Формирование команд и отслеживание статистики игр
* Система уведомлений
* Рейтинг игроков

## Настройка проекта

### Предварительные требования

1. Установите Flutter SDK (https://flutter.dev/docs/get-started/install)
   - Добавьте Flutter в переменную PATH вашей системы:
     ```bash
     # Для Windows добавьте в переменную PATH:
     C:\path\to\flutter\bin
     
     # Для Linux/Mac:
     export PATH="$PATH:/path/to/flutter/bin"
     ```
   - Убедитесь, что Flutter установлен корректно:
     ```bash
     flutter doctor
     ```

2. Установите Firebase CLI и FlutterFire CLI
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

3. Авторизуйтесь в Firebase
```bash
firebase login
```

### Настройка Firebase

1. Создайте новый проект в [Firebase Console](https://console.firebase.google.com/)
2. Добавьте приложения для Android и iOS (и Web, если планируете использовать)
3. Настройте аутентификацию, включив Email/Password
4. Создайте базу данных Firestore
5. Установите правила безопасности для Firestore
6. Настройте Firebase Storage для хранения изображений

### Настройка Flutter проекта

1. Клонируйте репозиторий:
```bash
git clone https://github.com/yourusername/volleyball_app.git
cd volleyball_app
```

2. Установите зависимости:
```bash
flutter pub get
```

3. Настройте Firebase для Flutter:
```bash
flutterfire configure
```

4. Запустите приложение:
```bash
flutter run
```

## Структура проекта

```
volleyball_app/
├── lib/                    # Исходный код Dart
│   ├── controllers/        # Контроллеры бизнес-логики
│   ├── models/             # Модели данных
│   ├── screens/            # Экраны приложения
│   ├── services/           # Сервисы для работы с Firebase и др.
│   ├── utils/              # Утилиты и константы
│   ├── widgets/            # Многоразовые виджеты
│   ├── firebase_options.dart # Настройки Firebase
│   └── main.dart           # Точка входа в приложение
├── assets/                 # Статические ресурсы
│   ├── fonts/              # Шрифты
│   └── images/             # Изображения
├── android/                # Код для Android
├── ios/                    # Код для iOS
└── pubspec.yaml            # Зависимости и настройки Flutter
```

## Роли пользователей

В приложении доступны следующие роли:

* **user** - обычный пользователь
* **organizer** - может создавать и организовывать игры
* **admin** - имеет полный доступ ко всем функциям

## Технический стек

* **Flutter** - фреймворк для разработки кроссплатформенных приложений
* **Firebase Authentication** - аутентификация пользователей
* **Cloud Firestore** - хранение данных
* **Firebase Storage** - хранение изображений
* **Flutter Riverpod** - управление состоянием
* **Go Router** - навигация
* **Intl** - локализация
* **Flutter Local Notifications** - локальные уведомления

## Схема базы данных (Firestore)

### Коллекция "users"
- id: String
- email: String
- name: String
- photoUrl: String (опционально)
- role: String (user, organizer, admin)
- rating: number
- teams: Array<String>
- gamesPlayed: number
- wins: number
- losses: number
- createdAt: Timestamp
- lastLogin: Timestamp

### Коллекция "rooms"
- id: String
- title: String
- description: String
- location: String
- startTime: Timestamp
- endTime: Timestamp
- organizerId: String
- participants: Array<String>
- maxParticipants: number
- status: String (planned, active, completed, cancelled)
- pricePerPerson: number
- teams: Array<String>
- winnerTeamId: String (опционально)
- gameStats: Map (опционально)
- createdAt: Timestamp
- updatedAt: Timestamp

### Коллекция "teams"
- id: String
- name: String
- members: Array<String>
- roomId: String
- createdAt: Timestamp

### Коллекция "notifications"
- id: String
- userId: String
- title: String
- body: String
- type: String
- relatedId: String
- isRead: boolean
- createdAt: Timestamp 