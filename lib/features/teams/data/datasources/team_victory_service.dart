import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/constants.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../auth/data/datasources/user_service.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../../rooms/data/datasources/room_service.dart';
import '../../../teams/domain/entities/user_team_model.dart';
import '../../../teams/domain/entities/team_model.dart';
import '../../../notifications/data/datasources/game_notification_service.dart';
import 'team_service.dart';

/// Модель записи о победе команды
class TeamVictoryModel {
  final String id;
  final String gameId;
  final String winnerTeamId;
  final String winnerTeamName;
  final List<String> winnerTeamMembers;
  final int pointsAwarded;
  final DateTime createdAt;
  final String organizerId;

  TeamVictoryModel({
    required this.id,
    required this.gameId,
    required this.winnerTeamId,
    required this.winnerTeamName,
    required this.winnerTeamMembers,
    required this.pointsAwarded,
    required this.createdAt,
    required this.organizerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'winnerTeamId': winnerTeamId,
      'winnerTeamName': winnerTeamName,
      'winnerTeamMembers': winnerTeamMembers,
      'pointsAwarded': pointsAwarded,
      'createdAt': Timestamp.fromDate(createdAt),
      'organizerId': organizerId,
    };
  }

  static TeamVictoryModel fromMap(Map<String, dynamic> map) {
    return TeamVictoryModel(
      id: map['id'] ?? '',
      gameId: map['gameId'] ?? '',
      winnerTeamId: map['winnerTeamId'] ?? '',
      winnerTeamName: map['winnerTeamName'] ?? '',
      winnerTeamMembers: List<String>.from(map['winnerTeamMembers'] ?? []),
      pointsAwarded: map['pointsAwarded'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      organizerId: map['organizerId'] ?? '',
    );
  }
}

/// Сервис для управления победами команд
class TeamVictoryService {
  static const String _collection = 'team_victories';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final TeamService _teamService;
  final GameNotificationService _notificationService;

  TeamVictoryService(this._teamService, this._notificationService);

  /// Выбрать команду-победителя и начислить баллы
  Future<void> declareTeamWinner({
    required String gameId,
    required String gameTitle,
    required DateTime gameDate,
    required String winnerTeamId,
    required UserModel organizer,
    int pointsForWin = 3,
  }) async {
    try {
      debugPrint('🏆 Объявляем победителя игры $gameId: команда $winnerTeamId');

      // Проверяем, не была ли уже выбрана команда-победитель для этой игры
      final existingVictory = await _getGameVictory(gameId);
      if (existingVictory != null) {
        throw Exception('Команда-победитель для этой игры уже выбрана');
      }

      // Получаем информацию о команде-победителе из временных команд игры
      final winnerTeam = await _getGameTeamById(gameId, winnerTeamId);
      if (winnerTeam == null) {
        throw Exception('Команда-победитель не найдена');
      }

      // Получаем информацию об игре для определения режима
      final roomDoc = await _firestore.collection('rooms').doc(gameId).get();
      if (!roomDoc.exists) {
        throw Exception('Игра не найдена');
      }
      final room = RoomModel.fromMap(roomDoc.data()!);

      final batch = _firestore.batch();
      final now = DateTime.now();

      // Создаем запись о победе
      final victory = TeamVictoryModel(
        id: _uuid.v4(),
        gameId: gameId,
        winnerTeamId: winnerTeamId,
        winnerTeamName: winnerTeam.name,
        winnerTeamMembers: winnerTeam.members,
        pointsAwarded: pointsForWin,
        createdAt: now,
        organizerId: organizer.id,
      );

      final victoryDoc = _firestore.collection(_collection).doc(victory.id);
      batch.set(victoryDoc, victory.toMap());

      // Начисляем баллы постоянной команде только для настоящего командного режима
      if (room.gameMode.toString() == 'GameMode.team_friendly') {
        // Командный режим: +1 балл команде
        await _awardPointsToWinnerTeam(winnerTeam, 1);
        debugPrint('💰 Команде начислен +1 балл за победу');
      } else {
        debugPrint('⚠️ Обычный режим - статистика постоянных команд не обновляется');
      }

      // Сохраняем все изменения
      await batch.commit();

      debugPrint('✅ Победа команды ${winnerTeam.name} зафиксирована!');

      // Обновляем индивидуальную статистику wins/losses игроков
      try {
        final roomService = RoomService();
        await roomService.updatePlayerStatsAfterTeamVictory(room, winnerTeamId);
        debugPrint('✅ Обновлена индивидуальная статистика игроков');
      } catch (e) {
        debugPrint('❌ Ошибка обновления индивидуальной статистики: $e');
      }

      // Отправляем уведомления участникам команды-победителя
      await _notifyTeamVictory(
        gameId: gameId,
        winnerTeamName: winnerTeam.name,
        winnerTeamMembers: winnerTeam.members,
        gameTitle: gameTitle,
        organizer: organizer,
        pointsAwarded: pointsForWin,
      );

    } catch (e) {
      debugPrint('❌ Ошибка при объявлении победителя: $e');
      rethrow;
    }
  }

