# 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Ошибка 400 Bad Request

## ⚡ НЕМЕДЛЕННЫЕ ДЕЙСТВИЯ

### 1. В приложении (СЕЙЧАС):
1. Откройте **"Тестировать Firebase"** в приложении
2. Нажмите красную кнопку **"Диагностика 400"**
3. Проверьте результаты в окне приложения

### 2. Проверьте Firebase Console (КРИТИЧНО):
🔗 **Откройте:** https://console.firebase.google.com/project/volleyball-a7d8d/firestore

**Если видите "Создать базу данных":**
1. ✅ Нажмите "Создать базу данных"
2. ✅ Выберите "Начать в тестовом режиме"
3. ✅ Выберите регион: `europe-west1`
4. ✅ Нажмите "Готово"

**Если Firestore уже создан:**
1. Перейдите в **Database → Rules**
2. Замените правила на:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```
3. Нажмите **"Опубликовать"**

## 🔍 Диагностика ошибки

**Ошибка:** `400 Bad Request` на URL:
```
https://firestore.googleapis.com/google.firestore.v1.Firestore/Write/channel
database=projects%2Fvolleyball-a7d8d%2Fdatabases%2F(default)
```

**Причина:** Firestore Write API недоступен для проекта `volleyball-a7d8d`

## ✅ Проверочный список

- [ ] Firestore создан в проекте volleyball-a7d8d
- [ ] Правила безопасности разрешают доступ
- [ ] Кнопка "Диагностика 400" нажата в приложении
- [ ] Нет ошибок 400 в Network tab браузера

## 🆘 Если не помогает

### Создайте новый проект:
1. Откройте https://console.firebase.google.com/
2. Нажмите "Создать проект"
3. Назовите: `volleyball-test-2025`
4. Создайте Firestore в тестовом режиме
5. Обновите `lib/firebase_options.dart` с новыми данными

---
**СТАТУС:** 🚨 КРИТИЧНО - требует немедленного исправления 