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
  
  // Поля для системы баллов команды
  final int teamScore; // Общие баллы команды
  final int gamesWon; // Выигранные игры
  final int gamesPlayed; // Всего игр сыграно
  final int tournamentPoints; // Баллы в турнирах
  final List<String> achievements; // Достижения команды ['first_win', 'winning_streak_5', etc.]

  UserTeamModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.members = const [],
    this.maxMembers = 6,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
    // Новые поля для баллов с значениями по умолчанию
    this.teamScore = 0,
    this.gamesWon = 0,
    this.gamesPlayed = 0,
    this.tournamentPoints = 0,
    this.achievements = const [],
  });

  UserTeamModel copyWith({
    String? name,
    List<String>? members,
    int? maxMembers,
    String? photoUrl,
    DateTime? updatedAt,
    int? teamScore,
    int? gamesWon,
    int? gamesPlayed,
    int? tournamentPoints,
    List<String>? achievements,
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
      teamScore: teamScore ?? this.teamScore,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      tournamentPoints: tournamentPoints ?? this.tournamentPoints,
      achievements: achievements ?? this.achievements,
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
      'teamScore': teamScore,
      'gamesWon': gamesWon,
      'gamesPlayed': gamesPlayed,
      'tournamentPoints': tournamentPoints,
      'achievements': achievements,
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
      teamScore: map['teamScore'] ?? 0,
      gamesWon: map['gamesWon'] ?? 0,
      gamesPlayed: map['gamesPlayed'] ?? 0,
      tournamentPoints: map['tournamentPoints'] ?? 0,
      achievements: List<String>.from(map['achievements'] ?? []),
    );
  }

  bool get isFull => members.length >= maxMembers;
  int get availableSlots => maxMembers - members.length;
  bool get hasOwner => members.contains(ownerId);
  
  // Вычисляемые свойства для баллов команды
  double get winRate => gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0.0;
  int get gamesLost => gamesPlayed - gamesWon;
  
  /// Общий рейтинг команды (баллы + винрейт)
  double get teamRating {
    if (gamesPlayed == 0) return 0.0;
    return (teamScore * 0.6) + (winRate * 0.4); // 60% баллы, 40% винрейт
  }
  
  /// Уровень команды на основе количества игр и побед
  String get teamLevel {
    if (gamesPlayed < 5) return 'Новичок';
    if (gamesPlayed < 15) return 'Любитель';
    if (gamesPlayed < 30) return 'Опытная';
    if (gamesPlayed < 50) return 'Профессиональная';
    return 'Элитная';
  }
  
  /// Проверяет, есть ли серия побед
  bool get hasWinningStreak => achievements.any((a) => a.startsWith('winning_streak_'));
  
  /// Получить количество побед в серии
  int get currentWinningStreak {
    final streakAchievement = achievements
        .where((a) => a.startsWith('winning_streak_'))
        .toList();
    
    if (streakAchievement.isEmpty) return 0;
    
    // Берем максимальную серию
    return streakAchievement
        .map((a) => int.tryParse(a.split('_').last) ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }
} 