  /// Получить информацию о победе в игре
  Future<TeamVictoryModel?> _getGameVictory(String gameId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('gameId', isEqualTo: gameId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return TeamVictoryModel.fromMap(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('❌ Ошибка получения информации о победе: $e');
      return null;
    }
  }

  /// Получить команды, участвовавшие в игре
  Future<List<UserTeamModel>> _getParticipatingTeams(String gameId) async {
    try {
      // Получаем все команды игры из коллекции teams
      final snapshot = await _firestore
          .collection('teams')
          .where('roomId', isEqualTo: gameId)
          .get();

      final gameTeams = snapshot.docs
          .map((doc) => TeamModel.fromMap(doc.data()))
          .toList();

      // Находим соответствующие постоянные команды
      final userTeams = <UserTeamModel>[];
      for (final gameTeam in gameTeams) {
        if (gameTeam.members.isNotEmpty) {
          // Пытаемся найти постоянную команду по участникам
          final firstMemberId = gameTeam.members.first;
          final userTeam = await _findUserTeamByMember(firstMemberId);
          if (userTeam != null) {
            userTeams.add(userTeam);
          }
        }
      }

      return userTeams;
    } catch (e) {
      debugPrint('❌ Ошибка получения участвующих команд: $e');
      return [];
    }
  }

  /// Найти постоянную команду по участнику
  Future<UserTeamModel?> _findUserTeamByMember(String memberId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.userTeamsCollection)
          .where('members', arrayContains: memberId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return UserTeamModel.fromMap(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('❌ Ошибка поиска команды участника: $e');
      return null;
    }
  }

  /// Получить команду игры по ID
  Future<TeamModel?> _getGameTeamById(String gameId, String teamId) async {
    try {
      debugPrint('🔍 Ищем команду gameId: $gameId, teamId: $teamId');
      
      final snapshot = await _firestore
          .collection('teams')
          .where('roomId', isEqualTo: gameId)
          .where('id', isEqualTo: teamId)
          .limit(1)
          .get();

      debugPrint('📋 Найдено команд по запросу: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        // Дополнительная диагностика - проверим все команды этой игры
        final allTeamsSnapshot = await _firestore
            .collection('teams')
            .where('roomId', isEqualTo: gameId)
            .get();
            
        debugPrint('🔍 Всего команд в игре $gameId: ${allTeamsSnapshot.docs.length}');
        for (final doc in allTeamsSnapshot.docs) {
          final team = TeamModel.fromMap(doc.data());
          debugPrint('📋 Команда: id=${team.id}, name=${team.name}, members=${team.members.length}');
        }
        
        return null;
      }

      final team = TeamModel.fromMap(snapshot.docs.first.data());
      debugPrint('✅ Найдена команда: ${team.name} с ${team.members.length} участниками');
      return team;
    } catch (e) {
      debugPrint('❌ Ошибка получения команды игры: $e');
      return null;
    }
  }

  /// Начислить баллы команде-победителю
  Future<void> _awardPointsToWinnerTeam(TeamModel winnerTeam, int points) async {
    try {
      // Находим постоянную команду по участникам
      for (final memberId in winnerTeam.members) {
        final userTeam = await _findUserTeamByMember(memberId);
        if (userTeam != null) {
          // Начисляем баллы постоянной команде
          await _firestore
              .collection(FirestorePaths.userTeamsCollection)
              .doc(userTeam.id)
              .update({
            'teamScore': FieldValue.increment(points),
            'gamesWon': FieldValue.increment(1),
            'gamesPlayed': FieldValue.increment(1),
            'updatedAt': Timestamp.now(),
          });
          
          debugPrint('💰 Команде ${userTeam.name} начислено $points баллов за победу');
          break; // Обновляем команду только один раз
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка начисления баллов команде-победителю: $e');
    }
  }

  /// Начислить баллы команде
  Future<void> _awardPointsToTeam({
    required WriteBatch batch,
    required String teamId,
    required int points,
    required bool isWin,
  }) async {
    final teamDoc = _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId);
    
    final updates = <String, dynamic>{
      'teamScore': FieldValue.increment(points),
      'updatedAt': Timestamp.now(),
    };

    if (isWin) {
      updates['gamesWon'] = FieldValue.increment(1);
    }

    batch.update(teamDoc, updates);
    debugPrint('💰 Команде $teamId начислено $points баллов');
  }

  /// Обновить игровую статистику команды
  Future<void> _updateTeamGameStats({
    required WriteBatch batch,
    required String teamId,
    required bool isWin,
  }) async {
    final teamDoc = _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId);
    
    final updates = <String, dynamic>{
      'gamesPlayed': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    };

    if (isWin) {
      updates['gamesWon'] = FieldValue.increment(1);
    }

    batch.update(teamDoc, updates);
    debugPrint('📊 Обновлена статистика команды $teamId (победа: $isWin)');
  }

  /// Отправить уведомления о победе команды
  Future<void> _notifyTeamVictory({
    required String gameId,
    required String winnerTeamName,
    required List<String> winnerTeamMembers,
    required String gameTitle,
    required UserModel organizer,
    required int pointsAwarded,
  }) async {
    try {
      // Получаем информацию о комнате для уведомлений
      final roomService = RoomService();
      final room = await roomService.getRoomById(gameId);
      
      if (room == null) {
        debugPrint('❌ Не удалось найти комнату $gameId для отправки уведомлений о победе');
        return;
      }

      // Отправляем уведомления всем участникам команды-победителя
      await _notificationService.notifyTeamVictory(
        room: room,
        organizer: organizer,
        winnerTeamName: winnerTeamName,
        teamMembers: winnerTeamMembers,
      );

      debugPrint('📨 Уведомления о победе отправлены команде $winnerTeamName');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомлений о победе: $e');
    }
  }

  /// Проверить и присудить достижения команде
  Future<void> _checkAndAwardAchievements(String teamId) async {
    try {
      final team = await _teamService.getUserTeamById(teamId);
      if (team == null) return;

      final achievements = <String>[];

      // Первая победа
      if (team.gamesWon == 1 && !team.achievements.contains('first_win')) {
        achievements.add('first_win');
      }

      // Серии побед
      final currentStreak = await _getCurrentWinningStreak(teamId);
      if (currentStreak >= 3 && !team.achievements.contains('winning_streak_3')) {
        achievements.add('winning_streak_3');
      }
      if (currentStreak >= 5 && !team.achievements.contains('winning_streak_5')) {
        achievements.add('winning_streak_5');
      }
      if (currentStreak >= 10 && !team.achievements.contains('winning_streak_10')) {
        achievements.add('winning_streak_10');
      }

      // Добавляем новые достижения
      if (achievements.isNotEmpty) {
        final updatedAchievements = [...team.achievements, ...achievements];
        await _firestore
            .collection(FirestorePaths.userTeamsCollection)
            .doc(teamId)
            .update({
          'achievements': updatedAchievements,
          'updatedAt': Timestamp.now(),
        });

        debugPrint('🏅 Команде ${team.name} присуждены достижения: ${achievements.join(", ")}');
      }
    } catch (e) {
      debugPrint('❌ Ошибка проверки достижений: $e');
    }
  }

  /// Получить текущую серию побед команды
  Future<int> _getCurrentWinningStreak(String teamId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('winnerTeamId', isEqualTo: teamId)
          .orderBy('createdAt', descending: true)
          .limit(20) // Проверяем последние 20 игр
          .get();

      int streak = 0;
      for (final doc in snapshot.docs) {
        final victory = TeamVictoryModel.fromMap(doc.data());
        if (victory.winnerTeamId == teamId) {
          streak++;
        } else {
          break; // Серия прервана
        }
      }

      return streak;
    } catch (e) {
      debugPrint('❌ Ошибка получения серии побед: $e');
      return 0;
    }
  }

  /// Получить историю побед команды
  Future<List<TeamVictoryModel>> getTeamVictories(String teamId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('winnerTeamId', isEqualTo: teamId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => TeamVictoryModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения истории побед: $e');
      return [];
    }
  }

  /// Получить топ команд по баллам
  Future<List<UserTeamModel>> getTopTeams({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.userTeamsCollection)
          .orderBy('teamScore', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserTeamModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения топ команд: $e');
      return [];
    }
  }

  /// Проверить, была ли выбрана команда-победитель для игры
  Future<bool> hasGameWinner(String gameId) async {
    final victory = await _getGameVictory(gameId);
    return victory != null;
  }

  /// Получить команду-победителя игры
  Future<TeamVictoryModel?> getGameWinner(String gameId) async {
    return await _getGameVictory(gameId);
  }
} 