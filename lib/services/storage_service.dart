import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Загружает изображение в Firebase Storage и возвращает URL
  Future<String> uploadRoomImage(Uint8List imageBytes, String roomId) async {
    try {
      // Создаем уникальное имя файла
      final fileName = '${_uuid.v4()}.jpg';
      final path = 'rooms/$roomId/images/$fileName';
      
      // Создаем ссылку на файл в Storage
      final ref = _storage.ref().child(path);
      
      // Загружаем файл с метаданными
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'roomId': roomId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Ждем завершения загрузки
      final snapshot = await uploadTask;
      
      // Получаем URL для скачивания
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки изображения: $e');
    }
  }

  /// Загружает аватар пользователя
  Future<String> uploadUserAvatar(Uint8List imageBytes, String userId) async {
    try {
      final fileName = 'avatar_${_uuid.v4()}.jpg';
      final path = 'users/$userId/avatar/$fileName';
      
      final ref = _storage.ref().child(path);
      
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки аватара: $e');
    }
  }

  /// Загружает аватар команды
  Future<String> uploadTeamAvatar(String teamId, Uint8List imageBytes) async {
    try {
      final fileName = 'team_avatar_${_uuid.v4()}.jpg';
      final path = 'teams/$teamId/avatar/$fileName';
      
      final ref = _storage.ref().child(path);
      
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'teamId': teamId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки аватара команды: $e');
    }
  }

  /// Удаляет файл по URL
  Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Игнорируем ошибки удаления (файл может уже не существовать)
      debugPrint('Предупреждение: не удалось удалить файл $url: $e');
    }
  }

  /// Удаляет все изображения комнаты
  Future<void> deleteRoomImages(String roomId) async {
    try {
      final ref = _storage.ref().child('rooms/$roomId/images');
      final listResult = await ref.listAll();
      
      // Удаляем все файлы в папке
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('Предупреждение: не удалось удалить изображения комнаты $roomId: $e');
    }
  }
} 