import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:minio/minio.dart';

/// S3 Upload Service для загрузки файлов в AWS S3
/// 
/// Использует пакет minio для надежной работы в веб и мобильных
class S3UploadService {
  // AWS конфигурация из .env файла
  static String get _accessKey => dotenv.env['AWS_ACCESS_KEY'] ?? '';
  static String get _secretKey => dotenv.env['AWS_SECRET_KEY'] ?? '';
  static String get _bucketName => dotenv.env['AWS_BUCKET_NAME'] ?? '';
  static String get _region => dotenv.env['AWS_REGION'] ?? '';

  static Minio get _minio => Minio(
    endPoint: 's3.amazonaws.com',
    accessKey: _accessKey,
    secretKey: _secretKey,
    useSSL: true,
    region: _region,
  );

  /// Загрузка фото профиля пользователя (File для мобильных)
  static Future<String?> uploadUserPhoto(File imageFile, String userId) async {
    try {
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await imageFile.readAsBytes();
      
      await _minio.putObject(
        _bucketName,
        'users/profiles/$fileName',
        Stream<Uint8List>.value(fileBytes),
        size: fileBytes.length,
        metadata: {
          'Content-Type': 'image/jpeg',
        },
      );
      
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/users/profiles/$fileName';
      
      if (kDebugMode) {
        print('✅ User photo uploaded: $url');
      }
      
      return url;
    } catch (e) {
      if (kDebugMode) {
        print('❌ S3 Upload error: $e');
      }
      return null;
    }
  }

  /// Загрузка аватара пользователя (Uint8List для веб и мобильных)
  static Future<String?> uploadUserAvatar(Uint8List imageBytes, String userId) async {
    try {
      final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _minio.putObject(
        _bucketName,
        'users/avatars/$fileName',
        Stream<Uint8List>.value(imageBytes),
        size: imageBytes.length,
        metadata: {
          'Content-Type': 'image/jpeg',
        },
      );
      
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/users/avatars/$fileName';
      
      if (kDebugMode) {
        print('✅ User avatar uploaded: $url');
      }
      
      return url;
    } catch (e) {
      if (kDebugMode) {
        print('❌ S3 Upload error: $e');
      }
      return null;
    }
  }

  /// Загрузка логотипа команды (File для мобильных)
  static Future<String?> uploadTeamLogo(File imageFile, String teamId) async {
    try {
      final fileName = 'logo_${teamId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await imageFile.readAsBytes();
      
      await _minio.putObject(
        _bucketName,
        'teams/logos/$fileName',
        Stream<Uint8List>.value(fileBytes),
        size: fileBytes.length,
        metadata: {
          'Content-Type': 'image/jpeg',
        },
      );
      
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/teams/logos/$fileName';
      
      if (kDebugMode) {
        print('✅ Team logo uploaded: $url');
      }
      
      return url;
    } catch (e) {
      if (kDebugMode) {
        print('❌ S3 Upload error: $e');
      }
      return null;
    }
  }

  /// Загрузка аватара команды (Uint8List для веб и мобильных)
  static Future<String?> uploadTeamAvatar(Uint8List imageBytes, String teamId) async {
    try {
      final fileName = 'team_avatar_${teamId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _minio.putObject(
        _bucketName,
        'teams/logos/$fileName',
        Stream<Uint8List>.value(imageBytes),
        size: imageBytes.length,
        metadata: {
          'Content-Type': 'image/jpeg',
        },
      );
      
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/teams/logos/$fileName';
      
      if (kDebugMode) {
        print('✅ Team avatar uploaded: $url');
      }
      
      return url;
    } catch (e) {
      if (kDebugMode) {
        print('❌ S3 Upload error: $e');
      }
      return null;
    }
  }

  /// Загрузка изображения комнаты (Uint8List для веб и мобильных)
  static Future<String?> uploadRoomImage(Uint8List imageBytes, String roomId) async {
    try {
      final fileName = 'room_${roomId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _minio.putObject(
        _bucketName,
        'rooms/images/$fileName',
        Stream<Uint8List>.value(imageBytes),
        size: imageBytes.length,
        metadata: {
          'Content-Type': 'image/jpeg',
        },
      );
      
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/rooms/images/$fileName';
      
      if (kDebugMode) {
        print('✅ Room image uploaded: $url');
      }
      
      return url;
    } catch (e) {
      if (kDebugMode) {
        print('❌ S3 Upload error: $e');
      }
      return null;
    }
  }

  /// Загрузка скриншота результата игры (Uint8List для веб и мобильных)
  static Future<String?> uploadGameScreenshot(Uint8List imageBytes, String gameId) async {
    try {
      final fileName = 'screenshot_${gameId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _minio.putObject(
        _bucketName,
        'games/screenshots/$fileName',
        Stream<Uint8List>.value(imageBytes),
        size: imageBytes.length,
        metadata: {
          'Content-Type': 'image/jpeg',
        },
      );
      
      final url = 'https://$_bucketName.s3.$_region.amazonaws.com/games/screenshots/$fileName';
      
      if (kDebugMode) {
        print('✅ Game screenshot uploaded: $url');
      }
      
      return url;
    } catch (e) {
      if (kDebugMode) {
        print('❌ S3 Upload error: $e');
      }
      return null;
    }
  }
}