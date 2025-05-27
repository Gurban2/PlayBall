# 🔥 Настройка индексов Firestore

## ❗ **Проблема**
Приложение показывает ошибку: "The query requires an index" - это означает, что Firestore требует создания составных индексов для наших запросов.

## ✅ **Решение: Создание индексов через Firebase Console**

### **Шаг 1: Откройте Firebase Console**
1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Выберите ваш проект "volleyball-connect"
3. В левом меню выберите **Firestore Database**
4. Перейдите на вкладку **Indexes**

### **Шаг 2: Создайте необходимые составные индексы**

Создайте следующие индексы для коллекции `rooms`:

#### **Индекс 1: Активные комнаты**
- **Collection ID**: `rooms`
- **Fields**:
  - `status` → **Ascending**
  - `startTime` → **Ascending**
- **Query scope**: Collection

#### **Индекс 2: Запланированные комнаты**  
- **Collection ID**: `rooms`
- **Fields**:
  - `status` → **Ascending**
  - `startTime` → **Ascending**
- **Query scope**: Collection

#### **Индекс 3: Комнаты пользователя**
- **Collection ID**: `rooms`
- **Fields**:
  - `participants` → **Array-contains**
  - `startTime` → **Ascending**
- **Query scope**: Collection

#### **Индекс 4: Комнаты организатора**
- **Collection ID**: `rooms`
- **Fields**:
  - `organizerId` → **Ascending**
  - `startTime` → **Ascending**
- **Query scope**: Collection

### **Шаг 3: Дождитесь создания индексов**
- Создание индексов может занять несколько минут
- Статус будет показан в консоли Firebase
- После завершения индексы будут помечены зеленой галочкой

### **Шаг 4: Перезапустите приложение**
После создания всех индексов перезапустите Flutter приложение.

## 🚀 **Альтернативное решение: Упрощение запросов**

Если не хотите создавать индексы, можно упростить запросы в коде (см. следующий файл с изменениями).

## 📝 **Примечания**
- Индексы нужно создать только один раз
- Они автоматически поддерживаются Firestore
- Индексы улучшают производительность запросов
- Без индексов сложные запросы не будут работать

## 🔗 **Полезные ссылки**
- [Документация по индексам Firestore](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Управление индексами](https://firebase.google.com/docs/firestore/query-data/index-overview) 