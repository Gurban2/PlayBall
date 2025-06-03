import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerEvaluationModel {
  final String id;
  final String gameId;
  final String organizerId;
  final String playerId;
  final int points; // Количество баллов (обычно 1)
  final String? comment; // Комментарий организатора
  final DateTime createdAt;

  const PlayerEvaluationModel({
    required this.id,
    required this.gameId,
    required this.organizerId,
    required this.playerId,
    required this.points,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'organizerId': organizerId,
      'playerId': playerId,
      'points': points,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PlayerEvaluationModel.fromMap(Map<String, dynamic> map) {
    return PlayerEvaluationModel(
      id: map['id'] ?? '',
      gameId: map['gameId'] ?? '',
      organizerId: map['organizerId'] ?? '',
      playerId: map['playerId'] ?? '',
      points: map['points'] ?? 0,
      comment: map['comment'],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
} 