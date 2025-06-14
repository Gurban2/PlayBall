import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы уведомлений связанных с играми
enum GameNotificationType {
  gameCreated,      // Создана новая игра
  gameUpdated,      // Изменения в игре
  gameStarting,     // Игра скоро начнется
  gameStarted,      // Игра началась
  gameEnded,        // Игра завершена
  gameCancelled,    // Игра отменена
  playerJoined,     // Игрок присоединился
  playerLeft,       // Игрок покинул игру
  teamFormed,       // Команда сформирована
  teamChanged,      // Изменения в команде
  evaluationRequired, // Требуется оценка игроков
  winnerSelectionRequired, // Требуется выбор команды-победителя
  playerEvaluated,  // Игрок получил оценку
  activityCheck,    // Проверка активности команды
  activityCheckCompleted, // Проверка готовности завершена
}

/// Модель уведомлений о играх
class GameNotificationModel {
  final String id;
  final String roomId;
  final String roomTitle;
  final String organizerId;
  final String organizerName;
  final List<String> recipientIds;
  final GameNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? scheduledDateTime;
  final Map<String, dynamic>? additionalData;
  final bool isRead;

  GameNotificationModel({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.organizerId,
    required this.organizerName,
    required this.recipientIds,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.scheduledDateTime,
    this.additionalData,
    this.isRead = false,
  });

  // Фабричные конструкторы для разных типов уведомлений

  /// Уведомление о создании новой игры
  factory GameNotificationModel.gameCreated({
    required String id,
    required String roomId,
    required String roomTitle,
    required String organizerId,
    required String organizerName,
    required List<String> recipientIds,
    required DateTime scheduledDateTime,
    required String location,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: roomId,
      roomTitle: roomTitle,
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: recipientIds,
      type: GameNotificationType.gameCreated,
      title: '🏐 Новая игра!',
      message: '$organizerName создал игру "$roomTitle"',
      createdAt: DateTime.now(),
      scheduledDateTime: scheduledDateTime,
      additionalData: {'location': location},
    );
  }

  /// Уведомление об изменениях в игре
  factory GameNotificationModel.gameUpdated({
    required String id,
    required String roomId,
    required String roomTitle,
    required String organizerId,
    required String organizerName,
    required List<String> recipientIds,
    required String changes,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: roomId,
      roomTitle: roomTitle,
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: recipientIds,
      type: GameNotificationType.gameUpdated,
      title: '📝 Изменения в игре',
      message: 'Игра "$roomTitle" была изменена: $changes',
      createdAt: DateTime.now(),
    );
  }

  /// Уведомление о скором начале игры
  factory GameNotificationModel.gameStarting({
    required String id,
    required String roomId,
    required String roomTitle,
    required String organizerId,
    required String organizerName,
    required List<String> recipientIds,
    required int minutesLeft,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: roomId,
      roomTitle: roomTitle,
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: recipientIds,
      type: GameNotificationType.gameStarting,
      title: '⏰ Игра скоро начнется!',
      message: 'Игра "$roomTitle" начнется через $minutesLeft мин.',
      createdAt: DateTime.now(),
      additionalData: {'minutesLeft': minutesLeft},
    );
  }

  /// Уведомление о начале игры
  factory GameNotificationModel.gameStarted({
    required String id,
    required String roomId,
    required String roomTitle,
    required String organizerId,
    required String organizerName,
    required List<String> recipientIds,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: roomId,
      roomTitle: roomTitle,
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: recipientIds,
      type: GameNotificationType.gameStarted,
      title: '🏐 Игра началась!',
      message: 'Игра "$roomTitle" началась. Удачи!',
      createdAt: DateTime.now(),
    );
  }

  /// Уведомление о завершении игры
  factory GameNotificationModel.gameEnded({
    required String id,
    required String roomId,
    required String roomTitle,
    required String organizerId,
    required String organizerName,
    required List<String> recipientIds,
    String? winnerTeamName,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: roomId,
      roomTitle: roomTitle,
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: recipientIds,
      type: GameNotificationType.gameEnded,
      title: '🏆 Игра завершена!',
      message: winnerTeamName != null
          ? 'Игра "$roomTitle" завершена. Победила команда: $winnerTeamName!'
          : 'Игра "$roomTitle" завершена.',
      createdAt: DateTime.now(),
      additionalData: winnerTeamName != null ? {'winner': winnerTeamName} : null,
    );
  }

