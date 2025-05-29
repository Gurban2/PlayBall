import 'package:cloud_firestore/cloud_firestore.dart';

class UserTeamModel {
  final String id;
  final String name;
  final String ownerId; // ID организатора команды
  final List<String> members; // Включая организатора
  final int maxMembers; // Максимум 6 человек
  final String? photoUrl; // Аватар команды
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserTeamModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.members = const [],
    this.maxMembers = 6,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  UserTeamModel copyWith({
    String? name,
    List<String>? members,
    int? maxMembers,
    String? photoUrl,
    DateTime? updatedAt,
  }) {
    return UserTeamModel(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      members: members ?? this.members,
      maxMembers: maxMembers ?? this.maxMembers,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'members': members,
      'maxMembers': maxMembers,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory UserTeamModel.fromMap(Map<String, dynamic> map) {
    return UserTeamModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      maxMembers: map['maxMembers'] ?? 6,
      photoUrl: map['photoUrl'],
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
  bool get hasOwner => members.contains(ownerId);
} 