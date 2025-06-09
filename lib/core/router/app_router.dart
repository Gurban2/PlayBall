import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/dashboard/presentation/screens/main_screen.dart';
import '../../features/dashboard/presentation/screens/schedule_screen.dart';

import '../../features/dashboard/presentation/screens/organizer_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/game_evaluation_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/player_profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/friend_requests_screen.dart';
import '../../features/profile/presentation/screens/friends_list_screen.dart';
import '../../features/rooms/presentation/screens/create_room_screen.dart';
import '../../features/rooms/presentation/screens/room_screen.dart';

import '../../features/teams/presentation/screens/team_screen.dart';
import '../../features/teams/presentation/screens/team_selection_screen.dart';
import '../../features/teams/presentation/screens/team_members_screen.dart';
import '../../features/teams/presentation/screens/team_view_screen.dart';
import '../../features/teams/presentation/screens/team_invitations_screen.dart';
import '../../features/teams/presentation/screens/team_applications_screen.dart';
import '../../features/teams/presentation/screens/my_team_screen.dart';
import '../../features/teams/presentation/screens/winner_selection_screen.dart';

import '../../features/auth/data/datasources/auth_service.dart';
import '../constants/constants.dart';
import '../errors/error_handler.dart';

import '../../features/notifications/presentation/screens/enhanced_notifications_screen.dart';
import '../../features/profile/presentation/screens/leaderboard_screen.dart';

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
      try {
        final isLoggedIn = await _authService.isUserLoggedIn();
        final currentPath = state.uri.path;
        
        // Если пользователь авторизован и находится на странице приветствия, перенаправляем на главную
        if (isLoggedIn && currentPath == AppRoutes.welcome) {
          return AppRoutes.home;
        }
        
        // Страницы, которые требуют авторизации
        final protectedRoutes = [
          AppRoutes.profile,
          AppRoutes.editProfile,
          AppRoutes.createRoom,
          AppRoutes.home,
          AppRoutes.schedule,
          '/team-',
          '/friend-requests',
          '/team-invitations',
          '/team-applications',
          '/my-team',
          '/notifications',
        ];
        
        // Проверяем, является ли текущий путь защищенным
        final isProtectedRoute = protectedRoutes.any((route) => currentPath.startsWith(route));
        
        // Если пользователь не авторизован и пытается попасть на защищенную страницу
        if (!isLoggedIn && isProtectedRoute) {
          return AppRoutes.login;
        }

        return null; // Не перенаправляем
      } catch (e) {
        // Обрабатываем ошибки авторизации через ErrorHandler
        if (context.mounted) {
          ErrorHandler.authenticationError(context);
        }
        // Возвращаем на страницу приветствия как fallback
        return AppRoutes.welcome;
      }
    },
    routes: [
      // Страницы без нижней навигации (для неавторизованных пользователей)
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Shell Route с нижней навигацией для авторизованных пользователей
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(
            currentRoute: state.uri.path,
            child: child,
          );
        },
        routes: [
          // Главные экраны с навигацией
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
            path: AppRoutes.schedule,
            name: 'schedule',
            builder: (context, state) => const ScheduleScreen(),
          ),

          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/edit-profile',
            name: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),

          // Все остальные страницы тоже получат нижнюю навигацию
          GoRoute(
            path: AppRoutes.createRoom,
            name: 'create-room',
            builder: (context, state) => const CreateRoomScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.room}/:roomId',
            name: 'room',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId'];
              if (roomId == null || roomId.isEmpty) {
                ErrorHandler.invalidParameter(context, 'roomId');
                return const ScheduleScreen(); // Fallback
              }
              return RoomScreen(roomId: roomId);
            },
          ),
          GoRoute(
            path: '${AppRoutes.team}/:roomId',
            name: 'team',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId'];
              if (roomId == null || roomId.isEmpty) {
                ErrorHandler.invalidParameter(context, 'roomId');
                return const ScheduleScreen(); // Fallback
              }
              return TeamScreen(roomId: roomId);
            },
          ),
          GoRoute(
            path: '/team-selection/:roomId',
            name: 'team-selection',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId'];
              if (roomId == null || roomId.isEmpty) {
                ErrorHandler.invalidParameter(context, 'roomId');
                return const ScheduleScreen(); // Fallback
              }
              return TeamSelectionScreen(roomId: roomId);
            },
          ),
          GoRoute(
            path: '/team-members/:teamId',
            name: 'team-members',
            builder: (context, state) {
              final teamId = state.pathParameters['teamId'];
              if (teamId == null || teamId.isEmpty) {
                ErrorHandler.invalidParameter(context, 'teamId');
                return const ScheduleScreen(); // Fallback
              }
              final teamName = state.uri.queryParameters['teamName'] ?? 'Команда';
              return TeamMembersScreen(teamId: teamId, teamName: teamName);
            },
          ),
          GoRoute(
            path: '/team-view/:teamId',
            name: 'team-view',
            builder: (context, state) {
              final teamId = state.pathParameters['teamId'];
              if (teamId == null || teamId.isEmpty) {
                ErrorHandler.invalidParameter(context, 'teamId');
                return const ScheduleScreen(); // Fallback
              }
              final teamName = state.uri.queryParameters['teamName'] ?? 'Команда';
              return TeamViewScreen(teamId: teamId, teamName: teamName);
            },
          ),
          GoRoute(
            path: '/player/:playerId',
            name: 'player-profile',
            builder: (context, state) {
              final playerId = state.pathParameters['playerId'];
              if (playerId == null || playerId.isEmpty) {
                ErrorHandler.invalidParameter(context, 'playerId');
                return const ScheduleScreen(); // Fallback
              }
              final playerName = state.uri.queryParameters['playerName'];
              return PlayerProfileScreen(playerId: playerId, playerName: playerName);
            },
          ),
          GoRoute(
            path: AppRoutes.organizerDashboard,
            name: 'organizer-dashboard',
            builder: (context, state) => const OrganizerDashboardScreen(),
          ),
          GoRoute(
            path: '/friend-requests',
            name: 'friend-requests',
            builder: (context, state) => const FriendRequestsScreen(),
          ),
          GoRoute(
            path: '/friends',
            name: 'friends',
            builder: (context, state) => const FriendsListScreen(),
          ),
          GoRoute(
            path: '/team-invitations',
            name: 'team-invitations',
            builder: (context, state) => const TeamInvitationsScreen(),
          ),
          GoRoute(
            path: '/team-applications',
            name: 'team-applications',
            builder: (context, state) => const TeamApplicationsScreen(),
          ),
          GoRoute(
            path: '/my-team',
            name: 'my-team',
            builder: (context, state) => const MyTeamScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const EnhancedNotificationsScreen(),
          ),
          GoRoute(
            path: '/game-evaluation/:roomId',
            name: 'game-evaluation',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId'];
              if (roomId == null || roomId.isEmpty) {
                ErrorHandler.invalidParameter(context, 'roomId');
                return const ScheduleScreen(); // Fallback
              }
              return GameEvaluationScreen(roomId: roomId);
            },
          ),
          GoRoute(
            path: '/winner-selection/:roomId',
            name: 'winner-selection',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId'];
              if (roomId == null || roomId.isEmpty) {
                ErrorHandler.invalidParameter(context, 'roomId');
                return const ScheduleScreen(); // Fallback
              }
              return WinnerSelectionScreen(roomId: roomId);
            },
          ),
          GoRoute(
            path: AppRoutes.leaderboard,
            name: 'leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),

        ],
      ),
    ],
    
    errorBuilder: (context, state) {
      // Показываем ошибку через ErrorHandler
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ErrorHandler.routeNotFound(context, state.uri.path);
        }
      });
      
      return Scaffold(
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
              const Text(
                'Страница не найдена',
                style: TextStyle(
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
      );
    },
  );
} 