  /// Уведомление об отмене игры
  factory GameNotificationModel.gameCancelled({
    required String id,
    required String roomId,
    required String roomTitle,
    required String organizerId,
    required String organizerName,
    required List<String> recipientIds,
    String? reason,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: roomId,
      roomTitle: roomTitle,
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: recipientIds,
      type: GameNotificationType.gameCancelled,
      title: '❌ Игра отменена',
      message: reason != null
          ? 'Игра "$roomTitle" отменена. Причина: $reason'
          : 'Игра "$roomTitle" отменена.',
      createdAt: DateTime.now(),
      additionalData: reason != null ? {'reason': reason} : null,
    );
  }

  /// Уведомление о присоединении игрока
  factory GameNotificationModel.playerJoined({
    required String id,
    required String roomId,
    required String roomTitle,
    required String organizerId,
    required String organizerName,
    required List<String> recipientIds,
    required String playerName,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: roomId,
      roomTitle: roomTitle,
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: recipientIds,
      type: GameNotificationType.playerJoined,
      title: '👋 Новый игрок',
      message: '$playerName присоединился к игре "$roomTitle"',
      createdAt: DateTime.now(),
      additionalData: {'playerName': playerName},
    );
  }

  /// Уведомление о необходимости оценки игроков
  factory GameNotificationModel.evaluationRequired({
    required String id,
    required String roomId,
    required String roomTitle,
    required String organizerId,
    required String organizerName,
    required List<String> recipientIds,
    required String gameMode,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: roomId,
      roomTitle: roomTitle,
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: recipientIds,
      type: GameNotificationType.evaluationRequired,
      title: '⭐ Оцените игроков',
      message: 'Игра "$roomTitle" завершена. Пожалуйста, оцените игроков.',
      createdAt: DateTime.now(),
      additionalData: {'gameMode': gameMode},
    );
  }

  /// Уведомление о необходимости выбора команды-победителя
  factory GameNotificationModel.winnerSelectionRequired({
    required String id,
    required String roomId,
    required String roomTitle,
    required String organizerId,
    required String organizerName,
    required List<String> recipientIds,
    required bool isTeamMode,
    required int playersToSelect,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: roomId,
      roomTitle: roomTitle,
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: recipientIds,
      type: GameNotificationType.winnerSelectionRequired,
      title: '🏆 Выберите команду-победителя',
      message: 'Игра "$roomTitle" завершена. Выберите команду-победителя и оцените игроков.',
      createdAt: DateTime.now(),
      additionalData: {
        'isTeamMode': isTeamMode.toString(),
        'playersToSelect': playersToSelect.toString(),
      },
    );
  }

  /// Уведомление о проверке активности команды
  factory GameNotificationModel.activityCheck({
    required String id,
    required String teamId,
    required String teamName,
    required String organizerId,
    required String organizerName,
    required String checkId,
    required List<String> recipientIds,
  }) {
    return GameNotificationModel(
      id: id,
      roomId: teamId, // Используем teamId как roomId
      roomTitle: teamName, // Используем teamName как roomTitle
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: recipientIds,
      type: GameNotificationType.activityCheck,
      title: '⚡ Проверка готовности команды',
      message: '$organizerName спрашивает, все ли готовы сегодня к игре? Нажмите "Готов", чтобы показать свою активность.',
      createdAt: DateTime.now(),
      additionalData: {
        'checkId': checkId,
        'teamId': teamId,
        'teamName': teamName,
      },
    );
  }

