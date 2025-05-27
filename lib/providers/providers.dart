import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';

// Провайдеры для сервисов
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Провайдер для текущего пользователя
final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  final authService = ref.read(authServiceProvider);
  
  // Сначала проверяем, авторизован ли пользователь
  final isLoggedIn = await authService.isUserLoggedIn();
  if (!isLoggedIn) {
    yield null;
    return;
  }
  
  // Если авторизован, получаем данные пользователя
  final user = await authService.getCurrentUserModel();
  yield user;
  
  // TODO: В будущем здесь можно добавить подписку на изменения пользователя
  // через Firestore stream
});

// Провайдер для активных комнат с real-time обновлениями
final activeRoomsProvider = StreamProvider<List<RoomModel>>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getActiveRoomsStream();
});

// Провайдер для запланированных комнат с real-time обновлениями
final plannedRoomsProvider = StreamProvider<List<RoomModel>>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getPlannedRoomsStream();
});

// Провайдер для конкретной комнаты с real-time обновлениями
final roomProvider = StreamProvider.family<RoomModel?, String>((ref, roomId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getRoomStream(roomId);
});

// Провайдер для всех комнат пользователя
final userRoomsProvider = StreamProvider<List<RoomModel>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield [];
    return;
  }
  
  final firestoreService = ref.read(firestoreServiceProvider);
  yield* firestoreService.getUserRoomsStream(user.id);
}); 