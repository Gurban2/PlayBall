import 'package:cloud_firestore/cloud_firestore.dart';

class TeamApplicationModel {
  final String id;
  final String teamId;
  final String teamName;
  final String fromUserId;
  final String fromUserName;
  final String toUserId; // владелец команды
  final String status; // 'pending', 'accepted', 'declined'
  final String? message; // сообщение от пользователя
  final DateTime createdAt;
  final DateTime? respondedAt;

  TeamApplicationModel({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
  });

  factory TeamApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamApplicationModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      teamName: data['teamName'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      toUserId: data['toUserId'] ?? '',
      status: data['status'] ?? 'pending',
      message: data['message'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null 
          ? (data['respondedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'status': status,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  TeamApplicationModel copyWith({
    String? id,
    String? teamId,
    String? teamName,
    String? fromUserId,
    String? fromUserName,
    String? toUserId,
    String? status,
    String? message,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return TeamApplicationModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserId: toUserId ?? this.toUserId,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
} 