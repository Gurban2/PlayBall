import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  user,
  organizer,
  admin,
}

enum PlayerStatus {
  lookingForGame,
  unavailable,
  freeTonight,
}

class PlayerRef {
  final String id;
  final String name;
  final int gamesPlayedTogether;
  final int winsTogetherCount;
  final double winRateTogether;

  const PlayerRef({
    required this.id,
    required this.name,
    required this.gamesPlayedTogether,
    required this.winsTogetherCount,
    required this.winRateTogether,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gamesPlayedTogether': gamesPlayedTogether,
      'winsTogetherCount': winsTogetherCount,
      'winRateTogether': winRateTogether,
    };
  }

  factory PlayerRef.fromMap(Map<String, dynamic> map) {
    return PlayerRef(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      gamesPlayedTogether: map['gamesPlayedTogether'] ?? 0,
      winsTogetherCount: map['winsTogetherCount'] ?? 0,
      winRateTogether: (map['winRateTogether'] ?? 0.0).toDouble(),
    );
  }
}

class GameRef {
  final String id;
  final String title;
  final String location;
  final DateTime date;
  final String result; // 'win', 'loss', 'cancelled'
  final List<String> teammates;

  const GameRef({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.result,
    required this.teammates,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': Timestamp.fromDate(date),
      'result': result,
      'teammates': teammates,
    };
  }

  factory GameRef.fromMap(Map<String, dynamic> map) {
    return GameRef(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      date: map['date'] is Timestamp 
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      result: map['result'] ?? '',
      teammates: List<String>.from(map['teammates'] ?? []),
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String bio; // НОВОЕ: описание "О себе"
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Поля для статистики
  final int gamesPlayed;
  final int wins;
  final int losses;
  final double rating; // Рейтинг от 0.0 до 5.0 звезд
  final int totalReviews; // Количество отзывов
  final String skillLevel; // Уровень игры: 'Начинающий', 'Средний', 'Продвинутый', 'Профессиональный'
  final List<String> preferredLocations; // Предпочитаемые города/районы
  final bool isVerified; // Верифицированный игрок
  final DateTime? lastActiveAt; // Последняя активность

  // НОВЫЕ ПОЛЯ
  final int organizerPoints; // Баллы от организаторов
  final int totalScore; // Итоговая система баллов
  final List<String> achievements; // Список достижений
  final PlayerStatus status; // Статус доступности
  final List<String> activityFeed; // Лента активности (последние 20 событий)
  final List<PlayerRef> bestTeammates; // Лучшие партнеры (топ-5)
  final List<GameRef> recentGames; // Последние 5 игр
  final List<String> friends; // Список ID друзей
  
  // ПОЛЯ ДЛЯ КОМАНДЫ
  final String? teamId; // ID постоянной команды пользователя
  final String? teamName; // Название команды
  final bool isTeamCaptain; // Является ли капитаном команды

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.phoneNumber,
    this.dateOfBirth,
    this.bio = '',
    required this.createdAt,
    this.updatedAt,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.skillLevel = 'Начинающий',
    this.preferredLocations = const [],
    this.isVerified = false,
    this.lastActiveAt,
    // Новые поля с значениями по умолчанию
    this.organizerPoints = 0,
    this.totalScore = 0,
    this.achievements = const [],
    this.status = PlayerStatus.lookingForGame,
    this.activityFeed = const [],
    this.bestTeammates = const [],
    this.recentGames = const [],
    this.friends = const [],
    // Поля команды
    this.teamId,
    this.teamName,
    this.isTeamCaptain = false,
  });

  // Вычисляемые свойства
  double get winRate => gamesPlayed > 0 ? (wins / gamesPlayed) * 100 : 0.0;
  
  /// Рейтинг на основе винрейта (0.0 - 5.0 звезд)
  double get calculatedRating {
    if (gamesPlayed == 0) return 2.5; // Средний рейтинг для новых игроков
    return (winRate / 20).clamp(0.0, 5.0); // winRate 0-100% преобразуем в 0-5 звезд
  }
  
  bool get hasPlayedGames => gamesPlayed > 0;
  String get experienceLevel {
    if (gamesPlayed < 5) return 'Новичок';
    if (gamesPlayed < 20) return 'Любитель';
    if (gamesPlayed < 50) return 'Опытный';
    return 'Эксперт';
  }

