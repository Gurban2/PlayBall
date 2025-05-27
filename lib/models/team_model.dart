import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String roomId;
  final List<String> members;
  final int maxMembers;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TeamModel({
    required this.id,
    required this.name,
    required this.roomId,
    this.members = const [],
    this.maxMembers = 6, // По умолчанию 6 игроков в команде
    required this.createdAt,
    this.updatedAt,
  });

  TeamModel copyWith({
    String? name,
    List<String>? members,
    int? maxMembers,
    DateTime? updatedAt,
  }) {
    return TeamModel(
      id: id,
      name: name ?? this.name,
      roomId: roomId,
      members: members ?? this.members,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    );
  }

  bool get isFull => members.length >= maxMembers;
  int get availableSlots => maxMembers - members.length;
} 