import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/game_notification_model.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../../shared/services/base_notification_service.dart';
import '../../../../shared/factories/notification_factory.dart';

/// Сервис для управления уведомлениями о играх
class GameNotificationService extends BaseNotificationService {
  @override
  String get collectionName => 'game_notifications';

  /// Отправить уведомление о создании новой игры всем пользователям в радиусе
  Future<void> notifyGameCreated({
    required RoomModel room,
    required UserModel organizer,
    List<String>? specificRecipients,
  }) async {
    final recipientIds = specificRecipients ?? await _getNearbyPlayersIds(room.location);
    
    if (recipientIds.isEmpty) {
      logWarning('Нет получателей для уведомления о создании игры "${room.title}"');
      return;
    }

    final notification = NotificationFactory.gameCreated(
      id: generateId(),
      room: room,
      organizer: organizer,
      recipientIds: recipientIds,
    );

    await _sendNotificationToMultipleUsers(notification, recipientIds, 'создании игры "${room.title}"');
  }

  /// Отправить уведомление об изменениях в игре участникам
  Future<void> notifyGameUpdated({
    required RoomModel room,
    required UserModel organizer,
    required String changes,
  }) async {
    final recipientIds = room.participants.where((id) => id != organizer.id).toList();
    
    if (recipientIds.isEmpty) {
      logWarning('Нет участников для уведомления об изменении игры "${room.title}"');
      return;
    }

    final notification = NotificationFactory.gameUpdated(
      id: generateId(),
      room: room,
      organizer: organizer,
      recipientIds: recipientIds,
      changes: changes,
    );

    await _sendNotificationToMultipleUsers(notification, recipientIds, 'изменении игры "${room.title}"');
  }

  /// Отправить уведомление о скором начале игры
  Future<void> notifyGameStarting({
    required RoomModel room,
    required UserModel organizer,
    required int minutesLeft,
  }) async {
    final recipientIds = room.participants;
    
    if (recipientIds.isEmpty) {
      logWarning('Нет участников для уведомления о скором начале игры "${room.title}"');
      return;
    }

    final notification = NotificationFactory.gameStarting(
      id: generateId(),
      room: room,
      organizer: organizer,
      recipientIds: recipientIds,
      minutesLeft: minutesLeft,
    );

    await _sendNotificationToMultipleUsers(notification, recipientIds, 'скором начале игры "${room.title}"');
  }

  /// Отправить уведомление о начале игры
  Future<void> notifyGameStarted({
    required RoomModel room,
    required UserModel organizer,
  }) async {
    final recipientIds = room.participants;
    
    if (recipientIds.isEmpty) {
      logWarning('Нет участников для уведомления о начале игры "${room.title}"');
      return;
    }

    final notification = NotificationFactory.gameStarted(
      id: generateId(),
      room: room,
      organizer: organizer,
      recipientIds: recipientIds,
    );

    await _sendNotificationToMultipleUsers(notification, recipientIds, 'начале игры "${room.title}"');
  }

  /// Отправить уведомление о завершении игры
  Future<void> notifyGameEnded({
    required RoomModel room,
    required UserModel organizer,
    String? winnerTeamName,
  }) async {
    final recipientIds = room.participants;
    
    if (recipientIds.isEmpty) {
      logWarning('Нет участников для уведомления о завершении игры "${room.title}"');
      return;
    }

    final notification = NotificationFactory.gameEnded(
      id: generateId(),
      room: room,
      organizer: organizer,
      recipientIds: recipientIds,
      winnerTeamName: winnerTeamName,
    );

    await _sendNotificationToMultipleUsers(notification, recipientIds, 'завершении игры "${room.title}"');
  }

  /// Отправить уведомление об отмене игры
  Future<void> notifyGameCancelled({
    required RoomModel room,
    required UserModel organizer,
    String? reason,
  }) async {
    final recipientIds = room.participants.where((id) => id != organizer.id).toList();
    
    if (recipientIds.isEmpty) {
      logWarning('Нет участников для уведомления об отмене игры "${room.title}"');
      return;
    }

    final notification = NotificationFactory.gameCancelled(
      id: generateId(),
      room: room,
      organizer: organizer,
      recipientIds: recipientIds,
      reason: reason,
    );

    await _sendNotificationToMultipleUsers(notification, recipientIds, 'отмене игры "${room.title}"');
  }

  /// Отправить уведомление о присоединении игрока
  Future<void> notifyPlayerJoined({
    required RoomModel room,
    required UserModel organizer,
    required UserModel player,
  }) async {
    final recipientIds = room.participants.where((id) => id != player.id).toList();
    
    if (recipientIds.isEmpty) {
      logWarning('Нет участников для уведомления о присоединении игрока "${player.name}"');
      return;
    }

    final notification = NotificationFactory.playerJoined(
      id: generateId(),
      room: room,
      organizer: organizer,
      player: player,
      recipientIds: recipientIds,
    );

    await _sendNotificationToMultipleUsers(notification, recipientIds, 'присоединении игрока "${player.name}"');
  }

