import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/room_model.dart';

void main() {
  group('RoomModel', () {
    late RoomModel testRoom;
    late DateTime startTime;
    late DateTime endTime;
    late DateTime createdAt;

    setUp(() {
      startTime = DateTime.now().add(const Duration(hours: 2));
      endTime = startTime.add(const Duration(hours: 2));
      createdAt = DateTime.now();

      testRoom = RoomModel(
        id: 'test_room_id',
        title: 'Тестовая игра',
        description: 'Описание тестовой игры',
        location: 'Тестовая площадка',
        startTime: startTime,
        endTime: endTime,
        organizerId: 'organizer_id',
        participants: ['player1', 'player2'],
        maxParticipants: 12,
        status: RoomStatus.planned,
        gameMode: GameMode.normal,
        pricePerPerson: 500.0,
        createdAt: createdAt,
      );
    });

    group('Конструктор и основные поля', () {
      test('должен создавать комнату с корректными данными', () {
        expect(testRoom.id, 'test_room_id');
        expect(testRoom.title, 'Тестовая игра');
        expect(testRoom.description, 'Описание тестовой игры');
        expect(testRoom.location, 'Тестовая площадка');
        expect(testRoom.organizerId, 'organizer_id');
        expect(testRoom.participants.length, 2);
        expect(testRoom.maxParticipants, 12);
        expect(testRoom.status, RoomStatus.planned);
        expect(testRoom.gameMode, GameMode.normal);
        expect(testRoom.pricePerPerson, 500.0);
      });

      test('должен создавать комнату со значениями по умолчанию', () {
        final roomWithDefaults = RoomModel(
          id: 'test_id',
          title: 'Тест',
          description: 'Описание',
          location: 'Место',
          startTime: startTime,
          endTime: endTime,
          organizerId: 'organizer',
          maxParticipants: 10,
          pricePerPerson: 0.0,
          createdAt: createdAt,
        );

        expect(roomWithDefaults.participants, []);
        expect(roomWithDefaults.status, RoomStatus.planned);
        expect(roomWithDefaults.gameMode, GameMode.normal);
        expect(roomWithDefaults.numberOfTeams, 2);
        expect(roomWithDefaults.winnerTeamId, null);
        expect(roomWithDefaults.gameStats, null);
      });
    });

    group('Вычисляемые свойства', () {
      test('isFull должен корректно определять заполненность', () {
        expect(testRoom.isFull, false);

        final fullRoom = testRoom.copyWith(
          participants: List.generate(12, (index) => 'player$index'),
        );
        expect(fullRoom.isFull, true);
      });

      test('hasStarted должен корректно определять начало игры', () {
        expect(testRoom.hasStarted, false);

        final startedRoom = testRoom.copyWith(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(startedRoom.hasStarted, true);
      });

      test('hasEnded должен корректно определять завершение игры', () {
        expect(testRoom.hasEnded, false);

        final endedRoom = testRoom.copyWith(
          endTime: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(endedRoom.hasEnded, true);
      });

      test('режимы игры должны определяться корректно', () {
        expect(testRoom.isNormalMode, true);
        expect(testRoom.isTeamMode, false);

        final teamRoom = testRoom.copyWith(gameMode: GameMode.team_friendly);
        expect(teamRoom.isNormalMode, false);
        expect(teamRoom.isTeamMode, true);
        expect(teamRoom.isFriendlyMode, true);
        expect(teamRoom.isTournamentMode, false);

        final tournamentRoom = testRoom.copyWith(gameMode: GameMode.tournament);
        expect(tournamentRoom.isTeamMode, true);
        expect(tournamentRoom.isTournamentMode, true);
        expect(tournamentRoom.isFriendlyMode, false);
      });
    });

    group('copyWith', () {
      test('должен создавать копию с обновленными полями', () {
        final updatedRoom = testRoom.copyWith(
          title: 'Обновленное название',
          maxParticipants: 20,
          status: RoomStatus.active,
        );

        expect(updatedRoom.title, 'Обновленное название');
        expect(updatedRoom.maxParticipants, 20);
        expect(updatedRoom.status, RoomStatus.active);
        expect(updatedRoom.id, 'test_room_id'); // не изменилось
        expect(updatedRoom.location, 'Тестовая площадка'); // не изменилось
      });

      test('должен сохранять исходные значения если null', () {
        final copyRoom = testRoom.copyWith();

        expect(copyRoom.title, testRoom.title);
        expect(copyRoom.description, testRoom.description);
        expect(copyRoom.maxParticipants, testRoom.maxParticipants);
      });
    });

    group('toMap и fromMap', () {
      test('должен конвертироваться в Map корректно', () {
        final map = testRoom.toMap();

        expect(map['id'], 'test_room_id');
        expect(map['title'], 'Тестовая игра');
        expect(map['description'], 'Описание тестовой игры');
        expect(map['location'], 'Тестовая площадка');
        expect(map['organizerId'], 'organizer_id');
        expect(map['participants'], ['player1', 'player2']);
        expect(map['maxParticipants'], 12);
        expect(map['status'], 'planned');
        expect(map['gameMode'], 'normal');
        expect(map['pricePerPerson'], 500.0);
        expect(map['numberOfTeams'], 2);
      });

      test('должен создаваться из Map корректно', () {
        final map = {
          'id': 'map_room_id',
          'title': 'Комната из Map',
          'description': 'Описание из Map',
          'location': 'Место из Map',
          'startTime': startTime,
          'endTime': endTime,
          'organizerId': 'map_organizer',
          'participants': ['player1', 'player2', 'player3'],
          'maxParticipants': 10,
          'status': 'active',
          'gameMode': 'team_friendly',
          'pricePerPerson': 300.0,
          'numberOfTeams': 4,
          'createdAt': createdAt,
        };

        final room = RoomModel.fromMap(map);

        expect(room.id, 'map_room_id');
        expect(room.title, 'Комната из Map');
        expect(room.description, 'Описание из Map');
        expect(room.location, 'Место из Map');
        expect(room.organizerId, 'map_organizer');
        expect(room.participants, ['player1', 'player2', 'player3']);
        expect(room.maxParticipants, 10);
        expect(room.status, RoomStatus.active);
        expect(room.gameMode, GameMode.team_friendly);
        expect(room.pricePerPerson, 300.0);
        expect(room.numberOfTeams, 4);
      });

      test('должен корректно обрабатывать некорректные статусы', () {
        final mapWithInvalidStatus = {
          'id': 'test_id',
          'title': 'Test',
          'description': 'Desc',
          'location': 'Location',
          'startTime': startTime,
          'endTime': endTime,
          'organizerId': 'organizer',
          'maxParticipants': 10,
          'status': 'invalid_status',
          'gameMode': 'invalid_mode',
          'pricePerPerson': 100.0,
          'createdAt': createdAt,
        };

        final room = RoomModel.fromMap(mapWithInvalidStatus);

        expect(room.status, RoomStatus.planned); // default
        expect(room.gameMode, GameMode.normal); // default
      });
    });
  });

  group('GameModeExtension', () {
    test('isTeamMode должен правильно определять командные режимы', () {
      expect(GameMode.normal.isTeamMode, false);
      expect(GameMode.team_friendly.isTeamMode, true);
      expect(GameMode.tournament.isTeamMode, true);
    });

    test('isNormalMode должен правильно определять обычный режим', () {
      expect(GameMode.normal.isNormalMode, true);
      expect(GameMode.team_friendly.isNormalMode, false);
      expect(GameMode.tournament.isNormalMode, false);
    });
  });

  group('RoomStatus enum', () {
    test('должен содержать все необходимые статусы', () {
      expect(RoomStatus.values.length, 4);
      expect(RoomStatus.values.contains(RoomStatus.planned), true);
      expect(RoomStatus.values.contains(RoomStatus.active), true);
      expect(RoomStatus.values.contains(RoomStatus.completed), true);
      expect(RoomStatus.values.contains(RoomStatus.cancelled), true);
    });
  });

  group('GameMode enum', () {
    test('должен содержать все необходимые режимы', () {
      expect(GameMode.values.length, 3);
      expect(GameMode.values.contains(GameMode.normal), true);
      expect(GameMode.values.contains(GameMode.team_friendly), true);
      expect(GameMode.values.contains(GameMode.tournament), true);
    });
  });
} 