import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String roomId;
  final List<String> members;
  final int maxMembers;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Новые поля для постоянных команд
  final String? ownerId; // ID владельца команды (организатора)
  final String? photoUrl; // Аватар команды
  final bool isGameTeam; // true - команда для конкретной игры, false - постоянная команда пользователя

  TeamModel({
    required this.id,
    required this.name,
    required this.roomId,
    this.members = const [],
    this.maxMembers = 6, // По умолчанию 6 игроков в команде
    required this.createdAt,
    this.updatedAt,
    this.ownerId,
    this.photoUrl,
    this.isGameTeam = true, // По умолчанию команда для игры
  });

  TeamModel copyWith({
    String? name,
    List<String>? members,
    int? maxMembers,
    DateTime? updatedAt,
    String? ownerId,
    String? photoUrl,
    bool? isGameTeam,
  }) {
    return TeamModel(
      id: id,
      name: name ?? this.name,
      roomId: roomId,
      members: members ?? this.members,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerId: ownerId ?? this.ownerId,
      photoUrl: photoUrl ?? this.photoUrl,
      isGameTeam: isGameTeam ?? this.isGameTeam,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'roomId': roomId,
      'members': members,
      'maxMembers': maxMembers,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'ownerId': ownerId,
      'photoUrl': photoUrl,
      'isGameTeam': isGameTeam,
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    return TeamModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      roomId: map['roomId'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      maxMembers: map['maxMembers'] ?? 6,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null && map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
      ownerId: map['ownerId'],
      photoUrl: map['photoUrl'],
      isGameTeam: map['isGameTeam'] ?? true,
    );
  }

  bool get isFull => members.length >= maxMembers;
  int get availableSlots => maxMembers - members.length;
  bool get isUserTeam => !isGameTeam; // Постоянная команда пользователя
} 