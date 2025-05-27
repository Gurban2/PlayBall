# Настройка Firebase для Volleyball App

## 📋 Текущее состояние

✅ **Уже настроено:**
- Firebase зависимости добавлены в `pubspec.yaml`
- Конфигурационные файлы созданы
- Android настройки выполнены
- Сервисы Auth и Firestore готовы
- Тестовый экран для проверки подключения

## 🚀 Быстрый старт

### 1. Установка Flutter (если не установлен)

1. Скачайте Flutter SDK с https://flutter.dev/docs/get-started/install/windows
2. Распакуйте в `C:\flutter`
3. Добавьте `C:\flutter\bin` в PATH
4. Перезапустите терминал
5. Проверьте: `flutter --version`

### 2. Установка зависимостей

```bash
flutter pub get
```

### 3. Запуск приложения

```bash
# Для Android
flutter run

# Для Web
flutter run -d chrome

# Для Windows
flutter run -d windows
```

## 🔧 Детальная настройка Firebase

### Шаг 1: Создание проекта Firebase

1. Перейдите в [Firebase Console](https://console.firebase.google.com/)
2. Нажмите "Создать проект"
3. Введите название проекта (например, "volleyball-app")
4. Включите Google Analytics (опционально)
5. Создайте проект

### Шаг 2: Настройка Authentication

1. В Firebase Console перейдите в **Authentication**
2. Нажмите "Начать"
3. Перейдите на вкладку **Sign-in method**
4. Включите нужные методы входа:
   - Email/Password ✅
   - Google (опционально)
   - Facebook (опционально)

### Шаг 3: Настройка Firestore Database

1. В Firebase Console перейдите в **Firestore Database**
2. Нажмите "Создать базу данных"
3. Выберите режим:
   - **Тестовый режим** (для разработки)
   - **Производственный режим** (для продакшена)
4. Выберите регион (например, europe-west1)

### Шаг 4: Настройка Storage

1. В Firebase Console перейдите в **Storage**
2. Нажмите "Начать"
3. Настройте правила безопасности

### Шаг 5: Добавление приложений

#### Android App

1. В Firebase Console нажмите "Добавить приложение" → Android
2. Введите package name: `com.example.volleyball_app`
3. Скачайте `google-services.json`
4. Поместите файл в `android/app/`

#### iOS App (если нужно)

1. В Firebase Console нажмите "Добавить приложение" → iOS
2. Введите Bundle ID: `com.example.volleyballApp`
3. Скачайте `GoogleService-Info.plist`
4. Поместите файл в `ios/Runner/`

#### Web App

1. В Firebase Console нажмите "Добавить приложение" → Web
2. Введите название приложения
3. Скопируйте конфигурацию в `lib/firebase_options.dart`

## 📱 Структура проекта

```
lib/
├── main.dart                 # Точка входа с инициализацией Firebase
├── firebase_options.dart     # Конфигурация Firebase для всех платформ
├── services/
│   ├── auth_service.dart     # Сервис аутентификации
│   └── firestore_service.dart # Сервис работы с Firestore
├── models/
│   ├── user_model.dart       # Модель пользователя
│   └── room_model.dart       # Модель игровой комнаты
├── screens/
│   └── firebase_test_screen.dart # Экран тестирования Firebase
└── utils/
    └── firebase_test.dart    # Утилиты для тестирования
```

## 🧪 Тестирование Firebase

После запуска приложения:

1. Нажмите кнопку **"Тестировать Firebase"** на главном экране
2. Используйте кнопки для тестирования различных функций:
   - **Тест подключения** - проверяет инициализацию Firebase
   - **Тест Auth** - проверяет сервис аутентификации
   - **Тест Firestore** - проверяет работу с базой данных

## 🔒 Правила безопасности

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Пользователи могут читать и изменять только свои данные
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Комнаты доступны для чтения всем авторизованным пользователям
    match /rooms/{roomId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.organizerId || 
         request.auth.uid in resource.data.participants);
      allow delete: if request.auth != null && 
        request.auth.uid == resource.data.organizerId;
    }
  }
}
```

### Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /user_avatars/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /room_images/{roomId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 🚨 Устранение неполадок

### Ошибка "Flutter command not found"
- Убедитесь, что Flutter добавлен в PATH
- Перезапустите терминал
- Проверьте установку: `flutter doctor`

### Ошибка подключения к Firebase
- Проверьте интернет-соединение
- Убедитесь, что `google-services.json` находится в правильной папке
- Проверьте правильность конфигурации в `firebase_options.dart`

### Ошибки сборки Android
- Убедитесь, что Google Services плагин добавлен в `build.gradle`
- Проверьте версии зависимостей
- Очистите проект: `flutter clean && flutter pub get`

### Ошибки Firestore
- Проверьте правила безопасности в Firebase Console
- Убедитесь, что пользователь авторизован
- Проверьте структуру данных

## 📚 Полезные ссылки

- [Flutter Firebase Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire GitHub](https://github.com/firebase/flutterfire)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)

## 🎯 Следующие шаги

1. ✅ Настроить Firebase проект
2. ✅ Добавить зависимости
3. ✅ Создать сервисы
4. 🔄 Протестировать подключение
5. 📱 Создать экраны аутентификации
6. 🏐 Реализовать функции приложения
7. 🚀 Деплой в продакшен

---

**Примечание:** Этот проект уже содержит базовую настройку Firebase. Вам нужно только создать проект в Firebase Console и обновить конфигурационные файлы с вашими данными. 