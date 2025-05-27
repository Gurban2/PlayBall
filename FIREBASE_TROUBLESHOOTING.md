# 🔧 Устранение проблем с Firebase

## Проблема: Множественные попытки подключения к Firestore

### Симптомы
- В консоли появляются множественные сообщения `@firebase/firestore:`
- Приложение "зависает" при попытке подключения к Firestore
- Таймауты при выполнении операций с базой данных

### Возможные причины и решения

#### 1. Проблемы с правилами безопасности Firestore

**Проверка:**
1. Откройте [Firebase Console](https://console.firebase.google.com/)
2. Выберите проект `volleyball-a7d8d`
3. Перейдите в Firestore Database → Rules

**Решение:**
```bash
# Разверните правила безопасности
./deploy_firestore_rules.bat
```

Или вручную в Firebase Console установите правила:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Временные правила для разработки
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

#### 2. Устаревшая версия Firebase SDK

**Проблема:** В `web/index.html` используется старая версия Firebase SDK

**Решение:** Обновлено в файле `web/index.html` до версии 10.7.1

#### 3. Проблемы с сетевым подключением

**Проверка:**
```bash
ping firestore.googleapis.com
```

**Решения:**
- Проверьте интернет-соединение
- Отключите VPN если используется
- Проверьте настройки брандмауэра
- Попробуйте другую сеть

#### 4. Проблемы с CORS (Cross-Origin Resource Sharing)

**Решение:** Запускайте приложение с флагом отключения безопасности:
```bash
flutter run -d chrome --web-port=8080 --web-browser-flag="--disable-web-security"
```

#### 5. Кэш браузера

**Решение:**
1. Очистите кэш браузера (Ctrl+Shift+Delete)
2. Откройте инструменты разработчика (F12)
3. Щелкните правой кнопкой на кнопке обновления → "Очистить кэш и жесткая перезагрузка"

## Диагностика проблем

### 1. Запуск полной диагностики

```bash
# Запустите приложение с диагностикой
./run_app_with_diagnostics.bat
```

### 2. Использование встроенной диагностики

1. Откройте приложение в браузере
2. Нажмите "Тестировать Firebase"
3. Выберите "Полная диагностика"
4. Изучите результаты в консоли

### 3. Проверка в браузере

Откройте консоль разработчика (F12) и проверьте:

**Ошибки JavaScript:**
- Ошибки инициализации Firebase
- Проблемы с CORS
- Сетевые ошибки

**Сетевые запросы:**
- Вкладка Network → фильтр XHR
- Ищите запросы к `firestore.googleapis.com`
- Проверьте статус ответов (должен быть 200)

## Частые ошибки и решения

### `PERMISSION_DENIED`
```
Ошибка: [code=permission-denied]: Missing or insufficient permissions
```

**Решение:**
1. Проверьте правила Firestore
2. Убедитесь, что пользователь авторизован (если требуется)
3. Разверните обновленные правила

### `UNAVAILABLE`
```
Ошибка: [code=unavailable]: The service is currently unavailable
```

**Решение:**
1. Проверьте интернет-соединение
2. Проверьте статус Firebase: https://status.firebase.google.com/
3. Попробуйте позже

### `DEADLINE_EXCEEDED` / Timeout
```
Ошибка: Таймаут при записи в Firestore (10 секунд)
```

**Решение:**
1. Проверьте скорость интернета
2. Увеличьте таймауты в коде
3. Проверьте нагрузку на Firebase проект

### Проблемы с инициализацией
```
Ошибка: Firebase app named '[DEFAULT]' already exists
```

**Решение:**
1. Очистите кэш браузера
2. Перезапустите приложение
3. Проверьте, что Firebase инициализируется только один раз

## Проверочный список

- [ ] Правила Firestore настроены корректно
- [ ] Firebase SDK обновлен до последней версии
- [ ] Интернет-соединение стабильно
- [ ] Кэш браузера очищен
- [ ] Приложение запущено с правильными флагами
- [ ] Проект ID корректный (`volleyball-a7d8d`)
- [ ] API ключи действительны

## Полезные команды

```bash
# Очистка проекта
flutter clean
flutter pub get

# Запуск с диагностикой
./run_app_with_diagnostics.bat

# Развертывание правил Firestore
./deploy_firestore_rules.bat

# Проверка Flutter
flutter doctor

# Проверка устройств
flutter devices
```

## Контакты для поддержки

Если проблема не решается:
1. Проверьте логи в консоли браузера
2. Сохраните скриншоты ошибок
3. Опишите шаги для воспроизведения проблемы

## Дополнительные ресурсы

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Setup](https://firebase.flutter.dev/docs/overview)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Status Page](https://status.firebase.google.com/) 