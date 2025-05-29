import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../models/player_evaluation_model.dart';
import '../utils/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // CRUD операции для комнат (игр)

  // Проверка лимита незавершенных игр для организатора
  Future<bool> canOrganizerCreateRoom(String organizerId) async {
    try {
      const int maxActiveRooms = ValidationRules.maxActiveRoomsPerOrganizer;
      
      final snapshot = await _firestore
          .collection('rooms')
          .where('organizerId', isEqualTo: organizerId)
          .get();
      
      // Считаем незавершенные игры (planned и active)
      final activeRooms = snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data()))
          .where((room) => 
              room.status == RoomStatus.planned || 
              room.status == RoomStatus.active)
          .length;
      
      return activeRooms < maxActiveRooms;
    } catch (e) {
      debugPrint('Ошибка проверки лимита комнат: $e');
      return false;
    }
  }

  // Получение количества незавершенных игр организатора
  Future<int> getOrganizerActiveRoomsCount(String organizerId) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .where('organizerId', isEqualTo: organizerId)
          .get();
      
      return snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data()))
          .where((room) => 
              room.status == RoomStatus.planned || 
              room.status == RoomStatus.active)
          .length;
    } catch (e) {
      debugPrint('Ошибка получения количества активных комнат: $e');
      return 0;
    }
  }

  // Создание новой комнаты с проверкой лимита
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
    List<String>? teamNames, // Новый параметр для названий команд
  }) async {
    try {
      // Валидация
      if (title.trim().isEmpty) throw Exception('Название не может быть пустым');
      if (location.trim().isEmpty) throw Exception('Локация не может быть пустой');
      if (maxParticipants < 4) throw Exception('Минимум 4 участника');
      if (numberOfTeams < 2) throw Exception('Минимум 2 команды');
      if (endTime.isBefore(startTime)) throw Exception('Время окончания должно быть позже времени начала');

      // Проверяем лимит активных комнат для организатора
      final activeRoomsCount = await getOrganizerActiveRoomsCount(organizerId);
      if (activeRoomsCount >= 5) {
        throw Exception('Превышен лимит незавершенных игр (максимум 5). Завершите существующие игры перед созданием новых.');
      }

      // Проверяем конфликты локации
      final hasConflict = await checkLocationConflictForCreation(
        location: location,
        startTime: startTime,
        endTime: endTime,
      );
      
      if (hasConflict) {
        // Получаем информацию о конфликтующей игре
        final conflictingRoom = await getConflictingRoomForCreation(
          location: location,
          startTime: startTime,
          endTime: endTime,
        );
        
        String conflictMessage = 'В локации "$location" уже запланирована игра на это время.';
        if (conflictingRoom != null) {
          final conflictStart = '${conflictingRoom.startTime.hour}:${conflictingRoom.startTime.minute.toString().padLeft(2, '0')}';
          final conflictEnd = '${conflictingRoom.endTime.hour}:${conflictingRoom.endTime.minute.toString().padLeft(2, '0')}';
          conflictMessage += '\n\nКонфликтующая игра: "${conflictingRoom.title}"\nВремя: $conflictStart - $conflictEnd';
        }
        
        throw Exception(conflictMessage);
      }

      final String roomId = _uuid.v4();
      final RoomModel newRoom = RoomModel(
        id: roomId,
        title: title,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
        organizerId: organizerId,
        participants: [], // Участники добавляются только после выбора команды
        maxParticipants: maxParticipants,
        pricePerPerson: pricePerPerson,
        numberOfTeams: numberOfTeams,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        gameMode: gameMode,
      );

      // Создаем комнату в Firestore
      await _firestore.collection('rooms').doc(roomId).set(newRoom.toMap());

      // Создаем команды для комнаты с кастомными названиями
      await _createTeamsForRoom(roomId, numberOfTeams, teamNames);

      // Добавляем организатора в первую команду
      await _addOrganizerToFirstTeam(roomId, organizerId);

      return roomId;
    } catch (e) {
      debugPrint('Ошибка создания комнаты: $e');
      rethrow;
    }
  }

  // Получение комнаты по ID
  Future<RoomModel?> getRoomById(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      
      if (!doc.exists) return null;
      
      return RoomModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Ошибка получения комнаты: $e');
      return null;
    }
  }

  // Получение всех комнат
  Future<List<RoomModel>> getAllRooms() async {
    try {
      final snapshot = await _firestore.collection('rooms').get();
      
      return snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения всех комнат: $e');
      return [];
    }
  }

  // Получение активных комнат
  Future<List<RoomModel>> getActiveRooms() async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .where('status', isEqualTo: RoomStatus.active.toString().split('.').last)
          .get();
      
      return snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения активных комнат: $e');
      return [];
    }
  }

  // Stream для активных комнат с real-time обновлениями и автоматическим управлением статусами
  Stream<List<RoomModel>> getActiveRoomsStream() {
    return _firestore
        .collection('rooms')
        .snapshots()
        .asyncMap((snapshot) async {
          final now = DateTime.now();
          final rooms = <RoomModel>[];
          final batch = _firestore.batch();
          bool needsBatchCommit = false;

          for (final doc in snapshot.docs) {
            final room = RoomModel.fromMap(doc.data());
            
            // Автоматическое управление статусами
            if (room.status == RoomStatus.planned && room.startTime.isBefore(now)) {
              // Запланированная игра началась - делаем активной
              batch.update(doc.reference, {
                'status': RoomStatus.active.toString().split('.').last,
                'updatedAt': Timestamp.now(),
              });
              needsBatchCommit = true;
              
              // Добавляем в список как активную
              rooms.add(room.copyWith(status: RoomStatus.active));
            } else if (room.status == RoomStatus.active && room.endTime.isBefore(now)) {
              // Активная игра закончилась - делаем завершенной
              batch.update(doc.reference, {
                'status': RoomStatus.completed.toString().split('.').last,
                'updatedAt': Timestamp.now(),
              });
              needsBatchCommit = true;
              // НЕ добавляем в список активных
            } else if (room.status == RoomStatus.active && !room.endTime.isBefore(now)) {
              // Игра активна и еще не закончилась
              rooms.add(room);
            }
          }

          // Применяем изменения статусов
          if (needsBatchCommit) {
            try {
              await batch.commit();
            } catch (e) {
              debugPrint('Ошибка обновления статусов комнат: $e');
            }
          }

          // Сортируем по времени начала
          rooms.sort((a, b) => a.startTime.compareTo(b.startTime));
          return rooms;
        });
  }

  // Получение запланированных комнат (упрощенный)
  Future<List<RoomModel>> getPlannedRooms() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('rooms')
          .where('status', isEqualTo: RoomStatus.planned.toString().split('.').last)
          .get();
      
      final rooms = snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data()))
          .where((room) => room.startTime.isAfter(now)) // Фильтруем в коде
          .toList();
      
      // Сортируем по времени начала
      rooms.sort((a, b) => a.startTime.compareTo(b.startTime));
      return rooms;
    } catch (e) {
      debugPrint('Ошибка получения запланированных комнат: $e');
      return [];
    }
  }

  // Stream для запланированных комнат с real-time обновлениями и автоматическим управлением статусами
  Stream<List<RoomModel>> getPlannedRoomsStream() {
    return _firestore
        .collection('rooms')
        .snapshots()
        .asyncMap((snapshot) async {
          final now = DateTime.now();
          final rooms = <RoomModel>[];
          final batch = _firestore.batch();
          bool needsBatchCommit = false;

          for (final doc in snapshot.docs) {
            final room = RoomModel.fromMap(doc.data());
            
            // Автоматическое управление статусами
            if (room.status == RoomStatus.planned && room.startTime.isBefore(now)) {
              // Запланированная игра началась - делаем активной
              batch.update(doc.reference, {
                'status': RoomStatus.active.toString().split('.').last,
                'updatedAt': Timestamp.now(),
              });
              needsBatchCommit = true;
              // НЕ добавляем в список запланированных
            } else if (room.status == RoomStatus.planned && room.startTime.isAfter(now)) {
              // Игра запланирована и еще не началась
              rooms.add(room);
            }
          }

          // Применяем изменения статусов
          if (needsBatchCommit) {
            try {
              await batch.commit();
            } catch (e) {
              debugPrint('Ошибка обновления статусов комнат: $e');
            }
          }

          // Сортируем по времени начала
          rooms.sort((a, b) => a.startTime.compareTo(b.startTime));
          return rooms;
        });
  }

  // Stream для конкретной комнаты с real-time обновлениями
  Stream<RoomModel?> getRoomStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return RoomModel.fromMap(snapshot.data()!);
        });
  }

  // Stream для комнат пользователя с real-time обновлениями (упрощенный)
  Stream<List<RoomModel>> getUserRoomsStream(String userId) {
    return _firestore
        .collection('rooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map((doc) => RoomModel.fromMap(doc.data()))
              .toList();
          // Сортируем по времени начала
          rooms.sort((a, b) => a.startTime.compareTo(b.startTime));
          return rooms;
        });
  }

  // Stream для всех комнат (для поиска)
  Stream<List<RoomModel>> getAllRoomsStream() {
    return _firestore
        .collection('rooms')
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map((doc) => RoomModel.fromMap(doc.data()))
              .toList();
          // Сортируем по времени начала
          rooms.sort((a, b) => a.startTime.compareTo(b.startTime));
          return rooms;
        });
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
    try {
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
      
      await _firestore.collection('rooms').doc(roomId).update(updates);
    } catch (e) {
      debugPrint('Ошибка обновления комнаты: $e');
      rethrow;
    }
  }

  // УСТАРЕВШИЕ МЕТОДЫ - теперь пользователи присоединяются через команды
  // Эти методы оставлены для совместимости, но не используются

  // Завершение игры и обновление статистики
  Future<void> completeGame({
    required String roomId,
    required String winnerTeamId,
    required Map<String, dynamic> gameStats,
  }) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'status': RoomStatus.completed.toString().split('.').last,
        'winnerTeamId': winnerTeamId,
        'gameStats': gameStats,
        'updatedAt': Timestamp.now(),
      });
      
      // Обновление статистики игроков
      await _updatePlayersStats(roomId, winnerTeamId, gameStats);
    } catch (e) {
      debugPrint('Ошибка завершения игры: $e');
      rethrow;
    }
  }

  // Обновление статистики игроков после игры
  Future<void> _updatePlayersStats(
    String roomId,
    String winnerTeamId,
    Map<String, dynamic> gameStats,
  ) async {
    try {
      // Получаем комнату и список участников
      final room = await getRoomById(roomId);
      if (room == null) return;
      
      final batch = _firestore.batch();
      
      // Обновляем статистику для каждого игрока
      for (final userId in room.participants) {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await userRef.get();
        
        if (!userDoc.exists) continue;
        
        final userData = userDoc.data()!;
        final currentGamesPlayed = userData['gamesPlayed'] ?? 0;
        final currentWins = userData['wins'] ?? 0;
        final currentLosses = userData['losses'] ?? 0;
        
        // Проверяем, был ли игрок в выигравшей команде
        final bool isWinner = gameStats['teamPlayers']?[winnerTeamId]?.contains(userId) == true;
        
        batch.update(userRef, {
          'gamesPlayed': currentGamesPlayed + 1,
          'wins': isWinner ? currentWins + 1 : currentWins,
          'losses': !isWinner ? currentLosses + 1 : currentLosses,
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка обновления статистики игроков: $e');
    }
  }

  // Отмена игры
  Future<void> cancelGame(String roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'status': RoomStatus.cancelled.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Ошибка отмены игры: $e');
      rethrow;
    }
  }

  // Получение комнат, созданных пользователем
  Future<List<RoomModel>> getRoomsByOrganizer(String organizerId) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .where('organizerId', isEqualTo: organizerId)
          .get();
      
      return snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения комнат организатора: $e');
      return [];
    }
  }

  // Получение комнат, в которых участвует пользователь
  Future<List<RoomModel>> getRoomsByParticipant(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .where('participants', arrayContains: userId)
          .get();
      
      return snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения комнат участника: $e');
      return [];
    }
  }

  // Проверка уникальности ника
  Future<bool> isNicknameUnique(String nickname, {String? excludeUserId}) async {
    try {
      var query = _firestore
          .collection('users')
          .where('name', isEqualTo: nickname);
      
      final querySnapshot = await query.limit(1).get();
      
      // Если ник не найден, он уникален
      if (querySnapshot.docs.isEmpty) {
        return true;
      }
      
      // Если найден один документ и это текущий пользователь (при обновлении профиля)
      if (excludeUserId != null && 
          querySnapshot.docs.length == 1 && 
          querySnapshot.docs.first.id == excludeUserId) {
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Ошибка проверки уникальности ника: $e');
      return false;
    }
  }

  // Получение пользователя по ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        // Возвращаем тестового пользователя, если не найден в Firestore
        if (userId == 'org-user-1') {
          return UserModel(
            id: 'org-user-1',
            email: 'organizer1@example.com',
            name: 'Организатор 1',
            role: UserRole.organizer,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            lastActiveAt: DateTime.now().subtract(const Duration(hours: 5)),
            gamesPlayed: 42,
            wins: 28,
            losses: 14,
            rating: 5.0,
          );
        }
        return null;
      }
      
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Ошибка получения пользователя: $e');
      return null;
    }
  }

  // Получение списка пользователей
  Future<List<UserModel>> getUsers({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .limit(limit)
          .get();
      
      if (snapshot.docs.isEmpty) {
        // Возвращаем тестовых пользователей, если их нет в Firestore
        return [
          UserModel(
            id: 'user-1',
            email: 'user1@example.com',
            name: 'Пользователь 1',
            role: UserRole.user,
            createdAt: DateTime.now().subtract(const Duration(days: 45)),
            lastActiveAt: DateTime.now().subtract(const Duration(days: 1)),
            gamesPlayed: 15,
            wins: 8,
            losses: 7,
            rating: 4.0,
          ),
          UserModel(
            id: 'org-user-1',
            email: 'organizer1@example.com',
            name: 'Организатор 1',
            role: UserRole.organizer,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            lastActiveAt: DateTime.now().subtract(const Duration(hours: 5)),
            gamesPlayed: 42,
            wins: 28,
            losses: 14,
            rating: 5.0,
          ),
        ];
      }
      
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения пользователей: $e');
      // Возвращаем тестовых пользователей в случае ошибки
      return [
        UserModel(
          id: 'user-1',
          email: 'user1@example.com',
          name: 'Пользователь 1',
          role: UserRole.user,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          lastActiveAt: DateTime.now().subtract(const Duration(days: 1)),
          gamesPlayed: 15,
          wins: 8,
          losses: 7,
          rating: 4.0,
        ),
      ];
    }
  }

  // Получение списка организаторов
  Future<List<UserModel>> getOrganizers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.organizer.toString().split('.').last)
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения организаторов: $e');
      return [];
    }
  }

  // Обновление данных пользователя
  Future<void> updateUser({
    required String userId,
    String? name,
    String? photoUrl,
    UserRole? role,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (role != null) updates['role'] = role.toString().split('.').last;
      
      updates['updatedAt'] = Timestamp.now();
      
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      debugPrint('Ошибка обновления пользователя: $e');
      rethrow;
    }
  }

  // МЕТОДЫ ДЛЯ РАБОТЫ С КОМАНДАМИ

  // Создание команд для комнаты
  Future<void> _createTeamsForRoom(String roomId, int numberOfTeams, List<String>? teamNames) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 1; i <= numberOfTeams; i++) {
        final teamId = _uuid.v4();
        final team = TeamModel(
          id: teamId,
          name: (teamNames != null && teamNames.length >= i) ? teamNames[i - 1] : 'Команда $i',
          roomId: roomId,
          createdAt: DateTime.now(),
        );
        
        final teamRef = _firestore.collection('teams').doc(teamId);
        batch.set(teamRef, team.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка создания команд: $e');
      rethrow;
    }
  }

  // Добавление организатора в первую команду
  Future<void> _addOrganizerToFirstTeam(String roomId, String organizerId) async {
    try {
      // Получаем первую команду
      final teamsSnapshot = await _firestore
          .collection('teams')
          .where('roomId', isEqualTo: roomId)
          .limit(1)
          .get();
      
      if (teamsSnapshot.docs.isNotEmpty) {
        final firstTeamId = teamsSnapshot.docs.first.id;
        
        final batch = _firestore.batch();
        
        // Добавляем организатора в первую команду
        batch.update(_firestore.collection('teams').doc(firstTeamId), {
          'members': FieldValue.arrayUnion([organizerId]),
          'updatedAt': Timestamp.now(),
        });
        
        // Добавляем организатора в участники комнаты
        batch.update(_firestore.collection('rooms').doc(roomId), {
          'participants': FieldValue.arrayUnion([organizerId]),
          'updatedAt': Timestamp.now(),
        });
        
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Ошибка добавления организатора в команду: $e');
      // Не прерываем создание комнаты из-за этой ошибки
    }
  }

  // Получение команд для комнаты
  Future<List<TeamModel>> getTeamsForRoom(String roomId) async {
    try {
      final snapshot = await _firestore
          .collection('teams')
          .where('roomId', isEqualTo: roomId)
          .get();
      
      final teams = snapshot.docs
          .map((doc) => TeamModel.fromMap(doc.data()))
          .toList();
      
      // Сортируем в коде вместо Firestore
      teams.sort((a, b) => a.name.compareTo(b.name));
      
      return teams;
    } catch (e) {
      debugPrint('Ошибка получения команд: $e');
      return [];
    }
  }

  // Stream для команд комнаты
  Stream<List<TeamModel>> getTeamsForRoomStream(String roomId) {
    return _firestore
        .collection('teams')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
          final teams = snapshot.docs
              .map((doc) => TeamModel.fromMap(doc.data()))
              .toList();
          
          // Сортируем в коде вместо Firestore
          teams.sort((a, b) => a.name.compareTo(b.name));
          
          return teams;
        });
  }

  // Присоединение пользователя к команде
  Future<void> joinTeam(String teamId, String userId) async {
    try {
      // Получаем команду
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Команда не найдена');
      }

      final team = TeamModel.fromMap(teamDoc.data()!);
      
      // Проверяем, что команда не заполнена
      if (team.isFull) {
        throw Exception('Команда заполнена');
      }

      // Проверяем, что пользователь не в этой команде
      if (team.members.contains(userId)) {
        throw Exception('Вы уже в этой команде');
      }

      // Получаем комнату
      final roomDoc = await _firestore.collection('rooms').doc(team.roomId).get();
      if (!roomDoc.exists) {
        throw Exception('Комната не найдена');
      }

      final room = RoomModel.fromMap(roomDoc.data()!);
      
      // Проверяем статус комнаты
      if (room.status != RoomStatus.planned) {
        throw Exception('Нельзя присоединиться к команде после начала игры');
      }

      // Проверяем, не в другой команде ли пользователь в этой комнате
      final userCurrentTeam = await getUserTeamInRoom(userId, team.roomId);
      if (userCurrentTeam != null) {
        throw Exception('Вы уже в команде "${userCurrentTeam.name}" в этой игре');
      }

      final batch = _firestore.batch();

      // Добавляем пользователя в команду
      batch.update(_firestore.collection('teams').doc(teamId), {
        'members': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });

      // Добавляем пользователя в участники комнаты (если его там нет)
      if (!room.participants.contains(userId)) {
        batch.update(_firestore.collection('rooms').doc(team.roomId), {
          'participants': FieldValue.arrayUnion([userId]),
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();

      // Начисляем баллы за присоединение к игре (только если пользователь не организатор)
      if (room.organizerId != userId) {
        await awardJoinGamePoints(userId);
      }
    } catch (e) {
      debugPrint('Ошибка присоединения к команде: $e');
      rethrow;
    }
  }

  // Покинуть команду
  Future<void> leaveTeam(String teamId, String userId) async {
    try {
      // Получаем команду
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Команда не найдена');
      }

      final team = TeamModel.fromMap(teamDoc.data()!);
      
      // Проверяем, что пользователь в команде
      if (!team.members.contains(userId)) {
        throw Exception('Вы не в этой команде');
      }

      // Получаем комнату
      final roomDoc = await _firestore.collection('rooms').doc(team.roomId).get();
      if (!roomDoc.exists) {
        throw Exception('Комната не найдена');
      }

      final room = RoomModel.fromMap(roomDoc.data()!);
      
      // Проверяем статус комнаты
      if (room.status != RoomStatus.planned) {
        throw Exception('Нельзя покинуть команду после начала игры');
      }

      // Проверяем, не организатор ли это
      if (room.organizerId == userId) {
        throw Exception('Организатор не может покинуть свою команду');
      }

      final batch = _firestore.batch();

      // Удаляем пользователя из команды
      batch.update(_firestore.collection('teams').doc(teamId), {
        'members': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });

      // Удаляем пользователя из участников комнаты
      batch.update(_firestore.collection('rooms').doc(team.roomId), {
        'participants': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка выхода из команды: $e');
      rethrow;
    }
  }

  // Получить команду пользователя в конкретной комнате
  Future<TeamModel?> getUserTeamInRoom(String userId, String roomId) async {
    try {
      final snapshot = await _firestore
          .collection('teams')
          .where('roomId', isEqualTo: roomId)
          .where('members', arrayContains: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      return TeamModel.fromMap(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('Ошибка получения команды пользователя: $e');
      return null;
    }
  }

  // Получить команду по ID
  Future<TeamModel?> getTeamById(String teamId) async {
    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      
      if (!doc.exists) return null;
      
      return TeamModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Ошибка получения команды: $e');
      return null;
    }
  }

  // Проверка конфликтов локаций
  Future<bool> checkLocationConflict({
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeRoomId, // Исключить текущую комнату из проверки
  }) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .where('location', isEqualTo: location)
          .where('status', isEqualTo: RoomStatus.active.toString().split('.').last)
          .get();
      
      for (final doc in snapshot.docs) {
        final room = RoomModel.fromMap(doc.data());
        
        // Исключаем текущую комнату из проверки
        if (excludeRoomId != null && room.id == excludeRoomId) {
          continue;
        }
        
        // Проверяем пересечение времени
        // Конфликт есть, если новая игра начинается до окончания существующей
        if (startTime.isBefore(room.endTime) && endTime.isAfter(room.startTime)) {
          debugPrint('Конфликт локации: ${room.id} (${room.startTime} - ${room.endTime})');
          return true; // Есть конфликт
        }
      }
      
      return false; // Конфликтов нет
    } catch (e) {
      debugPrint('Ошибка проверки конфликта локации: $e');
      return true; // В случае ошибки считаем, что есть конфликт (безопасность)
    }
  }

  // Получение информации о конфликтующей игре
  Future<RoomModel?> getConflictingRoom({
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeRoomId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .where('location', isEqualTo: location)
          .where('status', isEqualTo: RoomStatus.active.toString().split('.').last)
          .get();
      
      for (final doc in snapshot.docs) {
        final room = RoomModel.fromMap(doc.data());
        
        if (excludeRoomId != null && room.id == excludeRoomId) {
          continue;
        }
        
        if (startTime.isBefore(room.endTime) && endTime.isAfter(room.startTime)) {
          return room; // Возвращаем конфликтующую комнату
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Ошибка получения конфликтующей комнаты: $e');
      return null;
    }
  }

  // Проверка конфликтов локаций для создания новой игры (проверяет и активные, и запланированные игры)
  Future<bool> checkLocationConflictForCreation({
    required String location,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Получаем все игры в данной локации (активные и запланированные)
      final snapshot = await _firestore
          .collection('rooms')
          .where('location', isEqualTo: location)
          .get();
      
      for (final doc in snapshot.docs) {
        final room = RoomModel.fromMap(doc.data());
        
        // Проверяем только активные и запланированные игры
        if (room.status != RoomStatus.active && room.status != RoomStatus.planned) {
          continue;
        }
        
        // Проверяем пересечение времени
        // Конфликт есть, если новая игра пересекается по времени с существующей
        if (startTime.isBefore(room.endTime) && endTime.isAfter(room.startTime)) {
          debugPrint('Конфликт локации при создании: ${room.id} (${room.startTime} - ${room.endTime})');
          return true; // Есть конфликт
        }
      }
      
      return false; // Конфликтов нет
    } catch (e) {
      debugPrint('Ошибка проверки конфликта локации при создании: $e');
      return true; // В случае ошибки считаем, что есть конфликт (безопасность)
    }
  }

  // Получение информации о конфликтующей игре при создании
  Future<RoomModel?> getConflictingRoomForCreation({
    required String location,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .where('location', isEqualTo: location)
          .get();
      
      for (final doc in snapshot.docs) {
        final room = RoomModel.fromMap(doc.data());
        
        // Проверяем только активные и запланированные игры
        if (room.status != RoomStatus.active && room.status != RoomStatus.planned) {
          continue;
        }
        
        if (startTime.isBefore(room.endTime) && endTime.isAfter(room.startTime)) {
          return room; // Возвращаем конфликтующую комнату
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Ошибка получения конфликтующей комнаты при создании: $e');
      return null;
    }
  }

  // НОВЫЕ МЕТОДЫ ДЛЯ СИСТЕМЫ БАЛЛОВ И СТАТИСТИКИ

  // Начисление баллов за присоединение к игре
  Future<void> awardJoinGamePoints(String userId) async {
    try {
      const int joinPoints = 2;
      
      await _updatePlayerScore(
        userId: userId,
        pointsToAdd: joinPoints,
        activityMessage: 'Ты получил +$joinPoints за вход в комнату',
      );
    } catch (e) {
      debugPrint('Ошибка начисления баллов за присоединение: $e');
    }
  }

  // Обновленный метод завершения игры с новой системой баллов
  Future<void> completeGameWithNewScoring({
    required String roomId,
    required String winnerTeamId,
    required Map<String, dynamic> gameStats,
  }) async {
    try {
      // Обновляем статус игры
      await _firestore.collection('rooms').doc(roomId).update({
        'status': RoomStatus.completed.toString().split('.').last,
        'winnerTeamId': winnerTeamId,
        'gameStats': gameStats,
        'updatedAt': Timestamp.now(),
      });
      
      // Обновляем статистику игроков с новой системой баллов
      await _updatePlayersStatsWithNewScoring(roomId, winnerTeamId, gameStats);
      
      // Обновляем статистику партнерства
      await _updateTeammateStats(roomId, gameStats);
      
    } catch (e) {
      debugPrint('Ошибка завершения игры: $e');
      rethrow;
    }
  }

  // Обновленный метод обновления статистики игроков
  Future<void> _updatePlayersStatsWithNewScoring(
    String roomId,
    String winnerTeamId,
    Map<String, dynamic> gameStats,
  ) async {
    try {
      final room = await getRoomById(roomId);
      if (room == null) return;
      
      final batch = _firestore.batch();
      
      // Получаем команды для определения победителей
      final teams = await getTeamsForRoom(roomId);
      final winnerTeam = teams.firstWhere((team) => team.id == winnerTeamId);
      
      for (final userId in room.participants) {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await userRef.get();
        
        if (!userDoc.exists) continue;
        
        final userData = userDoc.data()!;
        final currentUser = UserModel.fromMap(userData);
        
        // Определяем, победил ли игрок
        final bool isWinner = winnerTeam.members.contains(userId);
        
        // Начисляем баллы за результат игры
        final int gameResultPoints = isWinner ? 1 : -1;
        
        // Обновляем основную статистику
        final updatedGamesPlayed = currentUser.gamesPlayed + 1;
        final updatedWins = isWinner ? currentUser.wins + 1 : currentUser.wins;
        final updatedLosses = !isWinner ? currentUser.losses + 1 : currentUser.losses;
        final updatedTotalScore = currentUser.totalScore + gameResultPoints;
        
        // Создаем запись об игре для истории
        final gameRef = GameRef(
          id: roomId,
          title: room.title,
          location: room.location,
          date: room.startTime,
          result: isWinner ? 'win' : 'loss',
          teammates: winnerTeam.members.where((id) => id != userId).toList(),
        );
        
        // Обновляем список последних игр (максимум 5)
        final updatedRecentGames = [gameRef, ...currentUser.recentGames];
        if (updatedRecentGames.length > 5) {
          updatedRecentGames.removeRange(5, updatedRecentGames.length);
        }
        
        // Добавляем событие в ленту активности
        final activityMessage = isWinner 
            ? 'Ты получил +1 за победу в игре "${room.title}"'
            : 'Ты получил -1 за поражение в игре "${room.title}"';
        
        final updatedActivityFeed = [activityMessage, ...currentUser.activityFeed];
        if (updatedActivityFeed.length > 20) {
          updatedActivityFeed.removeRange(20, updatedActivityFeed.length);
        }
        
        // Проверяем и добавляем достижения
        final newAchievements = _checkForNewAchievements(
          currentUser.copyWith(
            gamesPlayed: updatedGamesPlayed,
            wins: updatedWins,
            losses: updatedLosses,
            totalScore: updatedTotalScore,
          ),
        );
        
        final updatedAchievements = [...currentUser.achievements];
        for (final achievement in newAchievements) {
          if (!updatedAchievements.contains(achievement)) {
            updatedAchievements.add(achievement);
            updatedActivityFeed.insert(0, 'Ты получил значок "$achievement"!');
          }
        }
        
        // Обновляем пользователя
        batch.update(userRef, {
          'gamesPlayed': updatedGamesPlayed,
          'wins': updatedWins,
          'losses': updatedLosses,
          'totalScore': updatedTotalScore,
          'recentGames': updatedRecentGames.map((game) => game.toMap()).toList(),
          'activityFeed': updatedActivityFeed.take(20).toList(),
          'achievements': updatedAchievements,
          'updatedAt': Timestamp.now(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка обновления статистики игроков: $e');
    }
  }

  // Проверка новых достижений
  List<String> _checkForNewAchievements(UserModel user) {
    final achievements = <String>[];
    
    // Достижения за количество игр
    if (user.gamesPlayed == 1) achievements.add('Первая игра');
    if (user.gamesPlayed == 10) achievements.add('Десяток игр');
    if (user.gamesPlayed == 50) achievements.add('Полсотни игр');
    if (user.gamesPlayed == 100) achievements.add('Сотня игр');
    
    // Достижения за победы
    if (user.wins == 1) achievements.add('Первая победа');
    if (user.wins == 10) achievements.add('10 побед');
    if (user.wins == 25) achievements.add('25 побед');
    if (user.wins == 50) achievements.add('50 побед');
    
    // Достижения за винрейт
    if (user.gamesPlayed >= 10 && user.winRate >= 80) {
      achievements.add('Мастер побед');
    }
    if (user.gamesPlayed >= 20 && user.winRate >= 90) {
      achievements.add('Легенда');
    }
    
    // Достижения за баллы
    if (user.totalScore >= 50) achievements.add('50 баллов');
    if (user.totalScore >= 100) achievements.add('100 баллов');
    if (user.totalScore >= 200) achievements.add('200 баллов');
    
    return achievements;
  }

  // Обновление статистики партнерства
  Future<void> _updateTeammateStats(String roomId, Map<String, dynamic> gameStats) async {
    try {
      final teams = await getTeamsForRoom(roomId);
      
      for (final team in teams) {
        if (team.members.length < 2) continue;
        
        // Для каждой пары игроков в команде обновляем статистику
        for (int i = 0; i < team.members.length; i++) {
          for (int j = i + 1; j < team.members.length; j++) {
            final player1Id = team.members[i];
            final player2Id = team.members[j];
            
            await _updatePartnershipStats(player1Id, player2Id);
            await _updatePartnershipStats(player2Id, player1Id);
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка обновления статистики партнерства: $e');
    }
  }

  // Обновление статистики партнерства между двумя игроками
  Future<void> _updatePartnershipStats(String playerId, String partnerId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(playerId).get();
      if (!userDoc.exists) return;
      
      final user = UserModel.fromMap(userDoc.data()!);
      final partnerUser = await getUserById(partnerId);
      if (partnerUser == null) return;
      
      // Находим существующую запись о партнере
      final existingPartnerIndex = user.bestTeammates.indexWhere(
        (teammate) => teammate.id == partnerId,
      );
      
      List<PlayerRef> updatedTeammates = [...user.bestTeammates];
      
      if (existingPartnerIndex != -1) {
        // Обновляем существующую запись
        final existing = updatedTeammates[existingPartnerIndex];
        updatedTeammates[existingPartnerIndex] = PlayerRef(
          id: existing.id,
          name: partnerUser.name,
          gamesPlayedTogether: existing.gamesPlayedTogether + 1,
          winsTogetherCount: existing.winsTogetherCount + 1, // Упрощенно считаем, что играли в одной команде
          winRateTogether: ((existing.winsTogetherCount + 1) / (existing.gamesPlayedTogether + 1)) * 100,
        );
      } else {
        // Добавляем нового партнера
        updatedTeammates.add(PlayerRef(
          id: partnerId,
          name: partnerUser.name,
          gamesPlayedTogether: 1,
          winsTogetherCount: 1,
          winRateTogether: 100.0,
        ));
      }
      
      // Сортируем по количеству совместных игр и оставляем топ-5
      updatedTeammates.sort((a, b) => b.gamesPlayedTogether.compareTo(a.gamesPlayedTogether));
      if (updatedTeammates.length > 5) {
        updatedTeammates = updatedTeammates.take(5).toList();
      }
      
      // Обновляем пользователя
      await _firestore.collection('users').doc(playerId).update({
        'bestTeammates': updatedTeammates.map((ref) => ref.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      
    } catch (e) {
      debugPrint('Ошибка обновления статистики партнерства: $e');
    }
  }

  // Сохранение оценки организатора
  Future<void> saveOrganizerEvaluation({
    required String gameId,
    required String organizerId,
    required List<String> playerIds,
    String? comment,
  }) async {
    try {
      final batch = _firestore.batch();
      
      for (final playerId in playerIds) {
        final evaluationId = _uuid.v4();
        final evaluation = PlayerEvaluationModel(
          id: evaluationId,
          gameId: gameId,
          organizerId: organizerId,
          playerId: playerId,
          points: 1, // Стандартный балл от организатора
          comment: comment,
          createdAt: DateTime.now(),
        );
        
        // Сохраняем оценку
        final evaluationRef = _firestore.collection('playerEvaluations').doc(evaluationId);
        batch.set(evaluationRef, evaluation.toMap());
        
        // Обновляем баллы игрока
        await _updatePlayerScore(
          userId: playerId,
          pointsToAdd: 1,
          organizerPointsToAdd: 1,
          activityMessage: 'Организатор дал +1 балл за игру',
        );
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка сохранения оценки организатора: $e');
      rethrow;
    }
  }

  // Универсальный метод обновления баллов игрока
  Future<void> _updatePlayerScore({
    required String userId,
    int pointsToAdd = 0,
    int organizerPointsToAdd = 0,
    required String activityMessage,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;
      
      final user = UserModel.fromMap(userDoc.data()!);
      
      final updatedTotalScore = user.totalScore + pointsToAdd;
      final updatedOrganizerPoints = user.organizerPoints + organizerPointsToAdd;
      
      final updatedActivityFeed = [activityMessage, ...user.activityFeed];
      if (updatedActivityFeed.length > 20) {
        updatedActivityFeed.removeRange(20, updatedActivityFeed.length);
      }
      
      await _firestore.collection('users').doc(userId).update({
        'totalScore': updatedTotalScore,
        'organizerPoints': updatedOrganizerPoints,
        'activityFeed': updatedActivityFeed,
        'updatedAt': Timestamp.now(),
      });
      
    } catch (e) {
      debugPrint('Ошибка обновления баллов игрока: $e');
    }
  }

  // Получение предстоящих игр пользователя
  Future<List<GameRef>> getUpcomingGamesForUser(String userId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('rooms')
          .where('participants', arrayContains: userId)
          .where('status', whereIn: [
            RoomStatus.planned.toString().split('.').last,
            RoomStatus.active.toString().split('.').last,
          ])
          .get();
      
      final upcomingGames = <GameRef>[];
      
      for (final doc in snapshot.docs) {
        final room = RoomModel.fromMap(doc.data());
        
        // Только будущие игры
        if (room.startTime.isAfter(now)) {
          // Получаем команду пользователя
          final userTeam = await getUserTeamInRoom(userId, room.id);
          final teammates = userTeam?.members.where((id) => id != userId).toList() ?? [];
          
          upcomingGames.add(GameRef(
            id: room.id,
            title: room.title,
            location: room.location,
            date: room.startTime,
            result: 'upcoming',
            teammates: teammates,
          ));
        }
      }
      
      // Сортируем по дате
      upcomingGames.sort((a, b) => a.date.compareTo(b.date));
      
      return upcomingGames;
    } catch (e) {
      debugPrint('Ошибка получения предстоящих игр: $e');
      return [];
    }
  }

  // Обновление статуса игрока
  Future<void> updatePlayerStatus(String userId, PlayerStatus status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Ошибка обновления статуса игрока: $e');
      rethrow;
    }
  }

  // Получение оценок для игры
  Future<List<PlayerEvaluationModel>> getEvaluationsForGame(String gameId) async {
    try {
      final snapshot = await _firestore
          .collection('playerEvaluations')
          .where('gameId', isEqualTo: gameId)
          .get();
      
      return snapshot.docs
          .map((doc) => PlayerEvaluationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения оценок для игры: $e');
      return [];
    }
  }

  // МЕТОДЫ ДЛЯ РАБОТЫ С ДРУЗЬЯМИ

  // Добавить в друзья
  Future<void> addFriend(String userId, String friendId) async {
    try {
      if (userId == friendId) {
        throw Exception('Нельзя добавить себя в друзья');
      }

      // Проверяем, не друзья ли уже
      final isAlreadyFriend = await isFriend(userId, friendId);
      if (isAlreadyFriend) {
        throw Exception('Пользователь уже в списке друзей');
      }

      final batch = _firestore.batch();

      // Добавляем друг друга взаимно
      batch.update(_firestore.collection('users').doc(userId), {
        'friends': FieldValue.arrayUnion([friendId]),
        'updatedAt': Timestamp.now(),
      });

      batch.update(_firestore.collection('users').doc(friendId), {
        'friends': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка добавления в друзья: $e');
      rethrow;
    }
  }

  // Удалить из друзей
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      final batch = _firestore.batch();

      // Удаляем друг друга взаимно
      batch.update(_firestore.collection('users').doc(userId), {
        'friends': FieldValue.arrayRemove([friendId]),
        'updatedAt': Timestamp.now(),
      });

      batch.update(_firestore.collection('users').doc(friendId), {
        'friends': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка удаления из друзей: $e');
      rethrow;
    }
  }

  // Проверить, являются ли пользователи друзьями
  Future<bool> isFriend(String userId, String friendId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final user = UserModel.fromMap(userDoc.data()!);
      return user.friends.contains(friendId);
    } catch (e) {
      debugPrint('Ошибка проверки дружбы: $e');
      return false;
    }
  }

  // Получить список друзей пользователя
  Future<List<UserModel>> getFriends(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final user = UserModel.fromMap(userDoc.data()!);
      final friends = <UserModel>[];

      for (final friendId in user.friends) {
        final friend = await getUserById(friendId);
        if (friend != null) {
          friends.add(friend);
        }
      }

      return friends;
    } catch (e) {
      debugPrint('Ошибка получения списка друзей: $e');
      return [];
    }
  }
} 