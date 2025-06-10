import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/data/datasources/auth_service.dart';
import '../features/auth/data/datasources/user_service.dart';
import '../features/rooms/data/datasources/room_service.dart';
import '../features/teams/data/datasources/team_service.dart';
import '../features/teams/data/datasources/team_activity_service.dart';
import '../shared/services/storage_service.dart';
import '../features/auth/domain/entities/user_model.dart';
import '../features/rooms/domain/entities/room_model.dart';
import '../features/teams/domain/entities/team_model.dart';
import '../features/teams/domain/entities/team_activity_check_model.dart';
import '../features/teams/data/datasources/team_victory_service.dart';
import '../features/notifications/data/datasources/game_notification_service.dart';
import '../features/notifications/data/datasources/unified_notification_service.dart';

// Провайдеры для сервисов
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final roomServiceProvider = Provider<RoomService>((ref) {
  return RoomService();
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService();
});

final teamActivityServiceProvider = Provider<TeamActivityService>((ref) {
  final teamService = ref.read(teamServiceProvider);
  final gameNotificationService = ref.read(gameNotificationServiceProvider);
  return TeamActivityService(teamService, gameNotificationService);
});

// Firebase Storage отключен из-за CORS ошибок, используем S3
// final storageServiceProvider = Provider<StorageService>((ref) {
//   return StorageService();
// });

// === NOTIFICATION PROVIDERS ===

/// Сервис уведомлений о играх
final gameNotificationServiceProvider = Provider<GameNotificationService>((ref) {
  return GameNotificationService();
});

/// Stream провайдер для уведомлений о играх пользователя
final gameNotificationsStreamProvider = StreamProvider.family<List<dynamic>, String>((ref, userId) {
  final gameNotificationService = ref.read(gameNotificationServiceProvider);
  return gameNotificationService.getGameNotificationsStream(userId);
});

/// Количество непрочитанных игровых уведомлений
final unreadGameNotificationsCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final gameNotificationService = ref.read(gameNotificationServiceProvider);
  return await gameNotificationService.getUnreadCount(userId);
});

/// Провайдер для UnifiedNotificationService
final unifiedNotificationServiceProvider = Provider<UnifiedNotificationService>((ref) {
  final userService = ref.read(userServiceProvider);
  final teamService = ref.read(teamServiceProvider);
  return UnifiedNotificationService(userService, teamService);
});

/// Количество непрочитанных социальных уведомлений
final unreadSocialNotificationsCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final unifiedNotificationService = ref.read(unifiedNotificationServiceProvider);
  return await unifiedNotificationService.getUnreadNotificationsCount(userId);
});

/// Общее количество непрочитанных уведомлений (игровые + социальные)
final totalUnreadNotificationsCountProvider = StreamProvider.family<int, String>((ref, userId) {
  final gameNotificationService = ref.read(gameNotificationServiceProvider);
  
  // Слушаем изменения игровых уведомлений в реальном времени
  return gameNotificationService.getGameNotificationsStream(userId).asyncMap((gameNotifications) async {
    try {
      // Считаем непрочитанные игровые уведомления
      final gameUnreadCount = gameNotifications
          .where((notification) => !notification.isRead)
          .length;
      
      // Получаем количество социальных уведомлений
      final unifiedNotificationService = ref.read(unifiedNotificationServiceProvider);
      final socialUnreadCount = await unifiedNotificationService.getUnreadNotificationsCount(userId);
      
      final totalCount = gameUnreadCount + socialUnreadCount;
      debugPrint('🔔 Общее количество уведомлений для $userId: $totalCount (игровые: $gameUnreadCount, социальные: $socialUnreadCount)');
      return totalCount;
    } catch (e) {
      debugPrint('❌ Ошибка получения количества уведомлений: $e');
      return 0;
    }
  });
});

/// Автоинвалидируемый провайдер для уведомлений с таймером обновления
final notificationCountTimerProvider = StreamProvider.family<int, String>((ref, userId) {
  return Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now().millisecondsSinceEpoch)
      .asyncMap((_) async {
        final count = await ref.read(totalUnreadNotificationsCountProvider(userId).future);
        return count;
      });
});

