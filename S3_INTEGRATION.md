# AWS S3 интеграция в PlayBall 🚀

## ✅ Что настроено:

### 1. **AWS S3 Bucket**
- **Имя**: `playball-storage-playball-storage-2025-dev`
- **Регион**: `eu-north-1` (Stockholm)
- **Структура папок**:
  ```
  📁 users/
    📁 profiles/     (фото профилей)
    📁 avatars/      (аватары пользователей)
  📁 teams/
    📁 logos/        (логотипы команд)
    📁 photos/       (фото команд)
  📁 games/
    📁 screenshots/  (скриншоты результатов)
    📁 reports/      (PDF отчеты)
  ```

### 2. **IAM пользователь**
- **Имя**: `playball-app-user`
- **Политика**: `PlayBallS3AccessPolicy`
- **Права**: Upload, Download, Delete файлов в бакете

### 3. **Flutter интеграция**
- ✅ Зависимости добавлены: `aws_s3_upload`, `flutter_dotenv`
- ✅ S3 сервис создан: `lib/core/services/s3_upload_service.dart`
- ✅ .env файл настроен для безопасного хранения ключей
- ✅ main.dart обновлен для загрузки конфигурации

## 🔑 Конфигурация

### Файл `.env` (в корне проекта):
```env
AWS_ACCESS_KEY=ваши_aws_ключи
AWS_SECRET_KEY=ваши_aws_ключи
AWS_BUCKET_NAME=playball-storage-playball-storage-2025-dev
AWS_REGION=eu-north-1
```

## 🛠️ Как использовать:

### Загрузка фото профиля:
```dart
final photoUrl = await S3UploadService.uploadUserPhoto(imageFile, userId);
if (photoUrl != null) {
  // Обновляем в Firestore
  await userService.updateUser(userId: userId, photoUrl: photoUrl);
}
```

### Загрузка логотипа команды:
```dart
final logoUrl = await S3UploadService.uploadTeamLogo(imageFile, teamId);
```

### Готовый виджет загрузки фото:
```dart
PhotoUploadWidget(
  currentPhotoUrl: user.photoUrl,
  userId: user.id,
  onPhotoUploaded: (url) {
    // Фото загружено в S3 и обновлено в Firestore
  },
)
```

## 💰 Стоимость

**Примерная стоимость для PlayBall:**
- **Хранение**: 1GB ≈ $0.023/месяц
- **Загрузки**: 10,000 файлов ≈ $0.05
- **Скачивания**: первые 100GB бесплатно
- **Итого**: ~$1-5/месяц на начальном этапе

## 🚀 Следующие шаги:

1. **Интеграция в экраны профилей** ✅
2. **Добавление логотипов команд**
3. **Скриншоты результатов игр**
4. **CDN через CloudFront** (для ускорения)
5. **Автоматическое сжатие изображений**

## 🔒 Безопасность:

- ✅ AWS ключи не в коде, только в .env
- ✅ .env добавлен в .gitignore
- ✅ IAM пользователь с минимальными правами
- ✅ Доступ только к одному бакету

## 📱 Примеры использования:

### 1. Обновление фото профиля
Используйте `PhotoUploadWidget` в экране профиля

### 2. Логотип команды
```dart
class TeamLogoUploader extends StatelessWidget {
  final String teamId;
  
  Future<void> _uploadLogo() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      final url = await S3UploadService.uploadTeamLogo(File(image.path), teamId);
      // Обновить команду в Firestore
    }
  }
}
```

---

**🎉 S3 интеграция готова к использованию!**

Теперь все изображения будут загружаться в надежное и масштабируемое хранилище AWS S3. 