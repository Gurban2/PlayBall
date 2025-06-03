import 'package:cloud_firestore/cloud_firestore.dart';

enum UnifiedNotificationType {
  friendRequest,
  teamInvitation,
  teamExclusion,
}

enum UnifiedNotificationStatus {
  pending,
  accepted,
  declined,
  read,
}

class UnifiedNotificationModel {
  final String id;
  final String toUserId;
  final UnifiedNotificationType type;
  final UnifiedNotificationStatus status;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final bool isRead;
  
  // Данные для друзей
  final String? fromUserId;
  final String? fromUserName;
  final String? fromUserPhotoUrl;
  final String? toUserName;
  final String? toUserPhotoUrl;
  
  // Данные для команд
  final String? teamId;
  final String? teamName;
  final String? replacedUserId;
  final String? replacedUserName;
  final String? replacedByUserId;
  final String? replacedByUserName;

  UnifiedNotificationModel({
    required this.id,
    required this.toUserId,
    required this.type,
    this.status = UnifiedNotificationStatus.pending,
    required this.title,
    required this.message,
    required this.createdAt,
    this.respondedAt,
    this.isRead = false,
    this.fromUserId,
    this.fromUserName,
    this.fromUserPhotoUrl,
    this.toUserName,
    this.toUserPhotoUrl,
    this.teamId,
    this.teamName,
    this.replacedUserId,
    this.replacedUserName,
    this.replacedByUserId,
    this.replacedByUserName,
  });

  // Конструктор для заявки в друзья
  factory UnifiedNotificationModel.friendRequest({
    required String id,
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String toUserName,
    String? fromUserPhotoUrl,
    String? toUserPhotoUrl,
    required DateTime createdAt,
    UnifiedNotificationStatus status = UnifiedNotificationStatus.pending,
    DateTime? respondedAt,
  }) {
    return UnifiedNotificationModel(
      id: id,
      toUserId: toUserId,
      type: UnifiedNotificationType.friendRequest,
      status: status,
      title: 'Заявка в друзья',
      message: '$fromUserName хочет добавить вас в друзья',
      createdAt: createdAt,
      respondedAt: respondedAt,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserPhotoUrl: fromUserPhotoUrl,
      toUserName: toUserName,
      toUserPhotoUrl: toUserPhotoUrl,
    );
  }

  // Конструктор для приглашения в команду
  factory UnifiedNotificationModel.teamInvitation({
    required String id,
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String toUserName,
    required String teamId,
    required String teamName,
    String? fromUserPhotoUrl,
    String? toUserPhotoUrl,
    String? replacedUserId,
    String? replacedUserName,
    required DateTime createdAt,
    UnifiedNotificationStatus status = UnifiedNotificationStatus.pending,
    DateTime? respondedAt,
  }) {
    final message = replacedUserId != null
        ? '$fromUserName приглашает вас в команду "$teamName" (заменить ${replacedUserName ?? "игрока"})'
        : '$fromUserName приглашает вас в команду "$teamName"';
    
    return UnifiedNotificationModel(
      id: id,
      toUserId: toUserId,
      type: UnifiedNotificationType.teamInvitation,
      status: status,
      title: 'Приглашение в команду',
      message: message,
      createdAt: createdAt,
      respondedAt: respondedAt,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserPhotoUrl: fromUserPhotoUrl,
      toUserName: toUserName,
      toUserPhotoUrl: toUserPhotoUrl,
      teamId: teamId,
      teamName: teamName,
      replacedUserId: replacedUserId,
      replacedUserName: replacedUserName,
    );
  }

  // Конструктор для исключения из команды
  factory UnifiedNotificationModel.teamExclusion({
    required String id,
    required String toUserId,
    required String teamId,
    required String teamName,
    required String replacedByUserId,
    required String replacedByUserName,
    required DateTime createdAt,
  }) {
    return UnifiedNotificationModel(
      id: id,
      toUserId: toUserId,
      type: UnifiedNotificationType.teamExclusion,
      status: UnifiedNotificationStatus.read,
      title: 'Исключение из команды',
      message: 'Вы были исключены из команды "$teamName" и заменены игроком $replacedByUserName',
      createdAt: createdAt,
      isRead: false,
      teamId: teamId,
      teamName: teamName,
      replacedByUserId: replacedByUserId,
      replacedByUserName: replacedByUserName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'toUserId': toUserId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'isRead': isRead,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'toUserName': toUserName,
      'toUserPhotoUrl': toUserPhotoUrl,
      'teamId': teamId,
      'teamName': teamName,
      'replacedUserId': replacedUserId,
      'replacedUserName': replacedUserName,
      'replacedByUserId': replacedByUserId,
      'replacedByUserName': replacedByUserName,
    };
  }

  factory UnifiedNotificationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UnifiedNotificationModel(
      id: documentId,
      toUserId: map['toUserId'] ?? '',
      type: UnifiedNotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => UnifiedNotificationType.friendRequest,
      ),
      status: UnifiedNotificationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => UnifiedNotificationStatus.pending,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null && map['respondedAt'] is Timestamp
          ? (map['respondedAt'] as Timestamp).toDate() 
          : null,
      isRead: map['isRead'] ?? false,
      fromUserId: map['fromUserId'],
      fromUserName: map['fromUserName'],
      fromUserPhotoUrl: map['fromUserPhotoUrl'],
      toUserName: map['toUserName'],
      toUserPhotoUrl: map['toUserPhotoUrl'],
      teamId: map['teamId'],
      teamName: map['teamName'],
      replacedUserId: map['replacedUserId'],
      replacedUserName: map['replacedUserName'],
      replacedByUserId: map['replacedByUserId'],
      replacedByUserName: map['replacedByUserName'],
    );
  }

  String get displayName {
    switch (type) {
      case UnifiedNotificationType.friendRequest:
        return fromUserName ?? 'Неизвестный пользователь';
      case UnifiedNotificationType.teamInvitation:
        return fromUserName ?? 'Неизвестный организатор';
      case UnifiedNotificationType.teamExclusion:
        return 'Система';
    }
  }

  String get displayPhotoUrl {
    switch (type) {
      case UnifiedNotificationType.friendRequest:
        return fromUserPhotoUrl ?? '';
      case UnifiedNotificationType.teamInvitation:
        return fromUserPhotoUrl ?? '';
      case UnifiedNotificationType.teamExclusion:
        return '';
    }
  }

  bool get isIncoming => true; // Все уведомления считаются входящими для получателя
  
  bool get canRespond => type != UnifiedNotificationType.teamExclusion && status == UnifiedNotificationStatus.pending;
} 