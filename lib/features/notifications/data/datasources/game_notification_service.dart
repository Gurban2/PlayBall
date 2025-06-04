import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/game_notification_model.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../../auth/domain/entities/user_model.dart';

/// Сервис для управления уведомлениями о играх
class GameNotificationService {
  static const String _collectionName = 'game_notifications';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Отправить уведомление о создании новой игры всем пользователям в радиусе
  Future<void> notifyGameCreated({
    required RoomModel room,
    required UserModel organizer,
    List<String>? specificRecipients,
  }) async {
    try {
      // Получаем список получателей
      List<String> recipientIds = specificRecipients ?? 
          await _getNearbyPlayersIds(room.location ?? '');
      
      if (recipientIds.isEmpty) return;

      final notification = GameNotificationModel.gameCreated(
        id: _uuid.v4(),
        roomId: room.id,
        roomTitle: room.title,
        organizerId: organizer.id,
        organizerName: organizer.name,
        recipientIds: recipientIds,
        scheduledDateTime: room.startTime,
        location: room.location ?? 'Не указано',
      );

      // Создаем отдельное уведомление для каждого получателя
      final batch = _firestore.batch();
      
      for (String recipientId in recipientIds) {
        final personalNotification = notification.copyWith(
          id: _uuid.v4(),
          recipientIds: [recipientId],
        );
        
        final docRef = _firestore
            .collection(_collectionName)
            .doc(personalNotification.id);
        
        batch.set(docRef, personalNotification.toMap());
      }

      await batch.commit();
      
      debugPrint('✅ Отправлено ${recipientIds.length} уведомлений о создании игры "${room.title}"');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомлений о создании игры: $e');
      rethrow;
    }
  }

  /// Отправить уведомление об изменениях в игре участникам
  Future<void> notifyGameUpdated({
    required RoomModel room,
    required UserModel organizer,
    required String changes,
  }) async {
    try {
      final recipientIds = room.participants.where((id) => id != organizer.id).toList();
      
      if (recipientIds.isEmpty) return;

      final notification = GameNotificationModel.gameUpdated(
        id: _uuid.v4(),
        roomId: room.id,
        roomTitle: room.title,
        organizerId: organizer.id,
        organizerName: organizer.name,
        recipientIds: recipientIds,
        changes: changes,
      );

      await _sendNotificationToUsers(notification, recipientIds);
      
      debugPrint('✅ Отправлено ${recipientIds.length} уведомлений об изменении игры "${room.title}"');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомлений об изменении игры: $e');
      rethrow;
    }
  }

  /// Отправить уведомление о скором начале игры
  Future<void> notifyGameStarting({
    required RoomModel room,
    required UserModel organizer,
    required int minutesLeft,
  }) async {
    try {
      final recipientIds = room.participants;
      
      if (recipientIds.isEmpty) return;

      final notification = GameNotificationModel.gameStarting(
        id: _uuid.v4(),
        roomId: room.id,
        roomTitle: room.title,
        organizerId: organizer.id,
        organizerName: organizer.name,
        recipientIds: recipientIds,
        minutesLeft: minutesLeft,
      );

      await _sendNotificationToUsers(notification, recipientIds);
      
      debugPrint('✅ Отправлено ${recipientIds.length} уведомлений о скором начале игры "${room.title}"');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомлений о скором начале игры: $e');
      rethrow;
    }
  }

  /// Отправить уведомление о начале игры
  Future<void> notifyGameStarted({
    required RoomModel room,
    required UserModel organizer,
  }) async {
    try {
      final recipientIds = room.participants;
      
      if (recipientIds.isEmpty) return;

      final notification = GameNotificationModel.gameStarted(
        id: _uuid.v4(),
        roomId: room.id,
        roomTitle: room.title,
        organizerId: organizer.id,
        organizerName: organizer.name,
        recipientIds: recipientIds,
      );

      await _sendNotificationToUsers(notification, recipientIds);
      
      debugPrint('✅ Отправлено ${recipientIds.length} уведомлений о начале игры "${room.title}"');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомлений о начале игры: $e');
      rethrow;
    }
  }

  /// Отправить уведомление о завершении игры
  Future<void> notifyGameEnded({
    required RoomModel room,
    required UserModel organizer,
    String? winnerTeamName,
  }) async {
    try {
      final recipientIds = room.participants;
      
      if (recipientIds.isEmpty) return;

      final notification = GameNotificationModel.gameEnded(
        id: _uuid.v4(),
        roomId: room.id,
        roomTitle: room.title,
        organizerId: organizer.id,
        organizerName: organizer.name,
        recipientIds: recipientIds,
        winnerTeamName: winnerTeamName,
      );

      await _sendNotificationToUsers(notification, recipientIds);
      
      debugPrint('✅ Отправлено ${recipientIds.length} уведомлений о завершении игры "${room.title}"');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомлений о завершении игры: $e');
      rethrow;
    }
  }

