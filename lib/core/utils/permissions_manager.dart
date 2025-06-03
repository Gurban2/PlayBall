import '../../features/auth/domain/entities/user_model.dart';
import '../../features/rooms/domain/entities/room_model.dart';

enum Permission {
  createRoom,
  editRoom,
  deleteRoom,
  kickPlayer,
  manageTeams,
  moderateChat,
  viewPrivateInfo,
  manageUsers,
}

class PermissionsManager {
  // Основная проверка прав
  static bool canEditRoom(UserModel user, RoomModel room) {
    return user.role == UserRole.admin || room.organizerId == user.id;
  }

  static bool canJoinRoom(UserModel user, RoomModel room) {
    return room.status == RoomStatus.planned && 
           !room.isFull && 
           !room.participants.contains(user.id);
  }

  static bool canLeaveRoom(UserModel user, RoomModel room) {
    return room.participants.contains(user.id) && 
           room.status == RoomStatus.planned;
  }

  // Получение доступных действий
  static List<String> getRoomActions(UserModel user, RoomModel room) {
    final actions = <String>[];
    
    if (canJoinRoom(user, room)) actions.add('join');
    if (canLeaveRoom(user, room)) actions.add('leave');
    if (canEditRoom(user, room)) actions.add('edit');
    
    return actions;
  }

  // Проверка лимитов для пользователя
  static bool checkUserLimits(UserModel user) {
    // Новички могут участвовать только в 3 играх одновременно
    if (user.experienceLevel == 'Новичок' && user.recentGames.length >= 3) {
      return false;
    }
    
    return true;
  }

  // Получение описания роли
  static String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор - полный доступ ко всем функциям';
      case UserRole.organizer:
        return 'Организатор - может создавать и управлять играми';
      case UserRole.user:
        return 'Пользователь - может участвовать в играх';
    }
  }
} 