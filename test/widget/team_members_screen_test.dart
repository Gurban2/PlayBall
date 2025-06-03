import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volleyball_app/models/user_model.dart';
import 'package:volleyball_app/screens/team_members_screen.dart';

void main() {
  group('TeamMembersScreen Widget Tests', () {
    Widget createTestWidget() {
      return ProviderScope(
        child: MaterialApp(
          home: TeamMembersScreen(
            teamId: 'test_team_id',
            teamName: 'Тестовая команда',
          ),
        ),
      );
    }

    testWidgets('должен отображать заголовок экрана', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Участники команды'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('должен отображать список участников команды', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Проверяем наличие списка
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('должен показывать индикатор загрузки', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // При начальной загрузке должен показываться индикатор
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('должен показывать RefreshIndicator для pull-to-refresh', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    group('Карточки участников', () {
      testWidgets('должен отображать информацию об участнике', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Ищем элементы карточки участника
        expect(find.byType(Card), findsWidgets);
        expect(find.byType(CircleAvatar), findsWidgets);
        expect(find.byType(ListTile), findsWidgets);
      });

      testWidgets('должен показывать индикатор капитана', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Ищем корону капитана
        expect(find.byIcon(Icons.star), findsWidgets);
      });

      testWidgets('должен показывать кнопки управления друзьями', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Ищем кнопки добавления/удаления друзей
        expect(find.byIcon(Icons.person_add), findsWidgets);
        expect(find.byIcon(Icons.person_remove), findsWidgets);
      });

      testWidgets('должен обрабатывать нажатие на карточку участника', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Находим и нажимаем на карточку
        final memberCard = find.byType(Card).first;
        expect(memberCard, findsOneWidget);
        
        await tester.tap(memberCard);
        await tester.pumpAndSettle();
      });
    });

    group('Статистика участников', () {
      testWidgets('должен отображать статистику игр', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Ищем элементы статистики
        expect(find.byIcon(Icons.sports_volleyball), findsWidgets);
        expect(find.byIcon(Icons.emoji_events), findsWidgets);
        expect(find.byIcon(Icons.cancel), findsWidgets);
      });

      testWidgets('должен показывать рейтинг участников', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Ищем звездочки рейтинга
        expect(find.byIcon(Icons.star), findsWidgets);
      });

      testWidgets('должен отображать винрейт', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Ищем процентные значения винрейта
        expect(find.textContaining('%'), findsWidgets);
      });
    });

    group('Управление друзьями', () {
      testWidgets('должен обрабатывать добавление в друзья', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Находим кнопку добавления в друзья
        final addFriendButton = find.byIcon(Icons.person_add);
        if (addFriendButton.evaluate().isNotEmpty) {
          await tester.tap(addFriendButton.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('должен обрабатывать удаление из друзей', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Находим кнопку удаления из друзей
        final removeFriendButton = find.byIcon(Icons.person_remove);
        if (removeFriendButton.evaluate().isNotEmpty) {
          await tester.tap(removeFriendButton.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('должен показывать разные кнопки для друзей и не друзей', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Проверяем наличие разных типов кнопок
        final addButtons = find.byIcon(Icons.person_add);
        final removeButtons = find.byIcon(Icons.person_remove);
        
        // Хотя бы одна из кнопок должна присутствовать
        expect(addButtons.evaluate().isNotEmpty || removeButtons.evaluate().isNotEmpty, true);
      });
    });

    group('Pull-to-refresh функционал', () {
      testWidgets('должен поддерживать pull-to-refresh', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Выполняем pull-to-refresh жест
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pump();
        
        // Должен показаться индикатор обновления
        expect(find.byType(RefreshIndicator), findsOneWidget);
        
        await tester.pumpAndSettle();
      });
    });

    group('Состояния загрузки и ошибок', () {
      testWidgets('должен показывать сообщение при пустой команде', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Если команда пустая, должно быть сообщение
        expect(find.text('Команда пуста'), findsAny);
      });

      testWidgets('должен корректно обрабатывать ошибки загрузки', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Приложение не должно крашиться при ошибках
        expect(find.byType(TeamMembersScreen), findsOneWidget);
      });
    });

    group('Навигация', () {
      testWidgets('должен иметь кнопку назад в AppBar', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(BackButton), findsOneWidget);
      });

      testWidgets('должен обрабатывать нажатие кнопки назад', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);
        
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      });
    });

    group('Responsive design', () {
      testWidgets('должен корректно отображаться на разных размерах экрана', (WidgetTester tester) async {
        // Тестируем на маленьком экране
        await tester.binding.setSurfaceSize(const Size(400, 600));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(TeamMembersScreen), findsOneWidget);

        // Тестируем на большом экране
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(TeamMembersScreen), findsOneWidget);

        // Восстанавливаем размер по умолчанию
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
} 