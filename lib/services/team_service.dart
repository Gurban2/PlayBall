import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/team_model.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/user_team_model.dart';
import '../models/team_invitation_model.dart';
import '../models/team_application_model.dart';
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

  // Создать постоянную команду (только одну на организатора)
  Future<String> createUserTeam(UserTeamModel team) async {
    // Проверяем, нет ли уже команды у этого организатора
    final existingTeam = await getUserTeam(team.ownerId);
    if (existingTeam != null) {
      throw Exception('У организатора может быть только одна команда');
    }

    // Проверяем, не состоит ли организатор в чужой команде
    final organizer = await _getUserById(team.ownerId);
    if (organizer != null && organizer.teamId != null) {
      // Проверяем, является ли он владельцем этой команды
      final currentTeam = await getUserTeamById(organizer.teamId!);
      if (currentTeam != null && currentTeam.ownerId != team.ownerId) {
        throw Exception('Нельзя создать свою команду, находясь в другой');
      }
    }

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

  // Удалить команду пользователя
  Future<void> deleteUserTeam(String teamId) async {
    final teamDoc = await _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId).get();
    if (!teamDoc.exists) {
      throw Exception('Команда не найдена');
    }

    final team = UserTeamModel.fromMap(teamDoc.data()!);
    
    final batch = _firestore.batch();

    // Удаляем команду
    batch.delete(_firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId));

    // Удаляем информацию о команде у всех участников
    for (final memberId in team.members) {
      batch.update(_firestore.collection(FirestorePaths.usersCollection).doc(memberId), {
        'teamId': null,
        'teamName': null,
        'isTeamCaptain': false,
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
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

  // Получить команды организатора
  Future<List<UserTeamModel>> getTeamsByOrganizer(String organizerId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.userTeamsCollection)
        .where('ownerId', isEqualTo: organizerId)
        .get();
    
    return snapshot.docs
        .map((doc) => UserTeamModel.fromMap(doc.data()))
        .toList();
  }

  // Получить все команды (для поиска и просмотра)
  Future<List<UserTeamModel>> getAllUserTeams() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.userTeamsCollection)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => UserTeamModel.fromMap(doc.data()))
        .toList();
  }

  // МЕТОДЫ ДЛЯ ПРИГЛАШЕНИЙ В КОМАНДЫ

  // Отправить приглашение в команду
  Future<void> sendTeamInvitation({
    required String teamId,
    required String fromUserId,
    required String toUserId,
    String? replacedUserId, // ID игрока, которого заменяют
  }) async {
    if (fromUserId == toUserId) {
      throw Exception('Нельзя пригласить самого себя');
    }

    // Получаем данные команды
    final teamDoc = await _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId).get();
    if (!teamDoc.exists) {
      throw Exception('Команда не найдена');
    }

    final team = UserTeamModel.fromMap(teamDoc.data()!);
    
    // Проверяем, что отправитель - владелец команды
    if (team.ownerId != fromUserId) {
      throw Exception('Только владелец команды может отправлять приглашения');
    }

    // Проверяем, что приглашаемый пользователь не в команде
    if (team.members.contains(toUserId)) {
      throw Exception('Пользователь уже в команде');
    }

    // Получаем данные пользователей
    final fromUser = await _getUserById(fromUserId);
    final toUser = await _getUserById(toUserId);
    
    if (fromUser == null) {
      throw Exception('Отправитель не найден');
    }
    
    if (toUser == null) {
      throw Exception('Пользователь не найден');
    }

    // Проверяем, что пользователи друзья
    if (!fromUser.friends.contains(toUserId)) {
      throw Exception('Можно приглашать только друзей');
    }

    // Проверяем, что у приглашаемого нет активной команды (если не заменяем игрока)
    if (replacedUserId == null && toUser.teamId != null) {
      throw Exception('Пользователь уже состоит в команде');
    }

    // Проверяем, нет ли уже активного приглашения
    final existingInvitation = await _firestore
        .collection(FirestorePaths.teamInvitationsCollection)
        .where('teamId', isEqualTo: teamId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingInvitation.docs.isNotEmpty) {
      throw Exception('Приглашение уже отправлено');
    }

    String? replacedUserName;
    if (replacedUserId != null) {
      final replacedUser = await _getUserById(replacedUserId);
      replacedUserName = replacedUser?.name;
    }

    // Создаем приглашение
    final invitation = TeamInvitationModel(
      id: '',
      teamId: teamId,
      teamName: team.name,
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromUserName: fromUser.name,
      toUserName: toUser.name,
      fromUserPhotoUrl: fromUser.photoUrl,
      toUserPhotoUrl: toUser.photoUrl,
      status: TeamInvitationStatus.pending,
      createdAt: DateTime.now(),
      replacedUserId: replacedUserId,
      replacedUserName: replacedUserName,
    );

    await _firestore.collection(FirestorePaths.teamInvitationsCollection).add(invitation.toMap());
  }

  // Принять приглашение в команду
  Future<void> acceptTeamInvitation(String invitationId) async {
    final invitationDoc = await _firestore.collection(FirestorePaths.teamInvitationsCollection).doc(invitationId).get();
    if (!invitationDoc.exists) {
      throw Exception('Приглашение не найдено');
    }

    final invitation = TeamInvitationModel.fromMap(invitationDoc.data()!, invitationId);
    
    if (invitation.status != TeamInvitationStatus.pending) {
      throw Exception('Приглашение уже обработано');
    }

    final batch = _firestore.batch();

    // Обновляем статус приглашения
    batch.update(_firestore.collection(FirestorePaths.teamInvitationsCollection).doc(invitationId), {
      'status': 'accepted',
      'respondedAt': Timestamp.now(),
    });

    // Получаем команду
    final teamDoc = await _firestore.collection(FirestorePaths.userTeamsCollection).doc(invitation.teamId).get();
    if (!teamDoc.exists) {
      throw Exception('Команда не найдена');
    }

    final team = UserTeamModel.fromMap(teamDoc.data()!);
    List<String> newMembers = List.from(team.members);

    // Если заменяем игрока, удаляем его из команды
    if (invitation.replacedUserId != null) {
      newMembers.remove(invitation.replacedUserId);
      
      // Удаляем информацию о команде у заменяемого игрока
      batch.update(_firestore.collection(FirestorePaths.usersCollection).doc(invitation.replacedUserId!), {
        'teamId': null,
        'teamName': null,
        'isTeamCaptain': false,
        'updatedAt': Timestamp.now(),
      });
    }

    // Добавляем нового игрока
    if (!newMembers.contains(invitation.toUserId)) {
      newMembers.add(invitation.toUserId);
    }

    // Обновляем команду
    batch.update(_firestore.collection(FirestorePaths.userTeamsCollection).doc(invitation.teamId), {
      'members': newMembers,
      'updatedAt': Timestamp.now(),
    });

    // Обновляем информацию о команде у нового игрока
    batch.update(_firestore.collection(FirestorePaths.usersCollection).doc(invitation.toUserId), {
      'teamId': invitation.teamId,
      'teamName': invitation.teamName,
      'isTeamCaptain': false,
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  // Отклонить приглашение в команду
  Future<void> declineTeamInvitation(String invitationId) async {
    await _firestore.collection(FirestorePaths.teamInvitationsCollection).doc(invitationId).update({
      'status': 'declined',
      'respondedAt': Timestamp.now(),
    });
  }

  // Получить входящие приглашения в команды
  Future<List<TeamInvitationModel>> getIncomingTeamInvitations(String userId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.teamInvitationsCollection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TeamInvitationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Получить исходящие приглашения в команды
  Future<List<TeamInvitationModel>> getOutgoingTeamInvitations(String userId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.teamInvitationsCollection)
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TeamInvitationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Получить количество входящих приглашений в команды
  Future<int> getIncomingTeamInvitationsCount(String userId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.teamInvitationsCollection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }

  // Отменить приглашение в команду
  Future<void> cancelTeamInvitation(String teamId, String toUserId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.teamInvitationsCollection)
        .where('teamId', isEqualTo: teamId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Удалить игрока из команды
  Future<void> removePlayerFromTeam(String teamId, String playerId, String ownerId) async {
    final teamDoc = await _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId).get();
    if (!teamDoc.exists) {
      throw Exception('Команда не найдена');
    }

    final team = UserTeamModel.fromMap(teamDoc.data()!);
    
    // Проверяем права
    if (team.ownerId != ownerId) {
      throw Exception('Только владелец команды может удалять игроков');
    }

    if (playerId == ownerId) {
      throw Exception('Владелец команды не может удалить себя');
    }

    if (!team.members.contains(playerId)) {
      throw Exception('Игрок не состоит в команде');
    }

    final batch = _firestore.batch();

    // Удаляем игрока из команды
    final newMembers = team.members.where((id) => id != playerId).toList();
    batch.update(_firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId), {
      'members': newMembers,
      'updatedAt': Timestamp.now(),
    });

    // Удаляем информацию о команде у игрока
    batch.update(_firestore.collection(FirestorePaths.usersCollection).doc(playerId), {
      'teamId': null,
      'teamName': null,
      'isTeamCaptain': false,
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  // Вспомогательный метод для получения пользователя
  Future<UserModel?> _getUserById(String userId) async {
    final doc = await _firestore.collection(FirestorePaths.usersCollection).doc(userId).get();
    return doc.exists ? UserModel.fromMap(doc.data()!) : null;
  }

  // РАБОТА С ЗАЯВКАМИ В КОМАНДЫ

  // Подать заявку на вступление в команду
  Future<void> sendTeamApplication(String teamId, String fromUserId, {String? message}) async {
    // Получаем информацию о команде
    final teamDoc = await _firestore.collection(FirestorePaths.userTeamsCollection).doc(teamId).get();
    if (!teamDoc.exists) {
      throw Exception('Команда не найдена');
    }

    final team = UserTeamModel.fromMap(teamDoc.data()!);
    
    // Проверяем, что команда не полная
    if (team.isFull) {
      throw Exception('Команда уже заполнена');
    }

    // Получаем информацию о пользователе
    final fromUser = await _getUserById(fromUserId);
    if (fromUser == null) {
      throw Exception('Пользователь не найден');
    }

    // Проверяем, что пользователь не состоит в команде
    if (fromUser.teamId != null) {
      throw Exception('Вы уже состоите в команде');
    }

    // Проверяем, что нет активной заявки
    final existingApplication = await _firestore
        .collection(FirestorePaths.teamApplicationsCollection)
        .where('teamId', isEqualTo: teamId)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingApplication.docs.isNotEmpty) {
      throw Exception('Вы уже подали заявку в эту команду');
    }

    // Получаем информацию о владельце команды
    final teamOwner = await _getUserById(team.ownerId);
    if (teamOwner == null) {
      throw Exception('Владелец команды не найден');
    }

    // Создаем заявку
    final application = TeamApplicationModel(
      id: '',
      teamId: teamId,
      teamName: team.name,
      fromUserId: fromUserId,
      fromUserName: fromUser.name,
      toUserId: team.ownerId,
      status: 'pending',
      message: message,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(FirestorePaths.teamApplicationsCollection).add(application.toFirestore());
  }

  // Принять заявку в команду
  Future<void> acceptTeamApplication(String applicationId) async {
    final applicationDoc = await _firestore.collection(FirestorePaths.teamApplicationsCollection).doc(applicationId).get();
    if (!applicationDoc.exists) {
      throw Exception('Заявка не найдена');
    }

    final application = TeamApplicationModel.fromFirestore(applicationDoc);
    
    if (application.status != 'pending') {
      throw Exception('Заявка уже обработана');
    }

    // Получаем команду
    final teamDoc = await _firestore.collection(FirestorePaths.userTeamsCollection).doc(application.teamId).get();
    if (!teamDoc.exists) {
      throw Exception('Команда не найдена');
    }

    final team = UserTeamModel.fromMap(teamDoc.data()!);
    
    // Проверяем, что команда не полная
    if (team.isFull) {
      throw Exception('Команда уже заполнена');
    }

    // Проверяем, что пользователь не состоит в другой команде
    final applicant = await _getUserById(application.fromUserId);
    if (applicant?.teamId != null) {
      throw Exception('Пользователь уже состоит в команде');
    }

    final batch = _firestore.batch();

    // Обновляем статус заявки
    batch.update(_firestore.collection(FirestorePaths.teamApplicationsCollection).doc(applicationId), {
      'status': 'accepted',
      'respondedAt': Timestamp.now(),
    });

    // Добавляем игрока в команду
    final newMembers = List<String>.from(team.members);
    if (!newMembers.contains(application.fromUserId)) {
      newMembers.add(application.fromUserId);
    }

    batch.update(_firestore.collection(FirestorePaths.userTeamsCollection).doc(application.teamId), {
      'members': newMembers,
      'updatedAt': Timestamp.now(),
    });

    // Обновляем информацию о команде у игрока
    batch.update(_firestore.collection(FirestorePaths.usersCollection).doc(application.fromUserId), {
      'teamId': application.teamId,
      'teamName': application.teamName,
      'isTeamCaptain': false,
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  // Отклонить заявку в команду
  Future<void> declineTeamApplication(String applicationId) async {
    await _firestore.collection(FirestorePaths.teamApplicationsCollection).doc(applicationId).update({
      'status': 'declined',
      'respondedAt': Timestamp.now(),
    });
  }

  // Получить входящие заявки в команды (для владельцев команд)
  Future<List<TeamApplicationModel>> getIncomingTeamApplications(String teamOwnerId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.teamApplicationsCollection)
        .where('toUserId', isEqualTo: teamOwnerId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TeamApplicationModel.fromFirestore(doc))
        .toList();
  }

  // Получить исходящие заявки в команды (для пользователей)
  Future<List<TeamApplicationModel>> getOutgoingTeamApplications(String userId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.teamApplicationsCollection)
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TeamApplicationModel.fromFirestore(doc))
        .toList();
  }

  // Получить количество входящих заявок в команды
  Future<int> getIncomingTeamApplicationsCount(String teamOwnerId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.teamApplicationsCollection)
        .where('toUserId', isEqualTo: teamOwnerId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }

  // Отменить заявку в команду
  Future<void> cancelTeamApplication(String teamId, String fromUserId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.teamApplicationsCollection)
        .where('teamId', isEqualTo: teamId)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Выйти из команды (для обычных пользователей)
  Future<void> leaveUserTeam(String userId) async {
    // Получаем информацию о пользователе
    final user = await _getUserById(userId);
    if (user == null) {
      throw Exception('Пользователь не найден');
    }

    if (user.teamId == null) {
      throw Exception('Вы не состоите в команде');
    }

    // Получаем команду
    final teamDoc = await _firestore.collection(FirestorePaths.userTeamsCollection).doc(user.teamId!).get();
    if (!teamDoc.exists) {
      throw Exception('Команда не найдена');
    }

    final team = UserTeamModel.fromMap(teamDoc.data()!);
    
    // Проверяем, что пользователь не является владельцем команды
    if (team.ownerId == userId) {
      throw Exception('Владелец команды не может покинуть команду. Удалите команду или передайте права другому игроку.');
    }

    // Проверяем, что пользователь действительно в команде
    if (!team.members.contains(userId)) {
      throw Exception('Вы не состоите в этой команде');
    }

    final batch = _firestore.batch();

    // Удаляем пользователя из команды
    final newMembers = team.members.where((id) => id != userId).toList();
    batch.update(_firestore.collection(FirestorePaths.userTeamsCollection).doc(user.teamId!), {
      'members': newMembers,
      'updatedAt': Timestamp.now(),
    });

    // Удаляем информацию о команде у пользователя
    batch.update(_firestore.collection(FirestorePaths.usersCollection).doc(userId), {
      'teamId': null,
      'teamName': null,
      'isTeamCaptain': false,
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }
} 