  /// Отправить уведомление об отмене игры
  Future<void> notifyGameCancelled({
    required RoomModel room,
    required UserModel organizer,
    String? reason,
  }) async {
    try {
      final recipientIds = room.participants.where((id) => id != organizer.id).toList();
      
      if (recipientIds.isEmpty) return;

      final notification = GameNotificationModel.gameCancelled(
        id: _uuid.v4(),
        roomId: room.id,
        roomTitle: room.title,
        organizerId: organizer.id,
        organizerName: organizer.name,
        recipientIds: recipientIds,
        reason: reason,
      );

      await _sendNotificationToUsers(notification, recipientIds);
      
      debugPrint('✅ Отправлено ${recipientIds.length} уведомлений об отмене игры "${room.title}"');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомлений об отмене игры: $e');
      rethrow;
    }
  }

  /// Отправить уведомление о присоединении игрока
  Future<void> notifyPlayerJoined({
    required RoomModel room,
    required UserModel organizer,
    required UserModel player,
  }) async {
    try {
      final recipientIds = room.participants.where((id) => id != player.id).toList();
      
      if (recipientIds.isEmpty) return;

      final notification = GameNotificationModel.playerJoined(
        id: _uuid.v4(),
        roomId: room.id,
        roomTitle: room.title,
        organizerId: organizer.id,
        organizerName: organizer.name,
        recipientIds: recipientIds,
        playerName: player.name,
      );

      await _sendNotificationToUsers(notification, recipientIds);
      
      debugPrint('✅ Отправлено ${recipientIds.length} уведомлений о присоединении игрока "${player.name}"');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомлений о присоединении игрока: $e');
      rethrow;
    }
  }

  /// Получить уведомления о играх для пользователя
  Future<List<GameNotificationModel>> getGameNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('recipientIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => GameNotificationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения уведомлений о играх: $e');
      return [];
    }
  }

  /// Получить уведомления о играх в реальном времени
  Stream<List<GameNotificationModel>> getGameNotificationsStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('recipientIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameNotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(notificationId)
          .update({'isRead': true});
      
      debugPrint('✅ Уведомление отмечено как прочитанное: $notificationId');
    } catch (e) {
      debugPrint('❌ Ошибка отметки уведомления как прочитанного: $e');
      rethrow;
    }
  }

  /// Отметить все уведомления пользователя как прочитанные
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('recipientIds', arrayContains: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      
      debugPrint('✅ Все уведомления пользователя $userId отмечены как прочитанные');
    } catch (e) {
      debugPrint('❌ Ошибка отметки всех уведомлений как прочитанных: $e');
      rethrow;
    }
  }

  /// Удалить уведомление
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(notificationId)
          .delete();
      
      debugPrint('✅ Уведомление удалено: $notificationId');
    } catch (e) {
      debugPrint('❌ Ошибка удаления уведомления: $e');
      rethrow;
    }
  }

  /// Получить количество непрочитанных уведомлений о играх
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('recipientIds', arrayContains: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Ошибка получения количества непрочитанных уведомлений: $e');
      return 0;
    }
  }

  // Приватные методы

  /// Отправить уведомление нескольким пользователям
  Future<void> _sendNotificationToUsers(
    GameNotificationModel notification,
    List<String> recipientIds,
  ) async {
    final batch = _firestore.batch();
    
    for (String recipientId in recipientIds) {
      final personalNotification = notification.copyWith(
        id: _uuid.v4(),
        recipientIds: [recipientId],
      );
      
      final docRef = _firestore
          .collection(_collectionName)
          .doc(personalNotification.id);
      
      batch.set(docRef, personalNotification.toMap());
    }

    await batch.commit();
  }

  /// Получить IDs игроков поблизости (заглушка - нужна геолокация)
  Future<List<String>> _getNearbyPlayersIds(String location) async {
    // TODO: Реализовать поиск игроков по геолокации
    // Пока возвращаем всех активных пользователей
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .where('isActive', isEqualTo: true)
          .limit(100)
          .get();

      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения списка игроков: $e');
      return [];
    }
  }

  /// Планировщик уведомлений (для будущей реализации)
  Future<void> scheduleGameStartingNotifications() async {
    // TODO: Реализовать планировщик уведомлений
    // Сканировать игры, которые начнутся через 30/15/5 минут
    // Отправлять соответствующие уведомления
    debugPrint('📅 Планировщик уведомлений запущен');
  }
} 