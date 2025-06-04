import '../constants/constants.dart';
import '../../features/rooms/domain/entities/room_model.dart';

/// Утилита для работы с временем игр
/// Упрощает и унифицирует всю логику времени
class GameTimeUtils {
  
  /// Проверяет, можно ли присоединиться к игре
  /// Блокирует присоединение за 5 минут до начала
  static bool canJoinGame(RoomModel room) {
    if (room.status != RoomStatus.planned) return false;
    
    final now = DateTime.now();
    final joinCutoffTime = room.startTime.subtract(const Duration(minutes: 5));
    
    return now.isBefore(joinCutoffTime);
  }
  
  /// Проверяет, можно ли покинуть игру
  /// Блокирует выход за 5 минут до начала
  static bool canLeaveGame(RoomModel room) {
    if (room.status != RoomStatus.planned) return false;
    
    final now = DateTime.now();
    final leaveCutoffTime = room.startTime.subtract(const Duration(minutes: 5));
    
    return now.isBefore(leaveCutoffTime);
  }
  
  /// Проверяет, должна ли игра быть автоматически завершена
  /// Автоматически завершается в указанное время окончания (endTime)
  static bool shouldAutoCompleteGame(RoomModel room) {
    if (room.status != RoomStatus.active) return false;
    
    final now = DateTime.now();
    
    // Игра завершается автоматически в указанное время окончания
    return now.isAfter(room.endTime);
  }
  
  /// Проверяет, должна ли запланированная игра автоматически стать активной
  /// Автоматически активируется в назначенное время начала (startTime)
  static bool shouldAutoStartGame(RoomModel room) {
    if (room.status != RoomStatus.planned) return false;
    
    final now = DateTime.now();
    
    // Игра автоматически становится активной в назначенное время начала
    return now.isAfter(room.startTime);
  }
  
  /// Проверяет, просрочена ли запланированная игра (для автоотмены)
  static bool isPlannedGameExpired(RoomModel room) {
    if (room.status != RoomStatus.planned) return false;
    
    final now = DateTime.now();
    final expiredThreshold = room.startTime.add(const Duration(hours: 24));
    
    return now.isAfter(expiredThreshold);
  }
  
  /// Проверяет, можно ли отменить игру
  /// Нельзя отменить если все команды заполнены
  static bool canCancelGame(RoomModel room) {
    if (room.status != RoomStatus.planned) return false;
    
    // Для командного режима проверяем количество команд
    if (room.isTeamMode) {
      // Пока упрощенная логика - можно доработать с проверкой реальных команд
      return room.participants.length < room.maxParticipants;
    }
    
    // Для обычного режима проверяем заполненность команд
    return room.participants.length < room.maxParticipants;
  }
} 