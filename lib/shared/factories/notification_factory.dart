import '../../features/notifications/domain/entities/game_notification_model.dart';
import '../../features/auth/domain/entities/user_model.dart';
import '../../features/rooms/domain/entities/room_model.dart';

/// Фабрика для создания различных типов уведомлений
class NotificationFactory {
  
  /// Базовая структура для создания игровых уведомлений
  static GameNotificationModel _createGameNotification({
    required String id,
    required String roomId,
    required String roomTitle,
    required String organizerId,
    required String organizerName,
    required List<String> recipientIds,
    required GameNotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
    DateTime? scheduledDateTime,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: roomId,
      roomTitle: roomTitle,
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: recipientIds,
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      scheduledDateTime: scheduledDateTime,
      additionalData: additionalData,
    );
  }

  /// Фабричные методы для игровых уведомлений
  
  static GameNotificationModel gameCreated({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required List<String> recipientIds,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: recipientIds,
      type: GameNotificationType.gameCreated,
      title: '🏐 Новая игра!',
      message: '${organizer.name} создал игру "${room.title}"',
      scheduledDateTime: room.startTime,
      additionalData: {'location': room.location},
    );
  }

  static GameNotificationModel gameUpdated({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required List<String> recipientIds,
    required String changes,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: recipientIds,
      type: GameNotificationType.gameUpdated,
      title: '📝 Изменения в игре',
      message: 'Игра "${room.title}" была изменена: $changes',
      additionalData: {'changes': changes},
    );
  }

  static GameNotificationModel gameStarting({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required List<String> recipientIds,
    required int minutesLeft,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: recipientIds,
      type: GameNotificationType.gameStarting,
      title: '⏰ Игра скоро начнется!',
      message: 'Игра "${room.title}" начнется через $minutesLeft мин.',
      additionalData: {'minutesLeft': minutesLeft},
    );
  }

  static GameNotificationModel gameStarted({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required List<String> recipientIds,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: recipientIds,
      type: GameNotificationType.gameStarted,
      title: '🏐 Игра началась!',
      message: 'Игра "${room.title}" началась. Удачи!',
    );
  }

  static GameNotificationModel gameEnded({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required List<String> recipientIds,
    String? winnerTeamName,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: recipientIds,
      type: GameNotificationType.gameEnded,
      title: '🏆 Игра завершена!',
      message: winnerTeamName != null
          ? 'Игра "${room.title}" завершена. Победила команда: $winnerTeamName!'
          : 'Игра "${room.title}" завершена.',
      additionalData: winnerTeamName != null ? {'winner': winnerTeamName} : null,
    );
  }

  static GameNotificationModel gameCancelled({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required List<String> recipientIds,
    String? reason,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: recipientIds,
      type: GameNotificationType.gameCancelled,
      title: '❌ Игра отменена',
      message: reason != null
          ? 'Игра "${room.title}" отменена. Причина: $reason'
          : 'Игра "${room.title}" отменена',
      additionalData: reason != null ? {'reason': reason} : null,
    );
  }

  static GameNotificationModel playerJoined({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required UserModel player,
    required List<String> recipientIds,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: recipientIds,
      type: GameNotificationType.playerJoined,
      title: '👋 Новый участник',
      message: '${player.name} присоединился к игре "${room.title}"',
      additionalData: {
        'playerId': player.id,
        'playerName': player.name,
      },
    );
  }

  static GameNotificationModel playerLeft({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required UserModel player,
    required List<String> recipientIds,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: recipientIds,
      type: GameNotificationType.playerLeft,
      title: '👋 Участник покинул игру',
      message: '${player.name} покинул игру "${room.title}"',
      additionalData: {
        'playerId': player.id,
        'playerName': player.name,
      },
    );
  }

  static GameNotificationModel evaluationRequired({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required List<String> recipientIds,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: recipientIds,
      type: GameNotificationType.evaluationRequired,
      title: '⭐ Оцените игру!',
      message: 'Пожалуйста, оцените участников игры "${room.title}"',
    );
  }

  static GameNotificationModel winnerSelectionRequired({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required List<String> recipientIds,
    bool? isTeamMode,
    int? playersToSelect,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: recipientIds,
      type: GameNotificationType.winnerSelectionRequired,
      title: '🏆 Выберите команду-победителя',
      message: 'Игра "${room.title}" завершена. Выберите команду-победителя и оцените игроков.',
      additionalData: {
        if (isTeamMode != null) 'isTeamMode': isTeamMode.toString(),
        if (playersToSelect != null) 'playersToSelect': playersToSelect.toString(),
      },
    );
  }

  static GameNotificationModel playerEvaluated({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required UserModel evaluatedPlayer,
    required double rating,
    required String evaluatorName,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: [evaluatedPlayer.id],
      type: GameNotificationType.playerEvaluated,
      title: '⭐ Вас оценили!',
      message: '$evaluatorName оценил вашу игру в "${room.title}" на $rating/5',
      additionalData: {
        'rating': rating,
        'evaluatorName': evaluatorName,
        'playerId': evaluatedPlayer.id,
        'playerName': evaluatedPlayer.name,
      },
    );
  }

  static GameNotificationModel activityCheck({
    required String id,
    required String teamId,
    required String teamName,
    required List<String> recipientIds,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: teamId, // Используем teamId как roomId для активности команды
      roomTitle: teamName,
      organizerId: 'system',
      organizerName: 'Система',
      recipientIds: recipientIds,
      type: GameNotificationType.activityCheck,
      title: '📋 Проверка активности команды',
      message: 'Подтвердите участие в команде "$teamName"',
      createdAt: DateTime.now(),
      additionalData: {
        'teamId': teamId,
        'teamName': teamName,
      },
    );
  }

  static GameNotificationModel teamVictory({
    required String id,
    required RoomModel room,
    required UserModel organizer,
    required String winnerTeamName,
    required List<String> teamMembers,
  }) {
    return _createGameNotification(
      id: id,
      roomId: room.id,
      roomTitle: room.title,
      organizerId: organizer.id,
      organizerName: organizer.name,
      recipientIds: teamMembers,
      type: GameNotificationType.gameEnded, // Используем существующий тип
      title: '🎉 Поздравляем с победой!',
      message: 'Ваша команда "$winnerTeamName" выиграла игру "${room.title}"!',
      additionalData: {
        'winner': winnerTeamName,
        'victory': true,
      },
    );
  }
} 