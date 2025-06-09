import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/constants.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../../teams/domain/entities/team_model.dart';
import '../../../teams/domain/entities/user_team_model.dart';
import '../../../teams/domain/entities/team_invitation_model.dart';
import '../../../teams/domain/entities/team_application_model.dart';
import '../../../teams/domain/entities/team_activity_check_model.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/game_time_utils.dart';

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
    
    // Проверяем статус игры (используем GameTimeUtils для проверки)
    if (!GameTimeUtils.canJoinGame(room)) {
      throw Exception('Нельзя присоединиться к команде: игра уже активна или началась');
    }

    // Дополнительная проверка: за 5 минут до начала присоединение блокируется
    final now = DateTime.now();
    final joinCutoffTime = room.startTime.subtract(const Duration(minutes: 5));
    if (now.isAfter(joinCutoffTime)) {
      throw Exception('Присоединение к команде заблокировано за 5 минут до начала игры');
    }

    final batch = _firestore.batch();

    // Подготавливаем данные для обновления команды
    final teamUpdateData = {
      'members': FieldValue.arrayUnion([userId]),
      'updatedAt': Timestamp.now(),
    };

    // Если у команды нет капитана и она пустая, делаем присоединившегося капитаном
    if (team.captainId == null && team.members.isEmpty) {
      teamUpdateData['captainId'] = userId;
    }

    // Добавляем в команду
    batch.update(_firestore.collection('teams').doc(teamId), teamUpdateData);

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
    
    // Проверяем статус игры (используем GameTimeUtils для проверки)
    if (!GameTimeUtils.canLeaveGame(room)) {
      throw Exception('Нельзя покинуть команду: игра уже активна или началась');
    }

    // Дополнительная проверка: за 5 минут до начала выход из команды блокируется
    final now = DateTime.now();
    final leaveCutoffTime = room.startTime.subtract(const Duration(minutes: 5));
    if (now.isAfter(leaveCutoffTime)) {
      throw Exception('Выход из команды заблокирован за 5 минут до начала игры');
    }

    // В обычном режиме организатор игры не может покинуть команду
    // В командном режиме организатор команды может покинуть матч (но не организатор игры)
    if (room.organizerId == userId && !room.isTeamMode) {
      throw Exception('Организатор игры не может покинуть команду');
    }
    
    // В командном режиме организатор игры не может покинуть матч
    if (room.isTeamMode && room.organizerId == userId) {
      throw Exception('Организатор игры не может покинуть командный матч');
    }

    final batch = _firestore.batch();

    // НОВАЯ ЛОГИКА: В командном режиме, если организатор команды покидает матч,
    // то вся команда должна покинуть матч
    if (room.isTeamMode && team.ownerId == userId) {
      debugPrint('🚨 Организатор команды покидает командный матч - удаляем всю команду');
      
      // Удаляем всех участников команды из комнаты
      batch.update(_firestore.collection('rooms').doc(team.roomId), {
        'participants': FieldValue.arrayRemove(team.members),
        'updatedAt': Timestamp.now(),
      });
      
      // Очищаем команду полностью
      batch.update(_firestore.collection('teams').doc(teamId), {
        'members': [],
        'ownerId': null,
        'updatedAt': Timestamp.now(),
      });
      
      debugPrint('✅ Вся команда "${team.name}" (${team.members.length} игроков) покинула матч вместе с организатором');
    } else {
      // Обычная логика - удаляем только одного игрока
      batch.update(_firestore.collection('teams').doc(teamId), {
        'members': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });

      batch.update(_firestore.collection('rooms').doc(team.roomId), {
        'participants': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });
    }

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

    // Если заменяем игрока, удаляем его из команды и создаем уведомление об исключении
    if (invitation.replacedUserId != null) {
      newMembers.remove(invitation.replacedUserId);
      
      // Удаляем информацию о команде у заменяемого игрока
      batch.update(_firestore.collection(FirestorePaths.usersCollection).doc(invitation.replacedUserId!), {
        'teamId': null,
        'teamName': null,
        'isTeamCaptain': false,
        'updatedAt': Timestamp.now(),
      });
      
      // Создаем уведомление об исключении для заменяемого игрока
      final teamExclusionNotification = {
        'id': '',
        'toUserId': invitation.replacedUserId!,
        'type': 'team_exclusion',
        'title': 'Исключение из команды',
        'message': 'Вы были исключены из команды "${invitation.teamName}" и заменены игроком ${invitation.toUserName}',
        'teamId': invitation.teamId,
        'teamName': invitation.teamName,
        'replacedByUserId': invitation.toUserId,
        'replacedByUserName': invitation.toUserName,
        'isRead': false,
        'createdAt': Timestamp.now(),
      };
      
      // Добавляем уведомление в коллекцию notifications
      batch.set(
        _firestore.collection('notifications').doc(),
        teamExclusionNotification,
      );
      
      debugPrint('📢 Создано уведомление об исключении для игрока ${invitation.replacedUserId} из команды ${invitation.teamName}');
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
    // Получаем информацию о пользователе
    final fromUser = await _getUserById(fromUserId);
    if (fromUser == null) {
      throw Exception('Пользователь не найден');
    }

    // Проверяем роль пользователя - обычные пользователи не могут отправлять заявки
    if (fromUser.role == UserRole.user) {
      throw Exception('Обычные пользователи не могут отправлять заявки в команды. Обратитесь к организатору своей команды.');
    }

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
    debugPrint('🚪 Начинаем процесс покидания команды для пользователя: $userId');
    
    // Получаем информацию о пользователе
    final user = await _getUserById(userId);
    if (user == null) {
      throw Exception('Пользователь не найден');
    }

    if (user.teamId == null) {
      throw Exception('Вы не состоите в команде');
    }

    debugPrint('👤 Пользователь найден: ${user.name}, teamId: ${user.teamId}, teamName: ${user.teamName}');

    // Получаем команду
    final teamDoc = await _firestore.collection(FirestorePaths.userTeamsCollection).doc(user.teamId!).get();
    if (!teamDoc.exists) {
      throw Exception('Команда не найдена');
    }

    final team = UserTeamModel.fromMap(teamDoc.data()!);
    
    debugPrint('🏆 Команда найдена: ${team.name}, участники: ${team.members}');
    
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

    debugPrint('📝 Обновляем команду, новые участники: $newMembers');

    // Удаляем информацию о команде у пользователя
    batch.update(_firestore.collection(FirestorePaths.usersCollection).doc(userId), {
      'teamId': null,
      'teamName': null,
      'isTeamCaptain': false,
      'updatedAt': Timestamp.now(),
    });

    debugPrint('🗑️ Удаляем информацию о команде из профиля пользователя');

    await batch.commit();
    
    debugPrint('✅ Батч-операция завершена успешно');
    
    // Ждем небольшую задержку для синхронизации Firebase
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Проверяем, что обновление прошло успешно
    final updatedUser = await _getUserById(userId);
    if (updatedUser != null) {
      debugPrint('🔍 Проверка после обновления: teamId=${updatedUser.teamId}, teamName=${updatedUser.teamName}');
    }
  }

  // РАБОТА С ПРОВЕРКАМИ АКТИВНОСТИ ИГРОКОВ

  /// Создать новую проверку активности для команды
  Future<String> createActivityCheck({
    required String teamId,
    required String organizerId,
    required String organizerName,
    required List<String> teamMembers,
  }) async {
    // Проверяем, что нет активной проверки для этой команды
    final activeCheck = await getActiveActivityCheck(teamId);
    if (activeCheck != null) {
      throw Exception('У команды уже есть активная проверка готовности');
    }

    // Создаем новую проверку активности
    final activityCheck = TeamActivityCheckModel.createNew(
      teamId: teamId,
      organizerId: organizerId,
      organizerName: organizerName,
      teamMembers: teamMembers,
    );

    // Сохраняем в Firestore
    final docRef = await _firestore
        .collection('team_activity_checks')
        .add(activityCheck.toMap());

    debugPrint('✅ Создана проверка активности для команды $teamId: ${docRef.id}');
    return docRef.id;
  }

  /// Получить активную проверку активности для команды
  Future<TeamActivityCheckModel?> getActiveActivityCheck(String teamId) async {
    try {
      final snapshot = await _firestore
          .collection('team_activity_checks')
          .where('teamId', isEqualTo: teamId)
          .where('isActive', isEqualTo: true)
          .orderBy('startedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final activityCheck = TeamActivityCheckModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );

      // Проверяем, не истекла ли проверка
      if (activityCheck.isExpired) {
        // Автоматически завершаем истекшую проверку
        await _completeActivityCheck(activityCheck.id);
        return null;
      }

      return activityCheck;
    } catch (e) {
      debugPrint('❌ Ошибка получения активной проверки активности: $e');
      return null;
    }
  }

  /// Получить проверку активности по ID
  Future<TeamActivityCheckModel?> getActivityCheckById(String checkId) async {
    try {
      final doc = await _firestore
          .collection('team_activity_checks')
          .doc(checkId)
          .get();

      if (!doc.exists) return null;

      return TeamActivityCheckModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('❌ Ошибка получения проверки активности: $e');
      return null;
    }
  }

  /// Игрок подтверждает свою готовность
  Future<void> confirmPlayerReadiness(String checkId, String playerId) async {
    final checkDoc = await _firestore
        .collection('team_activity_checks')
        .doc(checkId)
        .get();

    if (!checkDoc.exists) {
      throw Exception('Проверка активности не найдена');
    }

    final activityCheck = TeamActivityCheckModel.fromMap(
      checkDoc.data()!,
      checkDoc.id,
    );

    // Проверяем, что проверка еще активна
    if (!activityCheck.isActive || activityCheck.isExpired) {
      throw Exception('Время для подтверждения готовности истекло');
    }

    // Проверяем, что игрок в списке участников команды
    if (!activityCheck.teamMembers.contains(playerId)) {
      throw Exception('Вы не являетесь участником этой команды');
    }

    // Проверяем, что игрок еще не подтвердил готовность
    if (activityCheck.readyPlayers.contains(playerId)) {
      throw Exception('Вы уже подтвердили свою готовность');
    }

    // Добавляем игрока в список готовых
    final updatedReadyPlayers = [...activityCheck.readyPlayers, playerId];

    await _firestore
        .collection('team_activity_checks')
        .doc(checkId)
        .update({
      'readyPlayers': updatedReadyPlayers,
    });

    debugPrint('✅ Игрок $playerId подтвердил готовность в проверке $checkId');

    // Проверяем, готовы ли все игроки
    if (updatedReadyPlayers.length == activityCheck.teamMembers.length) {
      await _completeActivityCheck(checkId);
      debugPrint('🎉 Все игроки команды ${activityCheck.teamId} готовы!');
    }
  }

  /// Получить проверки активности для конкретного игрока
  Future<List<TeamActivityCheckModel>> getPlayerActivityChecks(String playerId) async {
    try {
      final snapshot = await _firestore
          .collection('team_activity_checks')
          .where('teamMembers', arrayContains: playerId)
          .where('isActive', isEqualTo: true)
          .orderBy('startedAt', descending: true)
          .get();

      final checks = snapshot.docs
          .map((doc) => TeamActivityCheckModel.fromMap(doc.data(), doc.id))
          .where((check) => !check.isExpired) // Фильтруем истекшие
          .toList();

      return checks;
    } catch (e) {
      debugPrint('❌ Ошибка получения проверок активности для игрока: $e');
      return [];
    }
  }

  /// Stream для отслеживания активных проверок игрока
  Stream<List<TeamActivityCheckModel>> watchPlayerActivityChecks(String playerId) {
    return _firestore
        .collection('team_activity_checks')
        .where('teamMembers', arrayContains: playerId)
        .where('isActive', isEqualTo: true)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamActivityCheckModel.fromMap(doc.data(), doc.id))
            .where((check) => !check.isExpired)
            .toList());
  }

  /// Stream для отслеживания проверки активности организатором
  Stream<TeamActivityCheckModel?> watchActivityCheck(String checkId) {
    return _firestore
        .collection('team_activity_checks')
        .doc(checkId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return TeamActivityCheckModel.fromMap(snapshot.data()!, snapshot.id);
        });
  }

  /// Завершить проверку активности
  Future<void> _completeActivityCheck(String checkId) async {
    await _firestore
        .collection('team_activity_checks')
        .doc(checkId)
        .update({
      'isActive': false,
      'isCompleted': true,
    });

    debugPrint('✅ Проверка активности $checkId завершена');
  }

  /// Отменить проверку активности (только организатор)
  Future<void> cancelActivityCheck(String checkId, String organizerId) async {
    final checkDoc = await _firestore
        .collection('team_activity_checks')
        .doc(checkId)
        .get();

    if (!checkDoc.exists) {
      throw Exception('Проверка активности не найдена');
    }

    final activityCheck = TeamActivityCheckModel.fromMap(
      checkDoc.data()!,
      checkDoc.id,
    );

    // Проверяем права доступа
    if (activityCheck.organizerId != organizerId) {
      throw Exception('Только организатор может отменить проверку активности');
    }

    await _firestore
        .collection('team_activity_checks')
        .doc(checkId)
        .update({
      'isActive': false,
      'isCompleted': false,
    });

    debugPrint('❌ Проверка активности $checkId отменена организатором');
  }

  /// Очистить старые проверки активности (старше 24 часов)
  Future<void> cleanupOldActivityChecks() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      
      final snapshot = await _firestore
          .collection('team_activity_checks')
          .where('startedAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      debugPrint('🧹 Удалено ${snapshot.docs.length} старых проверок активности');
    } catch (e) {
      debugPrint('❌ Ошибка очистки старых проверок активности: $e');
    }
  }
} 