  /// Фабричный конструктор для уведомления о завершении проверки готовности
  factory GameNotificationModel.activityCheckCompleted({
    required String id,
    required String teamId,
    required String teamName,
    required String organizerId,
    required String organizerName,
    required String checkId,
    required int readyCount,
    required int notReadyCount,
    required int totalCount,
  }) {
    String resultMessage;
    if (readyCount == totalCount) {
      resultMessage = '🎉 Все игроки команды готовы! ($readyCount/$totalCount)';
    } else if (notReadyCount > 0) {
      resultMessage = '📊 Готовы: $readyCount, не готовы: $notReadyCount, не ответили: ${totalCount - readyCount - notReadyCount} из $totalCount';
    } else {
      resultMessage = '📊 Готовы: $readyCount из $totalCount игроков. ${totalCount - readyCount} не ответили.';
    }

    return GameNotificationModel(
      id: id,
      roomId: teamId,
      roomTitle: teamName,
      organizerId: organizerId,
      organizerName: organizerName,
      recipientIds: [organizerId], // Только организатору
      type: GameNotificationType.activityCheckCompleted,
      title: '✅ Проверка готовности завершена',
      message: resultMessage,
      createdAt: DateTime.now(),
      additionalData: {
        'checkId': checkId,
        'teamId': teamId,
        'teamName': teamName,
        'readyCount': readyCount,
        'notReadyCount': notReadyCount,
        'totalCount': totalCount,
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'roomTitle': roomTitle,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'recipientIds': recipientIds,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledDateTime': scheduledDateTime != null 
          ? Timestamp.fromDate(scheduledDateTime!) 
          : null,
      'additionalData': additionalData,
      'isRead': isRead,
    };
  }

  factory GameNotificationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GameNotificationModel(
      id: documentId,
      roomId: map['roomId'] ?? '',
      roomTitle: map['roomTitle'] ?? '',
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      recipientIds: List<String>.from(map['recipientIds'] ?? []),
      type: GameNotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => GameNotificationType.gameCreated,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledDateTime: (map['scheduledDateTime'] as Timestamp?)?.toDate(),
      additionalData: map['additionalData'] != null 
          ? Map<String, dynamic>.from(map['additionalData']) 
          : null,
      isRead: map['isRead'] ?? false,
    );
  }

  /// Возвращает иконку для типа уведомления
  String get icon {
    switch (type) {
      case GameNotificationType.gameCreated:
        return '🏐';
      case GameNotificationType.gameUpdated:
        return '📝';
      case GameNotificationType.gameStarting:
        return '⏰';
      case GameNotificationType.gameStarted:
        return '🚀';
      case GameNotificationType.gameEnded:
        return '🏆';
      case GameNotificationType.gameCancelled:
        return '❌';
      case GameNotificationType.playerJoined:
        return '👋';
      case GameNotificationType.playerLeft:
        return '👋';
      case GameNotificationType.teamFormed:
        return '👥';
      case GameNotificationType.teamChanged:
        return '🔄';
      case GameNotificationType.evaluationRequired:
        return '⭐';
      case GameNotificationType.winnerSelectionRequired:
        return '🏆';
      case GameNotificationType.playerEvaluated:
        return '⭐';
      case GameNotificationType.activityCheck:
        return '⚡';
      case GameNotificationType.activityCheckCompleted:
        return '✅';
    }
  }

  /// Возвращает цвет для типа уведомления
  String get colorHex {
    switch (type) {
      case GameNotificationType.gameCreated:
        return '#4CAF50'; // зеленый
      case GameNotificationType.gameUpdated:
        return '#2196F3'; // синий
      case GameNotificationType.gameStarting:
        return '#FF9800'; // оранжевый
      case GameNotificationType.gameStarted:
        return '#8BC34A'; // светло-зеленый
      case GameNotificationType.gameEnded:
        return '#9C27B0'; // фиолетовый
      case GameNotificationType.gameCancelled:
        return '#F44336'; // красный
      case GameNotificationType.playerJoined:
        return '#00BCD4'; // голубой
      case GameNotificationType.playerLeft:
        return '#607D8B'; // серый
      case GameNotificationType.teamFormed:
        return '#3F51B5'; // индиго
      case GameNotificationType.teamChanged:
        return '#FF5722'; // оранжево-красный
      case GameNotificationType.evaluationRequired:
        return '#FFC107'; // желтый (золотой)
      case GameNotificationType.winnerSelectionRequired:
        return '#FF6F00'; // оранжевый (для выбора победителя)
      case GameNotificationType.playerEvaluated:
        return '#FFC107'; // желтый (золотой)
      case GameNotificationType.activityCheck:
        return '#9E9E9E'; // серый (для проверки активности)
      case GameNotificationType.activityCheckCompleted:
        return '#4CAF50'; // зеленый (для завершения проверки)
    }
  }

  GameNotificationModel copyWith({
    String? id,
    String? roomId,
    String? roomTitle,
    String? organizerId,
    String? organizerName,
    List<String>? recipientIds,
    GameNotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    DateTime? scheduledDateTime,
    Map<String, dynamic>? additionalData,
    bool? isRead,
  }) {
    return GameNotificationModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      roomTitle: roomTitle ?? this.roomTitle,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      recipientIds: recipientIds ?? this.recipientIds,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      additionalData: additionalData ?? this.additionalData,
      isRead: isRead ?? this.isRead,
    );
  }
} 