import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  user,
  organizer,
  admin,
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final List<String> teams;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int rating;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.role = UserRole.user,
    required this.createdAt,
    this.lastLogin,
    this.teams = const [],
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.rating = 0,
  });

  UserModel copyWith({
    String? name,
    String? photoUrl,
    UserRole? role,
    DateTime? lastLogin,
    List<String>? teams,
    int? gamesPlayed,
    int? wins,
    int? losses,
    int? rating,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      teams: teams ?? this.teams,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'teams': teams,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'losses': losses,
      'rating': rating,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      role: _roleFromString(map['role'] as String?),
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLogin: map['lastLogin'] != null && map['lastLogin'] is Timestamp
          ? (map['lastLogin'] as Timestamp).toDate()
          : null,
      teams: List<String>.from(map['teams'] ?? []),
      gamesPlayed: map['gamesPlayed'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      rating: map['rating'] ?? 0,
    );
  }

  static UserRole _roleFromString(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'organizer':
        return UserRole.organizer;
      case 'user':
      default:
        return UserRole.user;
    }
  }
} 