import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/create_room_screen.dart';
import '../screens/room_screen.dart';
import '../screens/team_screen.dart';
import '../screens/team_selection_screen.dart';
import '../services/auth_service.dart';
import 'constants.dart';

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
        AppRoutes.editProfile,
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

      // Главный экран (список игр)
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Профиль пользователя
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Редактирование профиля
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
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