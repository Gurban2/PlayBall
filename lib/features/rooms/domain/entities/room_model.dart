import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus {
  planned,
  active,
  completed,
  cancelled,
}

enum GameMode {
  normal,        // Обычный режим - как сейчас
  team_friendly, // Дружеский матч - команда на команду (только 2 команды)
  tournament,    // Турнир - команда на команду (от 2х команд)
}

// НОВОЕ: Extension для GameMode
extension GameModeExtension on GameMode {
  bool get isTeamMode => this == GameMode.team_friendly || this == GameMode.tournament;
  bool get isNormalMode => this == GameMode.normal;
}

class RoomModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String organizerId;
  final List<String> participants;
  final int maxParticipants;
  final RoomStatus status;
  final GameMode gameMode;
  final double pricePerPerson;
  final String? photoUrl;
  final int numberOfTeams;
  final String? winnerTeamId;
  final Map<String, dynamic>? gameStats;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoomModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.organizerId,
    this.participants = const [],
    required this.maxParticipants,
    this.status = RoomStatus.planned,
    this.gameMode = GameMode.normal,
    required this.pricePerPerson,
    this.photoUrl,
    this.numberOfTeams = 2,
    this.winnerTeamId,
    this.gameStats,
    required this.createdAt,
    this.updatedAt,
  });

  RoomModel copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? participants,
    int? maxParticipants,
    RoomStatus? status,
    GameMode? gameMode,
    double? pricePerPerson,
    String? photoUrl,
    int? numberOfTeams,
    String? winnerTeamId,
    Map<String, dynamic>? gameStats,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      organizerId: organizerId,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      status: status ?? this.status,
      gameMode: gameMode ?? this.gameMode,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
      photoUrl: photoUrl ?? this.photoUrl,
      numberOfTeams: numberOfTeams ?? this.numberOfTeams,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      gameStats: gameStats ?? this.gameStats,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'organizerId': organizerId,
      'participants': participants,
      'maxParticipants': maxParticipants,
      'status': status.toString().split('.').last,
      'gameMode': gameMode.toString().split('.').last,
      'pricePerPerson': pricePerPerson,
      'photoUrl': photoUrl,
      'numberOfTeams': numberOfTeams,
      'winnerTeamId': winnerTeamId,
      'gameStats': gameStats,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      startTime: map['startTime'] is Timestamp 
          ? (map['startTime'] as Timestamp).toDate() 
          : DateTime.now(),
      endTime: map['endTime'] is Timestamp 
          ? (map['endTime'] as Timestamp).toDate() 
          : DateTime.now().add(const Duration(hours: 2)),
      organizerId: map['organizerId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      maxParticipants: map['maxParticipants'] ?? 0,
      status: _statusFromString(map['status'] as String?),
      gameMode: _gameModeFromString(map['gameMode'] as String?),
      pricePerPerson: (map['pricePerPerson'] ?? 0).toDouble(),
      photoUrl: map['photoUrl'],
      numberOfTeams: map['numberOfTeams'] ?? 2,
      winnerTeamId: map['winnerTeamId'],
      gameStats: map['gameStats'],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null && map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  static RoomStatus _statusFromString(String? status) {
    switch (status) {
      case 'active':
        return RoomStatus.active;
      case 'completed':
        return RoomStatus.completed;
      case 'cancelled':
        return RoomStatus.cancelled;
      case 'planned':
      default:
        return RoomStatus.planned;
    }
  }

  static GameMode _gameModeFromString(String? gameMode) {
    switch (gameMode) {
      case 'normal':
        return GameMode.normal;
      case 'team_friendly':
        return GameMode.team_friendly;
      case 'tournament':
        return GameMode.tournament;
      case 'friendly':
        return GameMode.team_friendly;
      default:
        return GameMode.normal;
    }
  }

  bool get isFull => participants.length >= maxParticipants;
  bool get hasStarted => startTime.isBefore(DateTime.now());
  bool get hasEnded => endTime.isBefore(DateTime.now());
  
  // Проверка, должна ли игра считаться активной (за 5 минут до начала)
  bool get shouldBeActive {
    final now = DateTime.now();
    final activationTime = startTime.subtract(const Duration(minutes: 5));
    return now.isAfter(activationTime) && status == RoomStatus.planned;
  }
  
  // Эффективный статус игры с учетом времени
  RoomStatus get effectiveStatus {
    if (status != RoomStatus.planned) {
      return status;
    }
    
    final now = DateTime.now();
    final activationTime = startTime.subtract(const Duration(minutes: 5));
    
    if (now.isAfter(activationTime)) {
      return RoomStatus.active;
    }
    
    return RoomStatus.planned;
  }
  
  // Проверка, можно ли завершить матч вручную (прошел минимум 1 час)
  bool get canBeEndedManually {
    if (status != RoomStatus.active) return false;
    final now = DateTime.now();
    final minimumEndTime = startTime.add(const Duration(hours: 1));
    return now.isAfter(minimumEndTime);
  }
  
  // Проверка, должен ли матч быть автоматически завершен (прошло 3 часа)
  bool get shouldBeAutoCompleted {
    if (status != RoomStatus.active) return false;
    final now = DateTime.now();
    return now.isAfter(endTime);
  }

  bool get isNormalMode => gameMode == GameMode.normal;
  bool get isTeamMode => gameMode == GameMode.team_friendly || gameMode == GameMode.tournament;
  bool get isFriendlyMode => gameMode == GameMode.team_friendly;
  bool get isTournamentMode => gameMode == GameMode.tournament;
} 