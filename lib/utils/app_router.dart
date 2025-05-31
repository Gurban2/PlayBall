import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/create_room_screen.dart';
import '../screens/room_screen.dart';
import '../screens/team_screen.dart';
import '../screens/team_selection_screen.dart';
import '../screens/search_games_screen.dart';
import '../screens/team_members_screen.dart';
import '../screens/team_view_screen.dart';
import '../screens/player_profile_screen.dart';
import '../screens/organizer_dashboard_screen.dart';
import '../screens/friend_requests_screen.dart';
import '../screens/team_invitations_screen.dart';
import '../screens/team_applications_screen.dart';
import '../services/auth_service.dart';
import 'constants.dart';

// Простые утилиты навигации
class Routes {
  static String room(String id) => '/room/$id';
  static String player(String id) => '/player/$id';
  static String team(String roomId) => '/team/$roomId';
}

class AppRouter {
  static final AuthService _authService = AuthService();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.welcome,
    redirect: (BuildContext context, GoRouterState state) async {
      final isLoggedIn = await _authService.isUserLoggedIn();
      final currentPath = state.uri.path;
      
      // Страницы, которые требуют авторизации
      final protectedRoutes = [
        AppRoutes.profile,
        AppRoutes.createRoom,
      ];
      
      // Проверяем, является ли текущий путь защищенным
      final isProtectedRoute = protectedRoutes.any((route) => currentPath.startsWith(route));
      
      // Если пользователь не авторизован и пытается попасть на защищенную страницу
      if (!isLoggedIn && isProtectedRoute) {
        return AppRoutes.login;
      }

      return null; // Не перенаправляем
    },
    routes: [
      // Приветствующая страница
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Экран входа
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Экран регистрации
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Главный экран с навигацией
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainScreen(initialIndex: 0),
      ),

      // Расписание игр
      GoRoute(
        path: AppRoutes.schedule,
        name: 'schedule',
        builder: (context, state) => const MainScreen(initialIndex: 0),
      ),

      // Поиск игр
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const MainScreen(initialIndex: 1),
      ),

      // Профиль пользователя
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const MainScreen(initialIndex: 2),
      ),

      // Создание комнаты
      GoRoute(
        path: AppRoutes.createRoom,
        name: 'create-room',
        builder: (context, state) => const CreateRoomScreen(),
      ),

      // Детали комнаты
      GoRoute(
        path: '${AppRoutes.room}/:roomId',
        name: 'room',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomScreen(roomId: roomId);
        },
      ),

      // Управление командами
      GoRoute(
        path: '${AppRoutes.team}/:roomId',
        name: 'team',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return TeamScreen(roomId: roomId);
        },
      ),

      // Выбор команды
      GoRoute(
        path: '/team-selection/:roomId',
        name: 'team-selection',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return TeamSelectionScreen(roomId: roomId);
        },
      ),

      // Участники команды (управление для организаторов)
      GoRoute(
        path: '/team-members/:teamId',
        name: 'team-members',
        builder: (context, state) {
          final teamId = state.pathParameters['teamId']!;
          final teamName = state.uri.queryParameters['teamName'] ?? 'Команда';
          return TeamMembersScreen(teamId: teamId, teamName: teamName);
        },
      ),

      // Просмотр команды (для обычных пользователей)
      GoRoute(
        path: '/team-view/:teamId',
        name: 'team-view',
        builder: (context, state) {
          final teamId = state.pathParameters['teamId']!;
          final teamName = state.uri.queryParameters['teamName'] ?? 'Команда';
          return TeamViewScreen(teamId: teamId, teamName: teamName);
        },
      ),

      // Профиль игрока
      GoRoute(
        path: '/player/:playerId',
        name: 'player-profile',
        builder: (context, state) {
          final playerId = state.pathParameters['playerId']!;
          final playerName = state.uri.queryParameters['playerName'];
          return PlayerProfileScreen(playerId: playerId, playerName: playerName);
        },
      ),

      // Dashboard организатора
      GoRoute(
        path: AppRoutes.organizerDashboard,
        name: 'organizer-dashboard',
        builder: (context, state) => const OrganizerDashboardScreen(),
      ),

      // Запросы дружбы
      GoRoute(
        path: '/friend-requests',
        name: 'friend-requests',
        builder: (context, state) => const FriendRequestsScreen(),
      ),

      // Приглашения в команды
      GoRoute(
        path: '/team-invitations',
        name: 'team-invitations',
        builder: (context, state) => const TeamInvitationsScreen(),
      ),

      // Заявки в команды
      GoRoute(
        path: '/team-applications',
        name: 'team-applications',
        builder: (context, state) => const TeamApplicationsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Ошибка'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            Text(
              'Страница не найдена',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.smallSpace),
            Text(
              'Путь: ${state.uri.path}',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.largeSpace),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.welcome),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    ),
  );
} 