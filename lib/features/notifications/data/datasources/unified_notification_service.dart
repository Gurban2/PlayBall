import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../auth/data/datasources/user_service.dart';
import '../../../teams/data/datasources/team_service.dart';
import '../../../profile/domain/entities/friend_request_model.dart';
import '../../../teams/domain/entities/team_invitation_model.dart';
import '../../domain/entities/unified_notification_model.dart';

class UnifiedNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService;
  final TeamService _teamService;

  UnifiedNotificationService(this._userService, this._teamService);

  // Получить все входящие уведомления (заявки в друзья + приглашения в команды + уведомления об исключении)
  Future<List<UnifiedNotificationModel>> getIncomingNotifications(String userId) async {
    List<UnifiedNotificationModel> notifications = [];

    // Получаем заявки в друзья
    final friendRequests = await _userService.getIncomingFriendRequests(userId);
    for (final request in friendRequests) {
      notifications.add(UnifiedNotificationModel.friendRequest(
        id: request.id,
        toUserId: request.toUserId,
        fromUserId: request.fromUserId,
        fromUserName: request.fromUserName,
        toUserName: request.toUserName,
        fromUserPhotoUrl: request.fromUserPhotoUrl,
        toUserPhotoUrl: request.toUserPhotoUrl,
        createdAt: request.createdAt,
        status: _mapFriendRequestStatus(request.status),
        respondedAt: request.respondedAt,
      ));
    }

    // Получаем приглашения в команды
    final teamInvitations = await _teamService.getIncomingTeamInvitations(userId);
    for (final invitation in teamInvitations) {
      notifications.add(UnifiedNotificationModel.teamInvitation(
        id: invitation.id,
        toUserId: invitation.toUserId,
        fromUserId: invitation.fromUserId,
        fromUserName: invitation.fromUserName,
        toUserName: invitation.toUserName,
        teamId: invitation.teamId,
        teamName: invitation.teamName,
        fromUserPhotoUrl: invitation.fromUserPhotoUrl,
        toUserPhotoUrl: invitation.toUserPhotoUrl,
        replacedUserId: invitation.replacedUserId,
        replacedUserName: invitation.replacedUserName,
        createdAt: invitation.createdAt,
        status: _mapTeamInvitationStatus(invitation.status),
        respondedAt: invitation.respondedAt,
      ));
    }

    // Получаем уведомления об исключении из коллекции notifications
    final notificationSnapshot = await _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('type', isEqualTo: 'team_exclusion')
        .orderBy('createdAt', descending: true)
        .get();

    for (final doc in notificationSnapshot.docs) {
      final data = doc.data();
      notifications.add(UnifiedNotificationModel.teamExclusion(
        id: doc.id,
        toUserId: data['toUserId'],
        teamId: data['teamId'],
        teamName: data['teamName'],
        replacedByUserId: data['replacedByUserId'],
        replacedByUserName: data['replacedByUserName'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      ));
    }

    // Сортируем по дате создания (новые сначала)
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return notifications;
  }

  // Получить исходящие уведомления (только для организаторов/админов - заявки в друзья и приглашения в команды)
  Future<List<UnifiedNotificationModel>> getOutgoingNotifications(String userId) async {
    final List<UnifiedNotificationModel> notifications = [];

    // Получаем исходящие заявки в друзья (доступно всем)
    final outgoingFriendRequests = await _userService.getOutgoingFriendRequests(userId);
    for (final request in outgoingFriendRequests) {
      notifications.add(UnifiedNotificationModel.friendRequest(
        id: request.id,
        toUserId: request.toUserId,
        fromUserId: request.fromUserId,
        fromUserName: request.fromUserName,
        toUserName: request.toUserName,
        fromUserPhotoUrl: request.fromUserPhotoUrl,
        toUserPhotoUrl: request.toUserPhotoUrl,
        createdAt: request.createdAt,
        status: _mapFriendRequestStatus(request.status),
        respondedAt: request.respondedAt,
      ));
    }

    // Получаем исходящие приглашения в команды (только для организаторов/админов)
    try {
      final outgoingTeamInvitations = await _teamService.getOutgoingTeamInvitations(userId);
      for (final invitation in outgoingTeamInvitations) {
        notifications.add(UnifiedNotificationModel.teamInvitation(
          id: invitation.id,
          toUserId: invitation.toUserId,
          fromUserId: invitation.fromUserId,
          fromUserName: invitation.fromUserName,
          toUserName: invitation.toUserName,
          teamId: invitation.teamId,
          teamName: invitation.teamName,
          fromUserPhotoUrl: invitation.fromUserPhotoUrl,
          toUserPhotoUrl: invitation.toUserPhotoUrl,
          replacedUserId: invitation.replacedUserId,
          replacedUserName: invitation.replacedUserName,
          createdAt: invitation.createdAt,
          status: _mapTeamInvitationStatus(invitation.status),
          respondedAt: invitation.respondedAt,
        ));
      }
    } catch (e) {
      // Если пользователь не организатор/админ, просто пропускаем приглашения в команды
      debugPrint('🔍 Пользователь не может получить исходящие приглашения в команды: $e');
    }

    // Сортируем по дате создания (новые сначала)
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return notifications;
  }

  // Принять уведомление
  Future<void> acceptNotification(UnifiedNotificationModel notification) async {
    switch (notification.type) {
      case UnifiedNotificationType.friendRequest:
        await _userService.acceptFriendRequest(notification.id);
        break;
      case UnifiedNotificationType.teamInvitation:
        await _teamService.acceptTeamInvitation(notification.id);
        break;
      case UnifiedNotificationType.teamExclusion:
        // Просто помечаем как прочитанное
        await markNotificationAsRead(notification.id);
        break;
    }
  }

  // Отклонить уведомление
  Future<void> declineNotification(UnifiedNotificationModel notification) async {
    switch (notification.type) {
      case UnifiedNotificationType.friendRequest:
        await _userService.declineFriendRequest(notification.id);
        break;
      case UnifiedNotificationType.teamInvitation:
        await _teamService.declineTeamInvitation(notification.id);
        break;
      case UnifiedNotificationType.teamExclusion:
        // Просто помечаем как прочитанное
        await markNotificationAsRead(notification.id);
        break;
    }
  }

  // Отменить исходящее уведомление
  Future<void> cancelOutgoingNotification(UnifiedNotificationModel notification) async {
    switch (notification.type) {
      case UnifiedNotificationType.friendRequest:
        if (notification.fromUserId != null) {
          await _userService.cancelFriendRequest(
            notification.fromUserId!, 
            notification.toUserId,
          );
        }
        break;
      case UnifiedNotificationType.teamInvitation:
        if (notification.teamId != null) {
          await _teamService.cancelTeamInvitation(
            notification.teamId!, 
            notification.toUserId,
          );
        }
        break;
      case UnifiedNotificationType.teamExclusion:
        // Уведомления об исключении нельзя отменить
        break;
    }
  }

  // Пометить уведомление как прочитанное
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'updatedAt': Timestamp.now(),
    });
  }

  // Получить количество непрочитанных уведомлений (заявки в друзья + приглашения в команды + уведомления об исключении)
  Future<int> getUnreadNotificationsCount(String userId) async {
    int count = 0;

    // Считаем заявки в друзья
    final friendRequests = await _userService.getIncomingFriendRequests(userId);
    count += friendRequests.length;

    // Считаем приглашения в команды
    final teamInvitations = await _teamService.getIncomingTeamInvitations(userId);
    count += teamInvitations.length;

    // Считаем непрочитанные уведомления об исключении
    final notificationSnapshot = await _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    count += notificationSnapshot.docs.length;

    return count;
  }

  // Маппинг статусов
  UnifiedNotificationStatus _mapFriendRequestStatus(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return UnifiedNotificationStatus.pending;
      case FriendRequestStatus.accepted:
        return UnifiedNotificationStatus.accepted;
      case FriendRequestStatus.declined:
        return UnifiedNotificationStatus.declined;
    }
  }

  UnifiedNotificationStatus _mapTeamInvitationStatus(TeamInvitationStatus status) {
    switch (status) {
      case TeamInvitationStatus.pending:
        return UnifiedNotificationStatus.pending;
      case TeamInvitationStatus.accepted:
        return UnifiedNotificationStatus.accepted;
      case TeamInvitationStatus.declined:
        return UnifiedNotificationStatus.declined;
    }
  }
} 