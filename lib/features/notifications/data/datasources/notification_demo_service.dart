import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../domain/entities/game_notification_model.dart';
import 'game_notification_service.dart';

/// Демонстрационный сервис для тестирования системы уведомлений
class NotificationDemoService {
  final GameNotificationService _gameNotificationService;
  final Uuid _uuid = const Uuid();

  NotificationDemoService(this._gameNotificationService);

  /// Создать тестовые уведомления для демонстрации
  Future<void> createDemoNotifications(UserModel currentUser) async {
    try {
      debugPrint('🎭 Создаем демонстрационные уведомления для ${currentUser.name}');

      // Создаем фиктивную комнату
      final demoRoom = RoomModel(
        id: _uuid.v4(),
        title: 'Волейбол на пляже Южном',
        description: 'Дружеская игра на песчаном корте',
        location: 'Пляж Южный, корт №3',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
        organizerId: 'demo_organizer_id',
        participants: [currentUser.id, 'player2', 'player3'],
        maxParticipants: 12,
        pricePerPerson: 300.0,
        createdAt: DateTime.now(),
      );

      // Создаем фиктивного организатора
      final demoOrganizer = UserModel(
        id: 'demo_organizer_id',
        email: 'organizer@demo.com',
        name: 'Алексей Петров',
        role: UserRole.organizer,
        createdAt: DateTime.now(),
        gamesPlayed: 45,
        wins: 28,
        losses: 17,
      );

      // 1. Уведомление о новой игре
      await _gameNotificationService.notifyGameCreated(
        room: demoRoom,
        organizer: demoOrganizer,
        specificRecipients: [currentUser.id],
      );

      // 2. Уведомление об изменениях в игре
      await _gameNotificationService.notifyGameUpdated(
        room: demoRoom.copyWith(
          participants: [currentUser.id, 'player2', 'player3', 'player4'],
        ),
        organizer: demoOrganizer,
        changes: 'Добавлен новый участник',
      );

      // 3. Уведомление о скором начале игры
      await _gameNotificationService.notifyGameStarting(
        room: demoRoom.copyWith(
          startTime: DateTime.now().add(const Duration(minutes: 30)),
        ),
        organizer: demoOrganizer,
        minutesLeft: 30,
      );

      // 4. Уведомление о присоединении игрока
      await _gameNotificationService.notifyPlayerJoined(
        room: demoRoom,
        organizer: demoOrganizer,
        player: UserModel(
          id: 'new_player_id',
          email: 'newplayer@demo.com',
          name: 'Мария Иванова',
          role: UserRole.user,
          createdAt: DateTime.now(),
          gamesPlayed: 12,
          wins: 8,
          losses: 4,
        ),
      );

      // 5. Создаем завершенную игру для демонстрации
      final completedRoom = demoRoom.copyWith(
        title: 'Турнир "Летний кубок"',
        status: RoomStatus.completed,
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await _gameNotificationService.notifyGameEnded(
        room: completedRoom,
        organizer: demoOrganizer,
        winnerTeamName: 'Команда Молния',
      );

      // 6. Отмененная игра
      final cancelledRoom = demoRoom.copyWith(
        title: 'Игра в спортзале школы №5',
        status: RoomStatus.cancelled,
        startTime: DateTime.now().add(const Duration(days: 1)),
      );

      await _gameNotificationService.notifyGameCancelled(
        room: cancelledRoom,
        organizer: demoOrganizer,
        reason: 'Плохая погода',
      );

      debugPrint('✅ Создано 6 демонстрационных уведомлений');

    } catch (e) {
      debugPrint('❌ Ошибка создания демонстрационных уведомлений: $e');
      rethrow;
    }
  }

  /// Создать разнообразные тестовые уведомления
  Future<void> createVarietyDemoNotifications(UserModel currentUser) async {
    try {
      debugPrint('🌈 Создаем разнообразные демонстрационные уведомления');

      final organizers = [
        UserModel(
          id: 'org1',
          email: 'org1@demo.com',
          name: 'Дмитрий Козлов',
          role: UserRole.organizer,
          createdAt: DateTime.now(),
          gamesPlayed: 150,
          wins: 95,
          losses: 55,
        ),
        UserModel(
          id: 'org2',
          email: 'org2@demo.com',
          name: 'Елена Смирнова',
          role: UserRole.organizer,
          createdAt: DateTime.now(),
          gamesPlayed: 89,
          wins: 67,
          losses: 22,
        ),
      ];

      final rooms = [
        RoomModel(
          id: _uuid.v4(),
          title: 'Утренняя разминка',
          description: 'Легкая игра для начала дня',
          location: 'Стадион "Динамо"',
          startTime: DateTime.now().add(const Duration(hours: 16)),
          endTime: DateTime.now().add(const Duration(hours: 18)),
          organizerId: organizers[0].id,
          participants: [currentUser.id],
          maxParticipants: 8,
          pricePerPerson: 200.0,
          createdAt: DateTime.now(),
        ),
        RoomModel(
          id: _uuid.v4(),
          title: 'Вечерний турнир',
          description: 'Соревновательная игра',
          location: 'Спортивный комплекс "Арена"',
          startTime: DateTime.now().add(const Duration(days: 1, hours: 3)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 5)),
          organizerId: organizers[1].id,
          participants: [currentUser.id, 'p1', 'p2', 'p3'],
          maxParticipants: 16,
          pricePerPerson: 500.0,
          createdAt: DateTime.now(),
        ),
      ];

      // Разнообразные уведомления
      for (int i = 0; i < organizers.length; i++) {
        final organizer = organizers[i];
        final room = rooms[i];

        // Новая игра
        await _gameNotificationService.notifyGameCreated(
          room: room,
          organizer: organizer,
          specificRecipients: [currentUser.id],
        );

        // Игра скоро начнется (разное время)
        await _gameNotificationService.notifyGameStarting(
          room: room,
          organizer: organizer,
          minutesLeft: i == 0 ? 15 : 60,
        );
      }

      // Дополнительные события
      await Future.delayed(const Duration(milliseconds: 100));

      // Игра началась
      await _gameNotificationService.notifyGameStarted(
        room: rooms[0],
        organizer: organizers[0],
      );

      // Изменения в игре
      await _gameNotificationService.notifyGameUpdated(
        room: rooms[1],
        organizer: organizers[1],
        changes: 'Изменено время начала на 30 минут позже',
      );

      debugPrint('✅ Создано множество разнообразных уведомлений');

    } catch (e) {
      debugPrint('❌ Ошибка создания разнообразных уведомлений: $e');
      rethrow;
    }
  }

