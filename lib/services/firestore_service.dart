import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../utils/constants.dart';
import 'package:uuid/uuid.dart';

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
    String? photoUrl,
  }) async {
    try {
      // Проверяем лимит незавершенных игр
      final canCreate = await canOrganizerCreateRoom(organizerId);
      if (!canCreate) {
        final activeCount = await getOrganizerActiveRoomsCount(organizerId);
        throw Exception(
          'Превышен лимит незавершенных игр. У вас уже есть $activeCount активных игр. '
          'Максимум разрешено 3 незавершенные игры одновременно. '
          'Завершите или отмените существующие игры перед созданием новых.'
        );
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
      );

      // Создаем комнату
      await _firestore.collection('rooms').doc(roomId).set(newRoom.toMap());
      
      // Создаем команды для комнаты
      await _createTeamsForRoom(roomId, numberOfTeams);
      
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
            lastLogin: DateTime.now().subtract(const Duration(hours: 5)),
            gamesPlayed: 42,
            wins: 28,
            losses: 14,
            rating: 5,
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
            lastLogin: DateTime.now().subtract(const Duration(days: 1)),
            gamesPlayed: 15,
            wins: 8,
            losses: 7,
            rating: 4,
          ),
          UserModel(
            id: 'org-user-1',
            email: 'organizer1@example.com',
            name: 'Организатор 1',
            role: UserRole.organizer,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            lastLogin: DateTime.now().subtract(const Duration(hours: 5)),
            gamesPlayed: 42,
            wins: 28,
            losses: 14,
            rating: 5,
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
          gamesPlayed: 15,
          wins: 8,
          losses: 7,
          rating: 4,
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
  Future<void> _createTeamsForRoom(String roomId, int numberOfTeams) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 1; i <= numberOfTeams; i++) {
        final teamId = _uuid.v4();
        final team = TeamModel(
          id: teamId,
          name: 'Команда $i',
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
} 