import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import '../services/user_service.dart';
import '../services/team_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/team_model.dart';

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

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
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