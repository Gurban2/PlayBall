import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/router/app_router.dart';
import 'schedule_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

// Обёртка для показа нижней навигации на всех страницах
class ScaffoldWithBottomNav extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const ScaffoldWithBottomNav({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  // Страницы, где нижняя навигация НЕ должна отображаться
  static const List<String> _pagesWithoutBottomNav = [
    '/welcome',
    '/login',
    '/register',
  ];

  bool _shouldShowBottomNav() {
    return !_pagesWithoutBottomNav.any((page) => currentRoute.startsWith(page));
  }

  int _getSelectedIndex(String route) {
    if (route.startsWith('/home') || 
        route.startsWith('/schedule') || 
        route == '/' ||
        route.startsWith('/room') ||
        route.startsWith('/create-room') ||
        route.startsWith('/organizer-dashboard')) {
      return 0; // Расписание
    } else if (route.startsWith('/profile') || 
               route.startsWith('/team-') || 
               route.startsWith('/friend-requests') ||
               route.startsWith('/team-invitations') ||
               route.startsWith('/team-applications') ||
               route.startsWith('/player/') ||
               route.startsWith('/my-team')) {
      return 1; // Профиль
    }
    return 0; // По умолчанию расписание
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    
    return userAsync.when(
      loading: () => Scaffold(
        body: child,
      ),
      error: (error, stack) => Scaffold(
        body: child,
      ),
      data: (user) {
        // Если пользователь не авторизован или на страницах без навигации
        if (user == null || !_shouldShowBottomNav()) {
          return Scaffold(body: child);
        }

        final selectedIndex = _getSelectedIndex(currentRoute);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.darkGrey,
            foregroundColor: Colors.white,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          _getInitials(user.name),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.teamName != null)
                        Text(
                          user.teamName!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Кнопка домой
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go(AppRoutes.home),
                tooltip: 'На главную',
              ),
              // Иконка уведомлений (если есть)
              _buildNotificationIcon(context, ref, user),
            ],
            automaticallyImplyLeading: false,
            elevation: 1,
          ),
          body: child,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => _onTabTapped(context, index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.darkGrey,
              selectedItemColor: Colors.white,
              unselectedItemColor: AppColors.lightGrey,
              selectedLabelStyle: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.white,
              ),
              unselectedLabelStyle: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: AppColors.lightGrey,
              ),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.schedule_outlined),
                  activeIcon: Icon(Icons.schedule),
                  label: 'Расписание',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Профиль',
                ),
              ],
            ),
          ),
          floatingActionButton: (user.role == UserRole.organizer || user.role == UserRole.admin)
              ? FloatingActionButton(
                  onPressed: () => context.push(AppRoutes.createRoom),
                  backgroundColor: AppColors.darkGrey,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  child: const Icon(Icons.add, size: 28),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        // Проверяем авторизацию перед переходом на профиль
        final container = ProviderScope.containerOf(context);
        final user = container.read(currentUserProvider).value;
        if (user != null) {
          context.go(AppRoutes.profile);
        } else {
          context.go(AppRoutes.login);
        }
        break;
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '';
  }

  Widget _buildNotificationIcon(BuildContext context, WidgetRef ref, UserModel user) {
    return FutureBuilder<int>(
      future: _getTotalNotificationsCount(ref, user),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push('/notifications'),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<int> _getTotalNotificationsCount(WidgetRef ref, UserModel user) async {
    try {
      final userService = ref.read(userServiceProvider);
      final teamService = ref.read(teamServiceProvider);
      
      final friendRequestsCount = await userService.getIncomingRequestsCount(user.id);
      final teamInvitationsCount = await teamService.getIncomingTeamInvitationsCount(user.id);
      
      return friendRequestsCount + teamInvitationsCount;
    } catch (e) {
      return 0;
    }
  }
}

// Оригинальный MainScreen для обратной совместимости
class MainScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late int _currentIndex;
  
  final List<Widget> _screens = [
    const ScheduleScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToCreateRoom() {
    context.push(AppRoutes.createRoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.darkGrey,
          selectedItemColor: Colors.white,
          unselectedItemColor: AppColors.lightGrey,
          selectedLabelStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.white,
          ),
          unselectedLabelStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: AppColors.lightGrey,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_outlined),
              activeIcon: Icon(Icons.schedule),
              label: 'Расписание',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Профиль',
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final userAsync = ref.watch(currentUserProvider);
          return userAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
            data: (user) {
              // Показываем кнопку только организаторам и админам
              if (user?.role == UserRole.organizer || user?.role == UserRole.admin) {
                return FloatingActionButton(
                  onPressed: _navigateToCreateRoom,
                  backgroundColor: AppColors.darkGrey,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  child: const Icon(Icons.add, size: 28),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
} 