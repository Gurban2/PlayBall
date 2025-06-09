# 🔧 Настройка AWS S3 для публичного доступа к изображениям

## ❌ Проблемы
1. **403 Forbidden** - нет публичного доступа к файлам
2. **"The bucket does not allow ACLs"** - заблокированы ACL

## ✅ Решение

### Шаг 1: Настройка Block Public Access
1. Откройте **AWS S3 Console** → выберите bucket `playball-storage-playball-storage-2025-dev`
2. Перейдите на вкладку **Permissions**
3. В разделе **Block public access (bucket settings)** нажмите **Edit**
4. **Снимите галочку** с "Block all public access" (если нужен полный публичный доступ)
5. Или оставьте включенными только:
   - ✅ Block public access to buckets and objects granted through new access control lists (ACLs)
   - ✅ Block public access to buckets and objects granted through any access control lists (ACLs)
   - ❌ Block public access to buckets and objects granted through new public bucket or access point policies
   - ❌ Block public access to buckets and objects granted through any public bucket or access point policies
6. Нажмите **Save changes** и подтвердите

### Шаг 2: Добавление Bucket Policy
1. В том же разделе **Permissions** найдите **Bucket policy**
2. Нажмите **Edit** и вставьте содержимое файла `aws_bucket_policy.json`:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::playball-storage-playball-storage-2025-dev/*"
        }
    ]
}
```

3. Нажмите **Save changes**

### Шаг 3: Проверка CORS
1. Перейдите на вкладку **Permissions** → **Cross-origin resource sharing (CORS)**
2. Убедитесь, что настройки CORS включают:

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
        "AllowedOrigins": ["http://localhost:*", "https://yourdomain.com"],
        "ExposeHeaders": []
    }
]
```

## 🧪 Тестирование

После применения настроек:
1. Попробуйте загрузить новый аватар
2. Проверьте доступность по URL в браузере
3. Если старые изображения недоступны - перезагрузите их

## 📝 Примечания

- **Без ACL**: Мы не используем ACL заголовки, только bucket policy
- **Безопасность**: Bucket policy дает публичный доступ только на чтение
- **Производство**: Для продакшена рассмотрите использование CloudFront CDN

## 🚨 Важно

Эта настройка делает **ВСЕ файлы в bucket публично доступными для чтения**. 
Убедитесь, что вы не храните приватные данные в этом bucket. 