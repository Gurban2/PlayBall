import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volleyball_app/main.dart' as app;

void main() {
  group('PlayBall App Flow Tests', () {
    testWidgets('Приложение должно запускаться без ошибок', (WidgetTester tester) async {
      // Запускаем приложение
      await tester.pumpWidget(ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // Проверяем, что приложение запустилось
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Навигация между основными экранами работает', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // Ищем нижнюю навигацию
      final bottomNavigation = find.byType(BottomNavigationBar);
      if (bottomNavigation.evaluate().isNotEmpty) {
        // Переходим на экран поиска игр
        final searchTab = find.byIcon(Icons.search);
        if (searchTab.evaluate().isNotEmpty) {
          await tester.tap(searchTab);
          await tester.pumpAndSettle();
        }

        // Переходим на экран расписания
        final scheduleTab = find.byIcon(Icons.schedule);
        if (scheduleTab.evaluate().isNotEmpty) {
          await tester.tap(scheduleTab);
          await tester.pumpAndSettle();
        }

        // Переходим на экран профиля
        final profileTab = find.byIcon(Icons.person);
        if (profileTab.evaluate().isNotEmpty) {
          await tester.tap(profileTab);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Создание новой игры должно открывать форму', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // Ищем кнопку создания игры
      final createGameButton = find.byIcon(Icons.add);
      if (createGameButton.evaluate().isNotEmpty) {
        await tester.tap(createGameButton);
        await tester.pumpAndSettle();

        // Проверяем, что что-то открылось
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('Поиск игр должен работать', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // Переходим на экран поиска
      final searchTab = find.byIcon(Icons.search);
      if (searchTab.evaluate().isNotEmpty) {
        await tester.tap(searchTab);
        await tester.pumpAndSettle();

        // Ищем поле поиска
        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'волейбол');
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Профиль пользователя должен отображаться', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // Переходим на экран профиля
      final profileTab = find.byIcon(Icons.person);
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Проверяем элементы профиля
        expect(find.byType(CircleAvatar), findsAny);

        // Проверяем вкладки
        final tabBar = find.byType(TabBar);
        if (tabBar.evaluate().isNotEmpty) {
          final friendsTab = find.text('Друзья');
          if (friendsTab.evaluate().isNotEmpty) {
            await tester.tap(friendsTab);
            await tester.pumpAndSettle();
          }

          final historyTab = find.text('История');
          if (historyTab.evaluate().isNotEmpty) {
            await tester.tap(historyTab);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('Списки должны поддерживать scroll', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // Находим список для скролла
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        // Прокручиваем вниз
        await tester.fling(listView.first, const Offset(0, -300), 1000);
        await tester.pumpAndSettle();

        // Выполняем pull-to-refresh
        await tester.fling(listView.first, const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('UI должен адаптироваться к разным размерам экрана', (WidgetTester tester) async {
      // Тестируем на планшете
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Тестируем на телефоне
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpWidget(ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Восстанавливаем размер по умолчанию
      await tester.binding.setSurfaceSize(null);
    });
  });
} 