  /// Очистить все тестовые уведомления
  Future<void> clearDemoNotifications(String userId) async {
    try {
      debugPrint('🧹 Очищаем демонстрационные уведомления для пользователя: $userId');

      // Получаем все уведомления пользователя
      final notifications = await _gameNotificationService.getGameNotifications(userId);
      
      // Удаляем все уведомления от демонстрационных организаторов
      final demoOrganizerIds = [
        'demo_organizer_id',
        'org1',
        'org2',
      ];

      for (final notification in notifications) {
        if (demoOrganizerIds.contains(notification.organizerId)) {
          await _gameNotificationService.deleteNotification(notification.id);
        }
      }

      debugPrint('✅ Демонстрационные уведомления очищены');

    } catch (e) {
      debugPrint('❌ Ошибка очистки демонстрационных уведомлений: $e');
      rethrow;
    }
  }

  /// Симуляция real-time уведомлений
  Future<void> simulateRealTimeNotifications(UserModel currentUser) async {
    try {
      debugPrint('⚡ Запускаем симуляцию real-time уведомлений');

      final organizer = UserModel(
        id: 'realtime_org',
        email: 'realtime@demo.com',
        name: 'Сергей Волков',
        role: UserRole.organizer,
        createdAt: DateTime.now(),
        gamesPlayed: 75,
        wins: 50,
        losses: 25,
      );

      final room = RoomModel(
        id: _uuid.v4(),
        title: 'Real-time демо игра',
        description: 'Демонстрация уведомлений в реальном времени',
        location: 'Виртуальный корт',
        startTime: DateTime.now().add(const Duration(minutes: 5)),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        organizerId: organizer.id,
        participants: [currentUser.id],
        maxParticipants: 10,
        pricePerPerson: 100.0,
        createdAt: DateTime.now(),
      );

      // Серия уведомлений с задержками
      await _gameNotificationService.notifyGameCreated(
        room: room,
        organizer: organizer,
        specificRecipients: [currentUser.id],
      );

      await Future.delayed(const Duration(seconds: 2));

      await _gameNotificationService.notifyPlayerJoined(
        room: room,
        organizer: organizer,
        player: UserModel(
          id: 'rt_player1',
          email: 'player1@demo.com',
          name: 'Анна Петрова',
          role: UserRole.user,
          createdAt: DateTime.now(),
          gamesPlayed: 25,
          wins: 15,
          losses: 10,
        ),
      );

      await Future.delayed(const Duration(seconds: 3));

      await _gameNotificationService.notifyGameStarting(
        room: room,
        organizer: organizer,
        minutesLeft: 5,
      );

      debugPrint('✅ Real-time симуляция завершена');

    } catch (e) {
      debugPrint('❌ Ошибка симуляции real-time уведомлений: $e');
      rethrow;
    }
  }
} 