  /// Отправить уведомление о необходимости оценки игроков
  Future<void> notifyEvaluationRequired({
    required RoomModel room,
    required UserModel organizer,
  }) async {
    final recipientIds = room.participants;
    
    if (recipientIds.isEmpty) {
      logWarning('❌ Нет участников для уведомления об оценке в игре "${room.title}"');
      return;
    }

    final notification = NotificationFactory.evaluationRequired(
      id: generateId(),
      room: room,
      organizer: organizer,
      recipientIds: recipientIds,
    );

    await _sendNotificationToMultipleUsers(notification, recipientIds, 'необходимости оценки игроков');
  }

  /// Отправить уведомление о необходимости выбора победителя
  Future<void> notifyWinnerSelectionRequired({
    required RoomModel room,
    required UserModel organizer,
    bool? isTeamMode,
    int? playersToSelect,
  }) async {
    // Уведомление о выборе победителя отправляется только организатору игры
    final recipientIds = [organizer.id];

    final notification = NotificationFactory.winnerSelectionRequired(
      id: generateId(),
      room: room,
      organizer: organizer,
      recipientIds: recipientIds,
      isTeamMode: isTeamMode,
      playersToSelect: playersToSelect,
    );

    await _sendNotificationToMultipleUsers(notification, recipientIds, 'выборе победителей');
  }

  /// Отправить уведомление игроку о его оценке
  Future<void> notifyPlayerEvaluated({
    required RoomModel room,
    required UserModel organizer,
    required UserModel evaluatedPlayer,
    required double rating,
    required String evaluatorName,
  }) async {
    logInfo('Отправляем уведомление об оценке игроку ${evaluatedPlayer.name}');

    final notification = NotificationFactory.playerEvaluated(
      id: generateId(),
      room: room,
      organizer: organizer,
      evaluatedPlayer: evaluatedPlayer,
      rating: rating,
      evaluatorName: evaluatorName,
    );

    await _sendSingleNotification(notification, evaluatedPlayer.id, 'оценке игрока ${evaluatedPlayer.name}');
  }

  /// Отправить уведомления о проверке активности команды
  Future<void> notifyActivityCheck({
    required String teamId,
    required String teamName,
    required List<String> teamMembers,
  }) async {
    logInfo('Отправляем уведомления о проверке активности команды "$teamName"');
    
    if (teamMembers.isEmpty) {
      logWarning('Нет игроков для уведомления о проверке активности команды $teamId');
      return;
    }

    final notification = NotificationFactory.activityCheck(
      id: generateId(),
      teamId: teamId,
      teamName: teamName,
      recipientIds: teamMembers,
    );

    await _sendNotificationToMultipleUsers(notification, teamMembers, 'проверке активности команды "$teamName"');
  }

  /// Отправить уведомления о победе команды
  Future<void> notifyTeamVictory({
    required RoomModel room,
    required UserModel organizer,
    required String winnerTeamName,
    required List<String> teamMembers,
  }) async {
    logInfo('Отправляем уведомления о победе команды "$winnerTeamName"');
    
    if (teamMembers.isEmpty) {
      logWarning('Нет участников команды для уведомления о победе');
      return;
    }

    final notification = NotificationFactory.teamVictory(
      id: generateId(),
      room: room,
      organizer: organizer,
      winnerTeamName: winnerTeamName,
      teamMembers: teamMembers,
    );

    await _sendNotificationToMultipleUsers(notification, teamMembers, 'победе команды "$winnerTeamName"');
  }

  /// Получить уведомления о играх для пользователя
  Future<List<GameNotificationModel>> getGameNotifications(String userId) async {
    final notifications = await getUserNotifications(userId);
    return notifications
        .map((data) => GameNotificationModel.fromMap(data, data['id']))
        .toList();
  }

  /// Получить уведомления о играх в реальном времени
  Stream<List<GameNotificationModel>> getGameNotificationsStream(String userId) {
    return getUserNotificationsStream(userId).map((notifications) =>
        notifications
            .map((data) => GameNotificationModel.fromMap(data, data['id']))
            .toList());
  }

  // Приватные методы

  /// Отправить уведомление одному пользователю
  Future<void> _sendSingleNotification(
    GameNotificationModel notification,
    String recipientId,
    String operationDescription,
  ) async {
    await executeVoidWithLogging(
      'отправки уведомления о $operationDescription',
      () async {
        final personalNotification = notification.copyWith(
          id: generateId(),
          recipientIds: [recipientId],
        );
        
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(personalNotification.id)
            .set(personalNotification.toMap());
      },
      successDetails: 'игроку $recipientId',
    );
  }

  /// Отправить уведомление нескольким пользователям
  Future<void> _sendNotificationToMultipleUsers(
    GameNotificationModel notification,
    List<String> recipientIds,
    String operationDescription,
  ) async {
    final notifications = recipientIds.map((recipientId) {
      final personalNotification = notification.copyWith(
        id: generateId(),
        recipientIds: [recipientId],
      );
      return personalNotification.toMap();
    }).toList();

    await sendBatchNotifications(notifications, 'отправки уведомлений о $operationDescription');
  }

  /// Получить IDs игроков поблизости на основе активных пользователей
  Future<List<String>> _getNearbyPlayersIds(String location) async {
    return executeWithLogging(
      'получения списка игроков поблизости',
      () async {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .where('isActive', isEqualTo: true)
            .limit(100)
            .get();

        return querySnapshot.docs.map((doc) => doc.id).toList();
      },
      rethrowErrors: false,
    ).catchError((e) {
      logError('получения списка игроков', e);
      return <String>[];
    });
  }


} 