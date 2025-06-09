import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель проверки активности игроков команды
class TeamActivityCheckModel {
  final String id;
  final String teamId;
  final String organizerId;
  final String organizerName;
  final DateTime startedAt;
  final DateTime expiresAt; // Время окончания проверки (2 часа)
  final List<String> teamMembers; // Все игроки команды (кроме организатора)
  final List<String> readyPlayers; // Игроки, которые подтвердили готовность
  final bool isActive; // Активна ли проверка
  final bool isCompleted; // Завершена ли проверка

  TeamActivityCheckModel({
    required this.id,
    required this.teamId,
    required this.organizerId,
    required this.organizerName,
    required this.startedAt,
    required this.expiresAt,
    required this.teamMembers,
    this.readyPlayers = const [],
    this.isActive = true,
    this.isCompleted = false,
  });

  /// Фабричный конструктор для создания новой проверки активности
  factory TeamActivityCheckModel.createNew({
    required String teamId,
    required String organizerId,
    required String organizerName,
    required List<String> teamMembers,
  }) {
    final now = DateTime.now();
    return TeamActivityCheckModel(
      id: '', // ID будет установлен при сохранении в Firestore
      teamId: teamId,
      organizerId: organizerId,
      organizerName: organizerName,
      startedAt: now,
      expiresAt: now.add(const Duration(hours: 2)),
      teamMembers: teamMembers.where((id) => id != organizerId).toList(),
      readyPlayers: [],
      isActive: true,
      isCompleted: false,
    );
  }

  /// Проверяет, истекло ли время проверки
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Проверяет, готовы ли все игроки
  bool get areAllPlayersReady => readyPlayers.length == teamMembers.length;

  /// Возвращает количество игроков, которые еще не ответили
  int get notRespondedCount => teamMembers.length - readyPlayers.length;

  /// Возвращает процент готовности команды
  double get readinessPercentage {
    if (teamMembers.isEmpty) return 100.0;
    return (readyPlayers.length / teamMembers.length) * 100;
  }

  /// Проверяет, ответил ли конкретный игрок
  bool isPlayerReady(String playerId) => readyPlayers.contains(playerId);

  /// Копирует модель с изменениями
  TeamActivityCheckModel copyWith({
    String? id,
    String? teamId,
    String? organizerId,
    String? organizerName,
    DateTime? startedAt,
    DateTime? expiresAt,
    List<String>? teamMembers,
    List<String>? readyPlayers,
    bool? isActive,
    bool? isCompleted,
  }) {
    return TeamActivityCheckModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      teamMembers: teamMembers ?? this.teamMembers,
      readyPlayers: readyPlayers ?? this.readyPlayers,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Преобразует модель в Map для сохранения в Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'startedAt': Timestamp.fromDate(startedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'teamMembers': teamMembers,
      'readyPlayers': readyPlayers,
      'isActive': isActive,
      'isCompleted': isCompleted,
    };
  }

  /// Создает модель из Map (из Firestore)
  factory TeamActivityCheckModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TeamActivityCheckModel(
      id: documentId,
      teamId: map['teamId'] ?? '',
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      startedAt: (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      teamMembers: List<String>.from(map['teamMembers'] ?? []),
      readyPlayers: List<String>.from(map['readyPlayers'] ?? []),
      isActive: map['isActive'] ?? true,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  @override
  String toString() {
    return 'TeamActivityCheckModel(id: $id, teamId: $teamId, organizerId: $organizerId, readyPlayers: ${readyPlayers.length}/${teamMembers.length}, isActive: $isActive, isExpired: $isExpired)';
  }
} 