import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/room_model.dart';
import '../../../teams/domain/entities/team_model.dart';
import '../../../../core/utils/game_time_utils.dart';
import '../../../auth/data/datasources/user_service.dart';
import '../../../notifications/data/datasources/game_notification_service.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  static const String _collection = 'rooms';

  // Создание комнаты
  Future<String> createRoom({
    required String title,
    required String description,
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    required String organizerId,
    required int maxParticipants,
    required double pricePerPerson,
    required int numberOfTeams,
    required GameMode gameMode,
    String? photoUrl,
    List<String>? teamNames,
  }) async {
    // Валидация
    if (title.trim().isEmpty) throw Exception('Название не может быть пустым');
    if (location.trim().isEmpty) throw Exception('Локация не может быть пустой');
    if (maxParticipants < 4) throw Exception('Минимум 4 участника');
    if (numberOfTeams < 2) throw Exception('Минимум 2 команды');
    if (endTime.isBefore(startTime)) throw Exception('Время окончания должно быть позже времени начала');

    // Проверяем конфликты локации
    final hasConflict = await checkLocationConflict(
      location: location,
      startTime: startTime,
      endTime: endTime,
    );
    
    if (hasConflict) {
      throw Exception('В локации "$location" уже запланирована игра на это время.');
    }

    final String roomId = _uuid.v4();
    // Определяем начальных участников в зависимости от режима игры
    List<String> initialParticipants = [organizerId];
    
    // Для командного режима добавляем всю команду организатора
    if (gameMode == GameMode.team_friendly) {
      try {
        final userTeamSnapshot = await _firestore
            .collection('user_teams')
            .where('ownerId', isEqualTo: organizerId)
            .limit(1)
            .get();
        
        if (userTeamSnapshot.docs.isNotEmpty) {
          final userTeamData = userTeamSnapshot.docs.first.data();
          final List<String> teamMembers = List<String>.from(userTeamData['members'] ?? []);
          
          if (teamMembers.isNotEmpty) {
            initialParticipants = teamMembers;
          }
        }
      } catch (e) {
        // В случае ошибки оставляем только организатора
      }
    }

    final RoomModel newRoom = RoomModel(
      id: roomId,
      title: title,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      organizerId: organizerId,
      participants: initialParticipants,
      maxParticipants: maxParticipants,
      pricePerPerson: pricePerPerson,
      numberOfTeams: numberOfTeams,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
      gameMode: gameMode,
    );

    // Создаем комнату
    await _firestore.collection(_collection).doc(roomId).set(newRoom.toMap());

    // Создаем команды
    await _createTeamsForRoom(roomId, numberOfTeams, teamNames, organizerId: organizerId, gameMode: gameMode);

    return roomId;
  }

  // Проверка конфликтов локации
  Future<bool> checkLocationConflict({
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeRoomId,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('location', isEqualTo: location)
        .get();
    
    // Проверяем конфликт только по времени начала с учетом страховочного времени ±5 минут
    // Время окончания не учитываем для избежания ложных конфликтов
    final checkStartTime = startTime.subtract(const Duration(minutes: 5));
    final checkEndTime = startTime.add(const Duration(minutes: 5));
    
    for (final doc in snapshot.docs) {
      final room = RoomModel.fromMap(doc.data());
      
      if (excludeRoomId != null && room.id == excludeRoomId) continue;
      if (room.status != RoomStatus.active && room.status != RoomStatus.planned) continue;
      
      // Проверяем пересечение времени начала другой игры с учетом страховочного времени ±5 минут
      final roomCheckStartTime = room.startTime.subtract(const Duration(minutes: 5));
      final roomCheckEndTime = room.startTime.add(const Duration(minutes: 5));
      
      if (checkStartTime.isBefore(roomCheckEndTime) && checkEndTime.isAfter(roomCheckStartTime)) {
        return true;
      }
    }
    
    return false;
  }

  // Создание команд для комнаты
  Future<void> _createTeamsForRoom(String roomId, int numberOfTeams, List<String>? teamNames, {String? organizerId, GameMode? gameMode}) async {
    final batch = _firestore.batch();
    String? firstTeamId;
    
    for (int i = 1; i <= numberOfTeams; i++) {
      final teamId = _uuid.v4();
      String teamName = (teamNames != null && teamNames.length >= i) ? teamNames[i - 1] : 'Команда $i';
      
      // Запоминаем ID первой команды
      if (i == 1) {
        firstTeamId = teamId;
      }
      
      final team = TeamModel(
        id: teamId,
        name: teamName,
        roomId: roomId,
        createdAt: DateTime.now(),
        // В командной игре первая команда будет принадлежать организатору
        captainId: (i == 1 && organizerId != null) ? organizerId : null,
      );
      
      final teamRef = _firestore.collection('teams').doc(teamId);
      batch.set(teamRef, team.toMap());
    }
    
    await batch.commit();
    
    // Автоматически добавляем организатора в первую команду
    if (organizerId != null && firstTeamId != null) {
      if (gameMode == GameMode.normal) {
        // В обычном режиме добавляем только организатора
        await _addMemberToTeam(firstTeamId, organizerId);
      } else if (gameMode == GameMode.team_friendly) {
        // В командном режиме добавляем всю команду организатора
        await _addOrganizerTeamToRoom(firstTeamId, organizerId);
      }
    }
  }

  // Добавление команды организатора в командную игру
  Future<void> _addOrganizerTeamToRoom(String teamId, String organizerId) async {
    try {
      // Получаем команду организатора из коллекции user_teams - исправлено поле leaderId на ownerId
      final userTeamSnapshot = await _firestore
          .collection('user_teams')
          .where('ownerId', isEqualTo: organizerId)
          .limit(1)
          .get();
      
      if (userTeamSnapshot.docs.isNotEmpty) {
        final userTeamData = userTeamSnapshot.docs.first.data();
        final List<String> teamMembers = List<String>.from(userTeamData['members'] ?? []);
        final String teamName = userTeamData['name'] ?? 'Команда 1';
        
        // Добавляем всех участников команды в игровую команду и обновляем название
        if (teamMembers.isNotEmpty) {
          await _firestore.collection('teams').doc(teamId).update({
            'members': FieldValue.arrayUnion(teamMembers),
            'name': teamName, // Используем название команды организатора
            'captainId': organizerId, // Организатор становится капитаном команды
          });
        }
      } else {
        // Если команда не найдена, добавляем только организатора
        await _addMemberToTeam(teamId, organizerId);
      }
    } catch (e) {
      // В случае ошибки добавляем только организатора
      await _addMemberToTeam(teamId, organizerId);
    }
  }
  
  // Добавление участника в команду
  Future<void> _addMemberToTeam(String teamId, String userId) async {
    await _firestore.collection('teams').doc(teamId).update({
      'members': FieldValue.arrayUnion([userId]),
      'captainId': userId, // Если добавляем одного участника, он становится капитаном
    });
  }

  // Получение комнаты по ID
  Future<RoomModel?> getRoomById(String roomId) async {
    final doc = await _firestore.collection(_collection).doc(roomId).get();
    return doc.exists ? RoomModel.fromMap(doc.data()!) : null;
  }

  // Реактивные обновления
  Stream<RoomModel?> watchRoom(String roomId) {
    return _firestore
        .collection(_collection)
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? RoomModel.fromMap(doc.data()!) : null);
  }

  // Активные комнаты с пагинацией
  Stream<List<RoomModel>> watchActiveRooms({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomModel.fromMap(doc.data()))
            .toList());
  }

  // Запланированные комнаты
  Stream<List<RoomModel>> watchPlannedRooms({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'planned')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomModel.fromMap(doc.data()))
            .toList());
  }

  // Присоединение к комнате
  Future<void> joinRoom(String roomId, String userId) async {
    await _firestore.collection(_collection).doc(roomId).update({
      'participants': FieldValue.arrayUnion([userId])
    });
  }

  // Выход из комнаты  
  Future<void> leaveRoom(String roomId, String userId) async {
    await _firestore.collection(_collection).doc(roomId).update({
      'participants': FieldValue.arrayRemove([userId])
    });
  }

  // Обновление статуса
  Future<void> updateRoomStatus(String roomId, String status) async {
    await _firestore.collection(_collection).doc(roomId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Комнаты пользователя
  Stream<List<RoomModel>> watchUserRooms(String userId) {
    return _firestore
        .collection(_collection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomModel.fromMap(doc.data()))
            .toList());
  }

  // Удаление комнаты
  Future<void> deleteRoom(String roomId) async {
    await _firestore.collection(_collection).doc(roomId).delete();
  }

  // Получение активных комнат с пагинацией
  Future<List<RoomModel>> getActiveRooms({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => RoomModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Поиск комнат по названию
  Future<List<RoomModel>> searchRooms(String query, {int limit = 20}) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThan: query + '\uf8ff')
        .where('status', isEqualTo: 'planned')
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => RoomModel.fromMap(doc.data()))
        .toList();
  }

  // Обновление комнаты
  Future<void> updateRoom({
    required String roomId,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? maxParticipants,
    RoomStatus? status,
    double? pricePerPerson,
    String? photoUrl,
  }) async {
    final Map<String, dynamic> updates = {};
    
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (location != null) updates['location'] = location;
    if (startTime != null) updates['startTime'] = Timestamp.fromDate(startTime);
    if (endTime != null) updates['endTime'] = Timestamp.fromDate(endTime);
    if (maxParticipants != null) updates['maxParticipants'] = maxParticipants;
    if (status != null) updates['status'] = status.toString().split('.').last;
    if (pricePerPerson != null) updates['pricePerPerson'] = pricePerPerson;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    
    updates['updatedAt'] = Timestamp.now();
    
    await _firestore.collection(_collection).doc(roomId).update(updates);
    
    // Если игра завершается вручную, начисляем очки и отправляем уведомления
    if (status == RoomStatus.completed) {
      try {
        // Получаем данные комнаты для доступа к участникам
        final roomDoc = await _firestore.collection(_collection).doc(roomId).get();
        if (roomDoc.exists) {
          final room = RoomModel.fromMap(roomDoc.data()!);
          final userService = UserService();
          final gameNotificationService = GameNotificationService();
          
          // Начисляем только базовые очки (wins/losses начисляются через выбор победителя)
          final participantsToAward = room.finalParticipants ?? room.participants;
          await userService.awardPointsToPlayers(participantsToAward);
          
          // Отправляем уведомления
          final organizer = await userService.getUserById(room.organizerId);
          if (organizer != null) {
            // Уведомление всем участникам о завершении игры
            await gameNotificationService.notifyGameEnded(
              room: room,
              organizer: organizer,
            );

            // Специфичные уведомления в зависимости от режима игры
            debugPrint('🔀 [UPDATE STATUS] Проверяем режим игры для уведомлений: isTeamMode=${room.isTeamMode}, gameMode=${room.gameMode}');
            if (room.isTeamMode) {
              // Командный режим: уведомление организатору
              debugPrint('🎯 [UPDATE STATUS] Командный режим - вызываем _notifyOrganizerAfterTeamGame');
              await _notifyOrganizerAfterTeamGame(room, gameNotificationService, userService);
            } else {
              // Обычный режим: уведомление организатору о выборе команды-победителя
              debugPrint('🎯 [UPDATE STATUS] Обычный режим - отправляем уведомление организатору');
              await gameNotificationService.notifyWinnerSelectionRequired(
                room: room,
                organizer: organizer,
                isTeamMode: false,
                playersToSelect: 4,
              );
            }
          }
        }
      } catch (e) {
      }
    }
  }

  // Завершение игры
  Future<void> completeGame({
    required String roomId,
    required String winnerTeamId,
    required Map<String, dynamic> gameStats,
  }) async {
    await _firestore.collection(_collection).doc(roomId).update({
      'status': RoomStatus.completed.toString().split('.').last,
      'winnerTeamId': winnerTeamId,
      'gameStats': gameStats,
      'updatedAt': Timestamp.now(),
    });

    // Статистика wins/losses обновляется через TeamVictoryService.declareTeamWinner
    // когда организатор выбирает команду-победителя
  }

  // Обновление статистики игроков после выбора команды-победителя
  Future<void> _updatePlayerStatsAfterTeamGame(RoomModel room, String winnerTeamId) async {
    // Этот метод вызывается когда организатор выбрал команду-победителя
    if (winnerTeamId.isEmpty) {
      debugPrint('⚠️ Пропускаем обновление статистики - winnerTeamId не указан');
      return;
    }

    final userService = UserService();
    final participantsToUpdate = room.finalParticipants ?? room.participants;
    
    // Определяем победителей и проигравших
    List<String> winners = [];
    List<String> losers = [];
    
    try {
      // Получаем участников команды-победителя
      final teamSnapshot = await _firestore
          .collection('teams')
          .where('roomId', isEqualTo: room.id)
          .where('id', isEqualTo: winnerTeamId)
          .limit(1)
          .get();
          
      if (teamSnapshot.docs.isNotEmpty) {
        final teamData = teamSnapshot.docs.first.data();
        final teamMembers = List<String>.from(teamData['members'] ?? []);
        
        // Победители - члены команды-победителя, которые участвовали в игре
        winners = participantsToUpdate.where((id) => teamMembers.contains(id)).toList();
        // Проигравшие - все остальные участники игры
        losers = participantsToUpdate.where((id) => !teamMembers.contains(id)).toList();
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения команды победителя: $e');
      return;
    }
    
    if (winners.isEmpty) {
      debugPrint('⚠️ Не удалось определить победителей');
      return;
    }
    
    debugPrint('🏆 Игра ${room.id} завершена. Победители: ${winners.length}, Проигравшие: ${losers.length}');
    
    // Обновляем статистику победителей
    for (String playerId in winners) {
      try {
        final playerDoc = _firestore.collection('users').doc(playerId);
        
        await playerDoc.update({
          'gamesPlayed': FieldValue.increment(1),
          'wins': FieldValue.increment(1), // Добавляем победу
          'totalScore': FieldValue.increment(2), // Больше очков за победу
        });

        // Пересчитываем и обновляем рейтинг
        await userService.updateUserRating(playerId);
        
        debugPrint('✅ Обновлена статистика победителя $playerId');
      } catch (e) {
        debugPrint('❌ Ошибка обновления статистики победителя $playerId: $e');
      }
    }
    
    // Обновляем статистику проигравших
    for (String playerId in losers) {
      try {
        final playerDoc = _firestore.collection('users').doc(playerId);
        
        await playerDoc.update({
          'gamesPlayed': FieldValue.increment(1),
          'losses': FieldValue.increment(1), // Добавляем поражение
          'totalScore': FieldValue.increment(1), // Меньше очков за участие
        });

        // Пересчитываем и обновляем рейтинг
        await userService.updateUserRating(playerId);
        
        debugPrint('📉 Обновлена статистика проигравшего $playerId');
      } catch (e) {
        debugPrint('❌ Ошибка обновления статистики проигравшего $playerId: $e');
      }
    }
  }

  // Публичный метод для обновления статистики после выбора команды-победителя
  Future<void> updatePlayerStatsAfterTeamVictory(RoomModel room, String winnerTeamId) async {
    await _updatePlayerStatsAfterTeamGame(room, winnerTeamId);
  }

  // Отмена игры
  Future<void> cancelGame(String roomId) async {
    await _firestore.collection(_collection).doc(roomId).update({
      'status': RoomStatus.cancelled.toString().split('.').last,
      'updatedAt': Timestamp.now(),
    });
  }

  // Получение комнат организатора
  Future<List<RoomModel>> getRoomsByOrganizer(String organizerId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('organizerId', isEqualTo: organizerId)
        .get();
    
    return snapshot.docs
        .map((doc) => RoomModel.fromMap(doc.data()))
        .toList();
  }

  // Очистка завершенных игр организатора
  Future<void> clearCompletedGames(String organizerId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('organizerId', isEqualTo: organizerId)
        .where('status', whereIn: ['completed', 'cancelled'])
        .get();
    
    final batch = _firestore.batch();
    
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Получение количества активных комнат организатора
  Future<int> getOrganizerActiveRoomsCount(String organizerId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('organizerId', isEqualTo: organizerId)
        .get();
    
    return snapshot.docs
        .map((doc) => RoomModel.fromMap(doc.data()))
        .where((room) => 
            room.status == RoomStatus.planned || 
            room.status == RoomStatus.active)
        .length;
  }

  // Все комнаты (для поиска)
  Stream<List<RoomModel>> watchAllRooms({int limit = 50}) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomModel.fromMap(doc.data()))
            .toList());
  }

  // Уведомление организатору после завершения командной игры
  Future<void> _notifyOrganizerAfterTeamGame(
    RoomModel room,
    GameNotificationService gameNotificationService,
    UserService userService,
  ) async {
    try {
      debugPrint('🔍 Отправляем уведомление организатору командной игры "${room.title}"');

      // Отправляем уведомление о выборе победителя только организатору игры
      final organizer = await userService.getUserById(room.organizerId);
      if (organizer != null) {
        await gameNotificationService.notifyWinnerSelectionRequired(
          room: room,
          organizer: organizer,
          isTeamMode: true,
          playersToSelect: 2,
        );
        debugPrint('🏆 Уведомление о выборе команды-победителя → организатор');
      } else {
        debugPrint('❌ Организатор игры не найден: ${room.organizerId}');
      }

    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления организатору: $e');
    }
  }

  // Автоматическое завершение матчей, которые достигли времени окончания
  Future<void> autoCompleteExpiredGames() async {
    // Ищем активные игры
    final snapshot = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .get();
    
    final batch = _firestore.batch();
    int completedCount = 0;
    final gameNotificationService = GameNotificationService();
    final userService = UserService();
    
    for (final doc in snapshot.docs) {
      final room = RoomModel.fromMap(doc.data());
      
      // Используем новую утилиту для проверки (теперь проверяет endTime)
      if (GameTimeUtils.shouldAutoCompleteGame(room)) {
        // ДОБАВЛЯЕМ ПРОВЕРКУ: завершаем только если игра еще активна
        final currentDoc = await _firestore.collection(_collection).doc(doc.id).get();
        if (!currentDoc.exists) continue;
        
        final currentRoom = RoomModel.fromMap(currentDoc.data()!);
        if (currentRoom.status != RoomStatus.active) {
          debugPrint('⚠️ Игра ${room.title} уже не активна, пропускаем автозавершение');
          continue;
        }
        
        batch.update(doc.reference, {
          'status': RoomStatus.completed.toString().split('.').last,
          'updatedAt': Timestamp.now(),
        });
        completedCount++;
        
        // Очки будут начислены только после выбора победителей организатором
        debugPrint('✅ Игра завершена автоматически. Ожидается выбор победителей.');

        // Отправляем уведомления о завершении игры
        try {
          final organizer = await userService.getUserById(room.organizerId);
          if (organizer != null) {
            // Уведомление всем участникам о завершении игры
            await gameNotificationService.notifyGameEnded(
              room: room,
              organizer: organizer,
            );

            // Специфичные уведомления в зависимости от режима игры
            debugPrint('🔀 [AUTO COMPLETE] Проверяем режим игры для уведомлений: isTeamMode=${room.isTeamMode}, gameMode=${room.gameMode}');
            if (room.isTeamMode) {
              // Командный режим: уведомление организатору
              debugPrint('🎯 [AUTO COMPLETE] Командный режим - вызываем _notifyOrganizerAfterTeamGame');
              await _notifyOrganizerAfterTeamGame(room, gameNotificationService, userService);
            } else {
              // Обычный режим: уведомление организатору о выборе команды-победителя
              debugPrint('🎯 [AUTO COMPLETE] Обычный режим - отправляем уведомление организатору');
              await gameNotificationService.notifyWinnerSelectionRequired(
                room: room,
                organizer: organizer,
                isTeamMode: false,
                playersToSelect: 4,
              );
            }
          }
        } catch (e) {
          debugPrint('❌ [AUTO COMPLETE] Ошибка отправки уведомлений: $e');
        }
      }
    }
    
    if (completedCount > 0) {
      await batch.commit();
      debugPrint('✅ Автоматически завершено игр: $completedCount');
    }
  }

  // Автоматическая отмена просроченных запланированных игр
  Future<void> autoCancelExpiredPlannedGames() async {
    // Получаем все запланированные игры
    final snapshot = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'planned')
        .get();
    
    final batch = _firestore.batch();
    int cancelledCount = 0;
    
    for (final doc in snapshot.docs) {
      final room = RoomModel.fromMap(doc.data());
      
      // Используем новую утилиту для проверки
      if (GameTimeUtils.isPlannedGameExpired(room)) {
        batch.update(doc.reference, {
          'status': RoomStatus.cancelled.toString().split('.').last,
          'updatedAt': Timestamp.now(),
        });
        cancelledCount++;
      }
    }
    
    if (cancelledCount > 0) {
      await batch.commit();
    }
  }

  // Автоматический запуск запланированных игр в назначенное время
  Future<void> autoStartScheduledGames() async {
    // Ищем запланированные игры
    final snapshot = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'planned')
        .get();
    
    final batch = _firestore.batch();
    int startedCount = 0;
    
    for (final doc in snapshot.docs) {
      final room = RoomModel.fromMap(doc.data());
      
      // Используем утилиту для проверки автоматического запуска
      if (GameTimeUtils.shouldAutoStartGame(room)) {
        // Сохраняем текущих участников как finalParticipants на момент старта
        batch.update(doc.reference, {
          'status': RoomStatus.active.toString().split('.').last,
          'finalParticipants': room.participants, // Фиксируем участников на момент старта
          'updatedAt': Timestamp.now(),
        });
        startedCount++;
      }
    }
    
    if (startedCount > 0) {
      await batch.commit();
    }
  }

  // Добавление команды организатора в уже созданную командную игру
  Future<void> addOrganizerTeamToGame({
    required String roomId,
    required String organizerId,
  }) async {
    // Проверяем, что игра существует и в командном режиме
    final roomDoc = await _firestore.collection(_collection).doc(roomId).get();
    if (!roomDoc.exists) {
      throw Exception('Игра не найдена');
    }

    final room = RoomModel.fromMap(roomDoc.data()!);
    
    if (room.gameMode != GameMode.team_friendly) {
      throw Exception('Добавление команды доступно только в командных играх');
    }

    if (room.status != RoomStatus.planned) {
      throw Exception('Нельзя добавлять команды в активную или завершенную игру');
    }

    // Проверяем, что организатор еще не участвует в игре
    if (room.participants.contains(organizerId)) {
      throw Exception('Вы уже участвуете в этой игре');
    }

    // Получаем команду организатора
    final userTeamSnapshot = await _firestore
        .collection('user_teams')
        .where('ownerId', isEqualTo: organizerId)
        .limit(1)
        .get();

    if (userTeamSnapshot.docs.isEmpty) {
      throw Exception('У вас нет команды. Создайте команду в разделе "Моя команда"');
    }

    final userTeamData = userTeamSnapshot.docs.first.data();
    final List<String> teamMembers = List<String>.from(userTeamData['members'] ?? []);
    final String teamName = userTeamData['name'] ?? 'Команда ${organizerId.substring(0, 4)}';

    if (teamMembers.length < 6) {
      throw Exception('В команде должно быть минимум 6 игроков для участия в командной игре');
    }

    // Проверяем, есть ли свободная команда
    final teamsSnapshot = await _firestore
        .collection('teams')
        .where('roomId', isEqualTo: roomId)
        .get();

    TeamModel? availableTeam;
    for (final teamDoc in teamsSnapshot.docs) {
      final team = TeamModel.fromMap(teamDoc.data());
      if (team.members.isEmpty) {
        availableTeam = team;
        break;
      }
    }

    if (availableTeam == null) {
      throw Exception('Все команды в игре заняты');
    }

    // Добавляем команду в игру
    final batch = _firestore.batch();

    // Обновляем команду в игре
    batch.update(_firestore.collection('teams').doc(availableTeam.id), {
      'members': teamMembers,
      'name': teamName,
      'ownerId': organizerId,
      'updatedAt': Timestamp.now(),
    });

    // Добавляем всех участников команды в участники комнаты
    batch.update(_firestore.collection(_collection).doc(roomId), {
      'participants': FieldValue.arrayUnion(teamMembers),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
    
  }
} 