// Провайдер для текущего пользователя
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.read(authServiceProvider);
  
  // Слушаем изменения состояния аутентификации Firebase
  return FirebaseAuth.instance.authStateChanges().asyncMap((firebaseUser) async {
    if (firebaseUser == null) {
      return null;
    }
    
    // Если пользователь авторизован, получаем его полную модель
    return await authService.getCurrentUserModel();
  });
});

// Провайдер для активных комнат с real-time обновлениями
final activeRoomsProvider = StreamProvider<List<RoomModel>>((ref) {
  final roomService = ref.read(roomServiceProvider);
  return roomService.watchActiveRooms();
});

// Провайдер для запланированных комнат с real-time обновлениями
final plannedRoomsProvider = StreamProvider<List<RoomModel>>((ref) {
  final roomService = ref.read(roomServiceProvider);
  return roomService.watchPlannedRooms();
});

// Провайдер для конкретной комнаты с real-time обновлениями
final roomProvider = StreamProvider.family<RoomModel?, String>((ref, roomId) {
  final roomService = ref.read(roomServiceProvider);
  return roomService.watchRoom(roomId);
});

// Провайдер для команд конкретной комнаты
final teamsProvider = StreamProvider.family<List<TeamModel>, String>((ref, roomId) {
  final teamService = ref.read(teamServiceProvider);
  return teamService.watchTeamsForRoom(roomId);
});

// Провайдер для конкретного пользователя
final userProvider = StreamProvider.family<UserModel?, String>((ref, userId) {
  final userService = ref.read(userServiceProvider);
  return userService.watchUser(userId);
});

// Провайдер для всех комнат (для поиска)
final roomsProvider = StreamProvider<List<RoomModel>>((ref) {
  final roomService = ref.read(roomServiceProvider);
  return roomService.watchAllRooms();
});

// Провайдер для всех комнат пользователя
final userRoomsProvider = StreamProvider<List<RoomModel>>((ref) async* {
  final currentUser = await ref.watch(currentUserProvider.future);
  
  if (currentUser == null) {
    yield [];
    return;
  }
  
  final roomService = ref.read(roomServiceProvider);
  yield* roomService.watchUserRooms(currentUser.id);
});

// === TEAM ACTIVITY CHECK PROVIDERS ===

/// Провайдер для активных проверок активности игрока
final playerActivityChecksProvider = StreamProvider.family<List<TeamActivityCheckModel>, String>((ref, playerId) {
  final teamService = ref.read(teamServiceProvider);
  return teamService.watchPlayerActivityChecks(playerId);
});

/// Провайдер для конкретной проверки активности
final activityCheckProvider = StreamProvider.family<TeamActivityCheckModel?, String>((ref, checkId) {
  final teamService = ref.read(teamServiceProvider);
  return teamService.watchActivityCheck(checkId);
});

/// Провайдер для активной проверки активности команды
final activeTeamActivityCheckProvider = FutureProvider.family<TeamActivityCheckModel?, String>((ref, teamId) async {
  final teamService = ref.read(teamServiceProvider);
  return await teamService.getActiveActivityCheck(teamId);
});

// === TEAM VICTORY PROVIDERS ===

/// Сервис побед команд
final teamVictoryServiceProvider = Provider<TeamVictoryService>((ref) {
  final teamService = ref.read(teamServiceProvider);
  final notificationService = ref.read(gameNotificationServiceProvider);
  return TeamVictoryService(teamService, notificationService);
});

/// Топ команд по баллам
final topTeamsProvider = FutureProvider<List<dynamic>>((ref) {
  final victoryService = ref.read(teamVictoryServiceProvider);
  return victoryService.getTopTeams(limit: 10);
});

/// История побед команды
final teamVictoriesProvider = FutureProvider.family<List<dynamic>, String>((ref, teamId) {
  final victoryService = ref.read(teamVictoryServiceProvider);
  return victoryService.getTeamVictories(teamId, limit: 10);
});

/// Проверка наличия команды-победителя для игры
final gameWinnerProvider = FutureProvider.family<dynamic, String>((ref, gameId) {
  final victoryService = ref.read(teamVictoryServiceProvider);
  return victoryService.getGameWinner(gameId);
});