import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus {
  planned,
  active,
  completed,
  cancelled,
}

enum GameMode {
  friendly,
  tournament,
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
    this.gameMode = GameMode.friendly,
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
      case 'friendly':
        return GameMode.friendly;
      case 'tournament':
        return GameMode.tournament;
      default:
        return GameMode.friendly;
    }
  }

  bool get isFull => participants.length >= maxParticipants;
  bool get hasStarted => startTime.isBefore(DateTime.now());
  bool get hasEnded => endTime.isBefore(DateTime.now());
} 