  // НОВЫЕ вычисляемые свойства
  List<GameRef> get upcomingGames {
    // Будет заполняться отдельным запросом к комнатам
    return [];
  }

  String get statusDisplayName {
    switch (status) {
      case PlayerStatus.lookingForGame:
        return 'Ищу игру';
      case PlayerStatus.unavailable:
        return 'Недоступен';
      case PlayerStatus.freeTonight:
        return 'Свободен сегодня вечером';
    }
  }

  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? photoUrl,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? bio,
    DateTime? updatedAt,
    int? gamesPlayed,
    int? wins,
    int? losses,
    double? rating,
    int? totalReviews,
    String? skillLevel,
    List<String>? preferredLocations,
    bool? isVerified,
    DateTime? lastActiveAt,
    int? organizerPoints,
    int? totalScore,
    List<String>? achievements,
    PlayerStatus? status,
    List<String>? activityFeed,
    List<PlayerRef>? bestTeammates,
    List<GameRef>? recentGames,
    List<String>? friends,
    String? teamId,
    String? teamName,
    bool? isTeamCaptain,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      skillLevel: skillLevel ?? this.skillLevel,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      isVerified: isVerified ?? this.isVerified,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      organizerPoints: organizerPoints ?? this.organizerPoints,
      totalScore: totalScore ?? this.totalScore,
      achievements: achievements ?? this.achievements,
      status: status ?? this.status,
      activityFeed: activityFeed ?? this.activityFeed,
      bestTeammates: bestTeammates ?? this.bestTeammates,
      recentGames: recentGames ?? this.recentGames,
      friends: friends ?? this.friends,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      isTeamCaptain: isTeamCaptain ?? this.isTeamCaptain,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'losses': losses,
      'rating': rating,
      'totalReviews': totalReviews,
      'skillLevel': skillLevel,
      'preferredLocations': preferredLocations,
      'isVerified': isVerified,
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      // Новые поля
      'organizerPoints': organizerPoints,
      'totalScore': totalScore,
      'achievements': achievements,
      'status': status.toString().split('.').last,
      'activityFeed': activityFeed,
      'bestTeammates': bestTeammates.map((ref) => ref.toMap()).toList(),
      'recentGames': recentGames.map((game) => game.toMap()).toList(),
      'friends': friends,
      // Поля команды
      'teamId': teamId,
      'teamName': teamName,
      'isTeamCaptain': isTeamCaptain,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: _roleFromString(map['role'] as String?),
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      dateOfBirth: map['dateOfBirth'] != null && map['dateOfBirth'] is Timestamp
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : null,
      bio: map['bio'] ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null && map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      gamesPlayed: map['gamesPlayed'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      skillLevel: map['skillLevel'] ?? 'Начинающий',
      preferredLocations: List<String>.from(map['preferredLocations'] ?? []),
      isVerified: map['isVerified'] ?? false,
      lastActiveAt: map['lastActiveAt'] != null && map['lastActiveAt'] is Timestamp
          ? (map['lastActiveAt'] as Timestamp).toDate()
          : null,
      // Новые поля
      organizerPoints: map['organizerPoints'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
      achievements: List<String>.from(map['achievements'] ?? []),
      status: _statusFromString(map['status'] as String?),
      activityFeed: List<String>.from(map['activityFeed'] ?? []),
      bestTeammates: (map['bestTeammates'] as List<dynamic>? ?? [])
          .map((item) => PlayerRef.fromMap(item as Map<String, dynamic>))
          .toList(),
      recentGames: (map['recentGames'] as List<dynamic>? ?? [])
          .map((item) => GameRef.fromMap(item as Map<String, dynamic>))
          .toList(),
      friends: List<String>.from(map['friends'] ?? []),
      // Поля команды
      teamId: map['teamId'],
      teamName: map['teamName'],
      isTeamCaptain: map['isTeamCaptain'] ?? false,
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

  static PlayerStatus _statusFromString(String? status) {
    switch (status) {
      case 'unavailable':
        return PlayerStatus.unavailable;
      case 'freeTonight':
        return PlayerStatus.freeTonight;
      case 'lookingForGame':
      default:
        return PlayerStatus.lookingForGame;
    }
  }
} 