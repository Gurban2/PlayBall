import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel', () {
    late UserModel testUser;
    
    setUp(() {
      testUser = UserModel(
        id: 'test_id',
        name: 'Тест Пользователь',
        email: 'test@example.com',
        role: UserRole.user,
        createdAt: DateTime.now(),
        gamesPlayed: 10,
        wins: 7,
        losses: 3,
      );
    });

    group('Конструктор и основные поля', () {
      test('должен создавать пользователя с корректными данными', () {
        expect(testUser.id, 'test_id');
        expect(testUser.name, 'Тест Пользователь');
        expect(testUser.email, 'test@example.com');
        expect(testUser.role, UserRole.user);
        expect(testUser.gamesPlayed, 10);
        expect(testUser.wins, 7);
        expect(testUser.losses, 3);
      });

      test('должен создавать пользователя со значениями по умолчанию', () {
        final userWithDefaults = UserModel(
          id: 'test_id',
          name: 'Тест',
          email: 'test@example.com',
          role: UserRole.user,
          createdAt: DateTime.now(),
        );

        expect(userWithDefaults.gamesPlayed, 0);
        expect(userWithDefaults.wins, 0);
        expect(userWithDefaults.losses, 0);
        expect(userWithDefaults.rating, 0.0);
        expect(userWithDefaults.skillLevel, 'Начинающий');
        expect(userWithDefaults.organizerPoints, 0);
        expect(userWithDefaults.isTeamCaptain, false);
        expect(userWithDefaults.status, PlayerStatus.lookingForGame);
      });
    });

    group('Вычисляемые свойства', () {
      test('winRate должен корректно вычисляться', () {
        expect(testUser.winRate, 70.0);
        
        final userWithoutGames = UserModel(
          id: 'test_id',
          name: 'Тест',
          email: 'test@example.com',
          role: UserRole.user,
          createdAt: DateTime.now(),
        );
        expect(userWithoutGames.winRate, 0.0);
      });

      test('hasPlayedGames должен возвращать правильное значение', () {
        expect(testUser.hasPlayedGames, true);
        
        final userWithoutGames = UserModel(
          id: 'test_id',
          name: 'Тест',
          email: 'test@example.com',
          role: UserRole.user,
          createdAt: DateTime.now(),
        );
        expect(userWithoutGames.hasPlayedGames, false);
      });

      test('experienceLevel должен корректно определяться', () {
        final novice = testUser.copyWith(gamesPlayed: 3);
        expect(novice.experienceLevel, 'Новичок');

        final amateur = testUser.copyWith(gamesPlayed: 15);
        expect(amateur.experienceLevel, 'Любитель');

        final experienced = testUser.copyWith(gamesPlayed: 35);
        expect(experienced.experienceLevel, 'Опытный');

        final expert = testUser.copyWith(gamesPlayed: 55);
        expect(expert.experienceLevel, 'Эксперт');
      });

      test('statusDisplayName должен возвращать правильное название', () {
        final lookingUser = testUser.copyWith(status: PlayerStatus.lookingForGame);
        expect(lookingUser.statusDisplayName, 'Ищу игру');

        final unavailableUser = testUser.copyWith(status: PlayerStatus.unavailable);
        expect(unavailableUser.statusDisplayName, 'Недоступен');

        final freeUser = testUser.copyWith(status: PlayerStatus.freeTonight);
        expect(freeUser.statusDisplayName, 'Свободен сегодня вечером');
      });
    });

    group('copyWith', () {
      test('должен создавать копию с обновленными полями', () {
        final updatedUser = testUser.copyWith(
          name: 'Новое Имя',
          gamesPlayed: 20,
          wins: 15,
        );

        expect(updatedUser.name, 'Новое Имя');
        expect(updatedUser.gamesPlayed, 20);
        expect(updatedUser.wins, 15);
        expect(updatedUser.losses, 3); // не изменилось
        expect(updatedUser.id, 'test_id'); // не изменилось
      });

      test('должен сохранять исходные значения если null', () {
        final copyUser = testUser.copyWith();

        expect(copyUser.name, testUser.name);
        expect(copyUser.email, testUser.email);
        expect(copyUser.gamesPlayed, testUser.gamesPlayed);
      });
    });

    group('PlayerRef', () {
      test('должен создаваться корректно из Map', () {
        final map = {
          'id': 'player_id',
          'name': 'Игрок Тест',
          'gamesPlayedTogether': 5,
          'winsTogetherCount': 3,
          'winRateTogether': 60.0,
        };

        final playerRef = PlayerRef.fromMap(map);

        expect(playerRef.id, 'player_id');
        expect(playerRef.name, 'Игрок Тест');
        expect(playerRef.gamesPlayedTogether, 5);
        expect(playerRef.winsTogetherCount, 3);
        expect(playerRef.winRateTogether, 60.0);
      });

      test('должен конвертироваться в Map корректно', () {
        const playerRef = PlayerRef(
          id: 'player_id',
          name: 'Игрок Тест',
          gamesPlayedTogether: 5,
          winsTogetherCount: 3,
          winRateTogether: 60.0,
        );

        final map = playerRef.toMap();

        expect(map['id'], 'player_id');
        expect(map['name'], 'Игрок Тест');
        expect(map['gamesPlayedTogether'], 5);
        expect(map['winsTogetherCount'], 3);
        expect(map['winRateTogether'], 60.0);
      });
    });

    group('GameRef', () {
      test('должен создаваться корректно из Map', () {
        final testDate = DateTime(2024, 1, 15);
        final map = {
          'id': 'game_id',
          'title': 'Тестовая игра',
          'location': 'Тестовая площадка',
          'date': Timestamp.fromDate(testDate),
          'result': 'win',
          'teammates': ['player1', 'player2'],
        };

        final gameRef = GameRef.fromMap(map);

        expect(gameRef.id, 'game_id');
        expect(gameRef.title, 'Тестовая игра');
        expect(gameRef.location, 'Тестовая площадка');
        expect(gameRef.date.year, testDate.year);
        expect(gameRef.date.month, testDate.month);
        expect(gameRef.date.day, testDate.day);
        expect(gameRef.result, 'win');
        expect(gameRef.teammates, ['player1', 'player2']);
      });

      test('должен конвертироваться в Map корректно', () {
        final testDate = DateTime(2024, 1, 15);
        final gameRef = GameRef(
          id: 'game_id',
          title: 'Тестовая игра',
          location: 'Тестовая площадка',
          date: testDate,
          result: 'win',
          teammates: ['player1', 'player2'],
        );

        final map = gameRef.toMap();

        expect(map['id'], 'game_id');
        expect(map['title'], 'Тестовая игра');
        expect(map['location'], 'Тестовая площадка');
        expect(map['result'], 'win');
        expect(map['teammates'], ['player1', 'player2']);
      });
    });
  });
} 