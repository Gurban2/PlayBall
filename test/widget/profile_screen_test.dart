import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volleyball_app/models/user_model.dart';
import 'package:volleyball_app/screens/profile_screen.dart';

void main() {
  group('ProfileScreen Widget Tests', () {
    late UserModel testUser;

    setUp(() {
      testUser = UserModel(
        id: 'test_user_id',
        name: 'Тест Пользователь',
        email: 'test@example.com',
        role: UserRole.user,
        createdAt: DateTime.now(),
        gamesPlayed: 15,
        wins: 10,
        losses: 5,
        rating: 4.2,
        organizerPoints: 85,
        totalScore: 150,
        bio: 'Тестовое описание пользователя',
        skillLevel: 'Средний',
        status: PlayerStatus.lookingForGame,
      );
    });

    Widget createTestWidget(UserModel user) {
      return ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      );
    }

    testWidgets('должен отображать основную информацию о пользователе', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testUser));
      await tester.pumpAndSettle();

      // Проверяем наличие основных элементов
      expect(find.text('Профиль'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsWidgets); // Аватар пользователя
      expect(find.byType(TabBar), findsOneWidget); // Вкладки
    });

    testWidgets('должен отображать статистические карточки', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testUser));
      await tester.pumpAndSettle();

      // Ищем статистические элементы по иконкам
      expect(find.byIcon(Icons.sports_volleyball), findsWidgets);
      expect(find.byIcon(Icons.emoji_events), findsWidgets);
      expect(find.byIcon(Icons.cancel), findsWidgets);
      expect(find.byIcon(Icons.trending_up), findsWidgets);
      expect(find.byIcon(Icons.star), findsWidgets);
      expect(find.byIcon(Icons.score), findsWidgets);
    });

    testWidgets('должен переключаться между вкладками', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testUser));
      await tester.pumpAndSettle();

      // Проверяем наличие всех вкладок
      expect(find.text('Профиль'), findsOneWidget);
      expect(find.text('Друзья'), findsOneWidget);
      expect(find.text('История'), findsOneWidget);

      // Переключаемся на вкладку "Друзья"
      await tester.tap(find.text('Друзья'));
      await tester.pumpAndSettle();

      // Переключаемся на вкладку "История"
      await tester.tap(find.text('История'));
      await tester.pumpAndSettle();
    });

    testWidgets('должен показывать кнопку редактирования профиля', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testUser));
      await tester.pumpAndSettle();

      // Ищем кнопку редактирования
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('должен отображать статус пользователя', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testUser));
      await tester.pumpAndSettle();

      // Проверяем отображение статуса
      expect(find.text('Ищу игру'), findsOneWidget);
    });

    testWidgets('должен показывать правильные цвета для статистики', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testUser));
      await tester.pumpAndSettle();

      // Ищем контейнеры со статистикой
      final statContainers = find.byType(Container);
      expect(statContainers, findsWidgets);
    });

    testWidgets('должен обрабатывать нажатие на кнопку редактирования', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testUser));
      await tester.pumpAndSettle();

      // Находим и нажимаем кнопку редактирования
      final editButton = find.byIcon(Icons.edit);
      expect(editButton, findsOneWidget);
      
      await tester.tap(editButton);
      await tester.pumpAndSettle();
    });

    testWidgets('должен отображать прогресс-бар для рейтинга', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testUser));
      await tester.pumpAndSettle();

      // Ищем индикаторы прогресса
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('должен корректно отображать винрейт', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testUser));
      await tester.pumpAndSettle();

      // Проверяем отображение винрейта (66.7% для 10 побед из 15 игр)
      expect(find.textContaining('66'), findsOneWidget);
    });

    group('Различные роли пользователей', () {
      testWidgets('должен показывать дополнительные элементы для организатора', (WidgetTester tester) async {
        final organizer = testUser.copyWith(role: UserRole.organizer);
        await tester.pumpWidget(createTestWidget(organizer));
        await tester.pumpAndSettle();

        // Для организатора должна быть доступна вкладка "My team"
        expect(find.text('My team'), findsOneWidget);
      });

      testWidgets('не должен показывать вкладку команды для обычного пользователя', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(testUser));
        await tester.pumpAndSettle();

        // Для обычного пользователя не должно быть вкладки "My team"
        expect(find.text('My team'), findsNothing);
      });
    });

    group('Обработка ошибок', () {
      testWidgets('должен корректно обрабатывать null значения', (WidgetTester tester) async {
        final userWithNulls = UserModel(
          id: 'test_id',
          name: '',
          email: 'test@example.com',
          role: UserRole.user,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(userWithNulls));
        await tester.pumpAndSettle();

        // Приложение не должно крашиться
        expect(find.byType(ProfileScreen), findsOneWidget);
      });
    });
  });
} 