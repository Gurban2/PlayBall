# PlayBall - Volleyball Game Management App 🏐

Приложение для организации и управления волейбольными играми.

## 🚀 Возможности

- 📅 **Планирование игр** - создание и управление волейбольными играми
- 👥 **Управление командами** - формирование команд и назначение игроков
- 🔍 **Поиск игр** - поиск по локации, времени и уровню игры
- 👫 **Система друзей** - добавление друзей и просмотр их игр
- 📊 **Статистика** - отслеживание результатов и рейтингов
- 🔔 **Уведомления** - получение уведомлений о играх

## 🛠 Технический стек

- **Flutter** - UI фреймворк
- **Firebase** - Backend (Firestore, Authentication)
- **Riverpod** - State management
- **Go Router** - Навигация

## 📋 Установка и настройка

### 1. Клонирование проекта
```bash
git clone https://github.com/your-username/PlayBall.git
cd PlayBall
```

### 2. Установка зависимостей
```bash
flutter pub get
```

### 3. 🔥 Настройка Firebase

**Firebase конфигурационные файлы ВКЛЮЧЕНЫ** в Git для личного использования

#### 3.1. Если клонируете впервые
Конфигурация уже настроена! Просто выполните:
```bash
flutter pub get
flutter run -d chrome
```

#### 3.2. Если нужно создать новый Firebase проект
1. Перейдите в [Firebase Console](https://console.firebase.google.com/)
2. Создайте новый проект или используйте существующий
3. Включите следующие сервисы:
   - **Firestore Database**
   - **Authentication** (Email/Password)

#### 3.3. Обновление конфигурации (при необходимости)
```bash
# Установите Firebase CLI (если еще не установлен)
npm install -g firebase-tools

# Войдите в Firebase
firebase login

# Установите FlutterFire CLI
dart pub global activate flutterfire_cli

# Обновите конфигурацию
flutterfire configure
```

### 4. 🗄 Настройка Firestore

#### 4.1. Создайте коллекции в Firestore:
- `users` - пользователи
- `rooms` - игровые комнаты  
- `teams` - команды

#### 4.2. Настройте правила безопасности Firestore:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Пользователи могут читать и писать только свои данные
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Комнаты доступны всем авторизованным пользователям для чтения
    match /rooms/{roomId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource == null || resource.data.organizerId == request.auth.uid);
    }
    
    // Команды доступны всем авторизованным пользователям
    match /teams/{teamId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. 🏃‍♂️ Запуск приложения

```bash
# Для Web
flutter run -d chrome

# Для Android (с подключенным устройством)
flutter run -d android

# Для iOS (только на macOS)
flutter run -d ios
```

## 🔐 Безопасность

- **Firebase конфигурационные файлы ВКЛЮЧЕНЫ** в Git для личного использования
- ⚠️ **ВНИМАНИЕ:** Если планируете поделиться кодом - удалите конфигурационные файлы
- При публичном использовании раскомментируйте строки в `.gitignore`:
  ```
  android/app/google-services.json
  ios/Runner/GoogleService-Info.plist
  lib/firebase_options.dart
  ```

## 📁 Структура проекта

```
lib/
├── models/          # Модели данных
├── screens/         # Экраны приложения
├── services/        # Сервисы (Firebase, Auth)
├── providers/       # Riverpod провайдеры
├── utils/           # Утилиты и константы
└── main.dart        # Точка входа

android/app/
├── google-services.json  # (не в Git)
└── AndroidManifest.xml

ios/Runner/
└── GoogleService-Info.plist  # (не в Git)
```

## 🎯 Первые шаги после настройки

1. Зарегистрируйтесь в приложении
2. Создайте первую игру (нужна роль организатора)
3. Пригласите друзей присоединиться

## 🐛 Устранение неполадок

### Ошибки Firebase
- Убедитесь, что все конфигурационные файлы на месте
- Проверьте, что сервисы включены в Firebase Console
- Убедитесь, что package names совпадают

### Ошибки компиляции
```bash
flutter clean
flutter pub get
```

## 🤝 Вклад в проект

1. Fork проекта
2. Создайте feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit изменения (`git commit -m 'Add some AmazingFeature'`)
4. Push в branch (`git push origin feature/AmazingFeature`)
5. Создайте Pull Request

## 📄 Лицензия

Этот проект лицензирован под MIT License.

## 📞 Контакты

Если у вас есть вопросы, создайте Issue в репозитории.

---

**⚠️ Важно:** Firebase конфигурационные файлы включены для личного использования. При публичном использовании обязательно исключите их из Git! 