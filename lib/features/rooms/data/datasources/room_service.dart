import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/room_model.dart';
import '../../../teams/domain/entities/team_model.dart';

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
    final RoomModel newRoom = RoomModel(
      id: roomId,
      title: title,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      organizerId: organizerId,
      participants: [organizerId],
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
    
    // Проверяем конфликт для первого часа с учетом страховочного времени ±5 минут
    final checkStartTime = startTime.subtract(const Duration(minutes: 5));
    final checkEndTime = startTime.add(const Duration(hours: 1, minutes: 5));
    
    for (final doc in snapshot.docs) {
      final room = RoomModel.fromMap(doc.data());
      
      if (excludeRoomId != null && room.id == excludeRoomId) continue;
      if (room.status != RoomStatus.active && room.status != RoomStatus.planned) continue;
      
      // Проверяем пересечение первого часа другой игры с учетом страховочного времени
      final roomCheckStartTime = room.startTime.subtract(const Duration(minutes: 5));
      final roomCheckEndTime = room.startTime.add(const Duration(hours: 1, minutes: 5));
      
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
      
      // Запоминаем ID первой команды для обычного режима
      if (i == 1) {
        firstTeamId = teamId;
      }
      
      final team = TeamModel(
        id: teamId,
        name: teamName,
        roomId: roomId,
        createdAt: DateTime.now(),
      );
      
      final teamRef = _firestore.collection('teams').doc(teamId);
      batch.set(teamRef, team.toMap());
    }
    
    await batch.commit();
    
    // В обычном режиме автоматически добавляем организатора в первую команду
    if (gameMode == GameMode.normal && organizerId != null && firstTeamId != null) {
      await _addMemberToTeam(firstTeamId, organizerId);
    }
  }
  
  // Добавление участника в команду
  Future<void> _addMemberToTeam(String teamId, String userId) async {
    await _firestore.collection('teams').doc(teamId).update({
      'members': FieldValue.arrayUnion([userId])
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
        .where('status', isEqualTo: 'planned')
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

  // Автоматическое завершение матчей, которые длятся более 3 часов
  Future<void> autoCompleteExpiredGames() async {
    final now = DateTime.now();
    
    // Ищем активные игры, которые должны быть завершены
    final snapshot = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .where('endTime', isLessThan: Timestamp.fromDate(now))
        .get();
    
    final batch = _firestore.batch();
    
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': RoomStatus.completed.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
    }
    
    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
      print('🎮 Автоматически завершено ${snapshot.docs.length} матчей');
    }
  }

  // Автоматическая отмена просроченных запланированных игр
  Future<void> autoCancelExpiredPlannedGames() async {
    final now = DateTime.now();
    final expiredThreshold = now.subtract(const Duration(hours: 24));
    
    // Получаем все запланированные игры и фильтруем на клиенте
    final snapshot = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'planned')
        .get();
    
    final batch = _firestore.batch();
    int cancelledCount = 0;
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final startTime = (data['startTime'] as Timestamp).toDate();
      
      // Проверяем на клиенте, просрочена ли игра
      if (startTime.isBefore(expiredThreshold)) {
        batch.update(doc.reference, {
          'status': RoomStatus.cancelled.toString().split('.').last,
          'updatedAt': Timestamp.now(),
        });
        cancelledCount++;
      }
    }
    
    if (cancelledCount > 0) {
      await batch.commit();
      print('🗑️ Автоматически отменено $cancelledCount просроченных запланированных игр');
    }
  }
} 