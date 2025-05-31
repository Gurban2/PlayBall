import 'package:cloud_firestore/cloud_firestore.dart';

enum TeamInvitationStatus {
  pending,
  accepted,
  declined,
}

class TeamInvitationModel {
  final String id;
  final String teamId;
  final String teamName;
  final String fromUserId; // ID организатора команды
  final String toUserId; // ID приглашаемого пользователя
  final String fromUserName;
  final String toUserName;
  final String? fromUserPhotoUrl;
  final String? toUserPhotoUrl;
  final TeamInvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? replacedUserId; // ID пользователя, которого заменяют (если есть)
  final String? replacedUserName;

  TeamInvitationModel({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.toUserName,
    this.fromUserPhotoUrl,
    this.toUserPhotoUrl,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.replacedUserId,
    this.replacedUserName,
  });

  TeamInvitationModel copyWith({
    String? id,
    String? teamId,
    String? teamName,
    String? fromUserId,
    String? toUserId,
    String? fromUserName,
    String? toUserName,
    String? fromUserPhotoUrl,
    String? toUserPhotoUrl,
    TeamInvitationStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? replacedUserId,
    String? replacedUserName,
  }) {
    return TeamInvitationModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
      fromUserPhotoUrl: fromUserPhotoUrl ?? this.fromUserPhotoUrl,
      toUserPhotoUrl: toUserPhotoUrl ?? this.toUserPhotoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      replacedUserId: replacedUserId ?? this.replacedUserId,
      replacedUserName: replacedUserName ?? this.replacedUserName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'teamName': teamName,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserName': fromUserName,
      'toUserName': toUserName,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'toUserPhotoUrl': toUserPhotoUrl,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'replacedUserId': replacedUserId,
      'replacedUserName': replacedUserName,
    };
  }

  factory TeamInvitationModel.fromMap(Map<String, dynamic> map, String id) {
    return TeamInvitationModel(
      id: id,
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      toUserName: map['toUserName'] ?? '',
      fromUserPhotoUrl: map['fromUserPhotoUrl'],
      toUserPhotoUrl: map['toUserPhotoUrl'],
      status: _statusFromString(map['status']),
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null && map['respondedAt'] is Timestamp
          ? (map['respondedAt'] as Timestamp).toDate() 
          : null,
      replacedUserId: map['replacedUserId'],
      replacedUserName: map['replacedUserName'],
    );
  }

  static TeamInvitationStatus _statusFromString(String? status) {
    switch (status) {
      case 'accepted':
        return TeamInvitationStatus.accepted;
      case 'declined':
        return TeamInvitationStatus.declined;
      case 'pending':
      default:
        return TeamInvitationStatus.pending;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TeamInvitationStatus.pending:
        return 'Ожидает ответа';
      case TeamInvitationStatus.accepted:
        return 'Принято';
      case TeamInvitationStatus.declined:
        return 'Отклонено';
    }
  }
} 