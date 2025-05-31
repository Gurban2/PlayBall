import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/team_model.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/user_team_model.dart';
import '../utils/constants.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Получение команд для комнаты
  Future<List<TeamModel>> getTeamsForRoom(String roomId) async {
    final snapshot = await _firestore
        .collection('teams')
        .where('roomId', isEqualTo: roomId)
        .get();
    
    final teams = snapshot.docs
        .map((doc) => TeamModel.fromMap(doc.data()))
        .toList();
    
    teams.sort((a, b) => a.name.compareTo(b.name));
    return teams;
  }

  // Stream для команд комнаты
  Stream<List<TeamModel>> watchTeamsForRoom(String roomId) {
    return _firestore
        .collection('teams')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
          final teams = snapshot.docs
              .map((doc) => TeamModel.fromMap(doc.data()))
              .toList();
          
          teams.sort((a, b) => a.name.compareTo(b.name));
          return teams;
        });
  }

  // Присоединение к команде
  Future<void> joinTeam(String teamId, String userId) async {
    final teamDoc = await _firestore.collection('teams').doc(teamId).get();
    if (!teamDoc.exists) {
      throw Exception('Команда не найдена');
    }

    final team = TeamModel.fromMap(teamDoc.data()!);
    
    if (team.isFull) {
      throw Exception('Команда заполнена');
    }

    if (team.members.contains(userId)) {
      throw Exception('Вы уже в этой команде');
    }

    final roomDoc = await _firestore.collection('rooms').doc(team.roomId).get();
    if (!roomDoc.exists) {
      throw Exception('Комната не найдена');
    }

    final room = RoomModel.fromMap(roomDoc.data()!);
    
    if (room.status != RoomStatus.planned) {
      throw Exception('Нельзя присоединиться к команде после начала игры');
    }

    final batch = _firestore.batch();

    // Добавляем в команду
    batch.update(_firestore.collection('teams').doc(teamId), {
      'members': FieldValue.arrayUnion([userId]),
      'updatedAt': Timestamp.now(),
    });

    // Добавляем в участники комнаты
    if (!room.participants.contains(userId)) {
      batch.update(_firestore.collection('rooms').doc(team.roomId), {
        'participants': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  // Выход из команды
  Future<void> leaveTeam(String teamId, String userId) async {
    final teamDoc = await _firestore.collection('teams').doc(teamId).get();
    if (!teamDoc.exists) {
      throw Exception('Команда не найдена');
    }

    final team = TeamModel.fromMap(teamDoc.data()!);
    
    if (!team.members.contains(userId)) {
      throw Exception('Вы не в этой команде');
    }

    final roomDoc = await _firestore.collection('rooms').doc(team.roomId).get();
    if (!roomDoc.exists) {
      throw Exception('Комната не найдена');
    }

    final room = RoomModel.fromMap(roomDoc.data()!);
    
    if (room.status != RoomStatus.planned) {
      throw Exception('Нельзя покинуть команду после начала игры');
    }

    if (room.organizerId == userId) {
      throw Exception('Организатор не может покинуть свою команду');
    }

    final batch = _firestore.batch();

    batch.update(_firestore.collection('teams').doc(teamId), {
      'members': FieldValue.arrayRemove([userId]),
      'updatedAt': Timestamp.now(),
    });

    batch.update(_firestore.collection('rooms').doc(team.roomId), {
      'participants': FieldValue.arrayRemove([userId]),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  // Получить команду пользователя в комнате
  Future<TeamModel?> getUserTeamInRoom(String userId, String roomId) async {
    final snapshot = await _firestore
        .collection('teams')
        .where('roomId', isEqualTo: roomId)
        .where('members', arrayContains: userId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    
    return TeamModel.fromMap(snapshot.docs.first.data());
  }

  // Получить команду по ID
  Future<TeamModel?> getTeamById(String teamId) async {
    final doc = await _firestore.collection('teams').doc(teamId).get();
    return doc.exists ? TeamModel.fromMap(doc.data()!) : null;
  }

  // Получить команду по ID
  Future<UserTeamModel?> getUserTeamById(String teamId) async {
    final doc = await _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId).get();
    return doc.exists ? UserTeamModel.fromMap(doc.data()!) : null;
  }

  // РАБОТА С ПОСТОЯННЫМИ КОМАНДАМИ

  // Создать постоянную команду
  Future<String> createUserTeam(UserTeamModel team) async {
    final String teamId = _uuid.v4();
    final teamWithId = team.copyWith();
    
    final teamData = teamWithId.toMap();
    teamData['id'] = teamId;
    
    await _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId).set(teamData);
    
    // Обновляем информацию о команде у участников
    await _updateTeamInfoForMembers(teamId, team.name, team.members, team.ownerId);
    
    return teamId;
  }

  // Получить команду пользователя
  Future<UserTeamModel?> getUserTeam(String ownerId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.userTeamsCollection)
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    
    return UserTeamModel.fromMap(snapshot.docs.first.data());
  }

  // Обновить команду
  Future<void> updateUserTeam(String teamId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.now();
    await _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId).update(updates);
    
    if (updates.containsKey('members') || updates.containsKey('name')) {
      final teamDoc = await _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId).get();
      if (teamDoc.exists) {
        final updatedTeam = UserTeamModel.fromMap(teamDoc.data()!);
        await _updateTeamInfoForMembers(teamId, updatedTeam.name, updatedTeam.members, updatedTeam.ownerId);
      }
    }
  }

  // Удалить команду
  Future<void> deleteUserTeam(String teamId) async {
    final teamDoc = await _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId).get();
    if (teamDoc.exists) {
      final team = UserTeamModel.fromMap(teamDoc.data()!);
      await _removeTeamInfoFromMembers(team.members);
    }
    
    await _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId).delete();
  }

  // Получить информацию о команде пользователя (упрощенно)
  Future<Map<String, String?>> getUserTeamInfo(String userId) async {
    try {
      // Сначала ищем команду, где пользователь является владельцем
      final ownerSnapshot = await _firestore
          .collection(FirestorePaths.userTeamsCollection)
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (ownerSnapshot.docs.isNotEmpty) {
        final team = UserTeamModel.fromMap(ownerSnapshot.docs.first.data());
        return {'name': team.name, 'id': team.id};
      }
      
      // Если не владелец, ищем команду, где пользователь является участником
      final memberSnapshot = await _firestore
          .collection(FirestorePaths.userTeamsCollection)
          .where('members', arrayContains: userId)
          .limit(1)
          .get();
      
      if (memberSnapshot.docs.isNotEmpty) {
        final team = UserTeamModel.fromMap(memberSnapshot.docs.first.data());
        return {'name': team.name, 'id': team.id};
      }
      
      return {'name': null, 'id': null};
    } catch (e) {
      return {'name': null, 'id': null};
    }
  }

  // Синхронизация информации о команде в профилях пользователей
  Future<void> _updateTeamInfoForMembers(String teamId, String teamName, List<String> members, String ownerId) async {
    final batch = _firestore.batch();
    
    for (final memberId in members) {
      final userRef = _firestore.collection(FirestorePaths.usersCollection).doc(memberId);
      batch.update(userRef, {
        'teamId': teamId,
        'teamName': teamName,
        'isTeamCaptain': memberId == ownerId,
        'updatedAt': Timestamp.now(),
      });
    }
    
    await batch.commit();
  }

  // Удалить информацию о команде из профилей
  Future<void> _removeTeamInfoFromMembers(List<String> members) async {
    final batch = _firestore.batch();
    
    for (final memberId in members) {
      final userRef = _firestore.collection(FirestorePaths.usersCollection).doc(memberId);
      batch.update(userRef, {
        'teamId': null,
        'teamName': null,
        'isTeamCaptain': false,
        'updatedAt': Timestamp.now(),
      });
    }
    
    await batch.commit();
  }
} 