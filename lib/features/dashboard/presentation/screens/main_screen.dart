import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/providers.dart';
import '../../../../core/services/background_scheduler_service.dart';
import '../../../../shared/widgets/navigation/hamburger_menu.dart';
import '../../../auth/domain/entities/user_model.dart';








// Обёртка для показа нижней навигации на всех страницах
class ScaffoldWithBottomNav extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const ScaffoldWithBottomNav({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<ScaffoldWithBottomNav> createState() => _ScaffoldWithBottomNavState();
}

class _ScaffoldWithBottomNavState extends ConsumerState<ScaffoldWithBottomNav> 
    with WidgetsBindingObserver {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Подписываемся на изменения состояния приложения
    WidgetsBinding.instance.addObserver(this);
    
    // Запускаем фоновый планировщик
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final backgroundScheduler = ref.read(backgroundSchedulerServiceProvider);
        backgroundScheduler.start(ref);
      }
    });
  }

  @override
  void dispose() {
    // Отписываемся от изменений состояния приложения
    WidgetsBinding.instance.removeObserver(this);
    
    // Останавливаем фоновый планировщик
    try {
      final backgroundScheduler = ref.read(backgroundSchedulerServiceProvider);
      backgroundScheduler.stop();
    } catch (e) {
      // Игнорируем ошибки при dispose
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Обновляем данные при возвращении в приложение
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('🔄 Приложение возобновлено - обновляем все провайдеры');
      
      // Обновляем основные провайдеры данных
      // ignore: unused_result
      ref.refresh(currentUserProvider);
      // ignore: unused_result
      ref.refresh(activeRoomsProvider);
      // ignore: unused_result
      ref.refresh(plannedRoomsProvider);
      // ignore: unused_result
      ref.refresh(userRoomsProvider);
      
      // Перезапускаем фоновый планировщик
      final backgroundScheduler = ref.read(backgroundSchedulerServiceProvider);
      backgroundScheduler.stop();
      backgroundScheduler.start(ref);
    }
  }

  // Страницы, где нижняя навигация НЕ должна отображаться
  static const List<String> _pagesWithoutBottomNav = [
    '/welcome',
    '/login',
    '/register',
  ];

  bool _shouldShowBottomNav() {
    return !_pagesWithoutBottomNav.any((page) => widget.currentRoute.startsWith(page));
  }

  int _getSelectedIndex(String route) {
    if (route.startsWith('/home') || 
        route.startsWith('/schedule') ||
        route == '/' ||
        route.startsWith('/organizer-dashboard') ||
        route.startsWith('/room') ||
        route.startsWith('/create-room')) {
      return 0; // Главная/Игры
    } else if (route.startsWith('/team-') || 
               route.startsWith('/my-team')) {
      return 1; // Команды
    }
    return 0; // По умолчанию главная
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    
    return userAsync.when(
      loading: () => Scaffold(
        body: widget.child,
      ),
      error: (error, stack) => Scaffold(
        body: widget.child,
      ),
      data: (user) {
        // Если пользователь не авторизован или на страницах без навигации
        if (user == null || !_shouldShowBottomNav()) {
          return Scaffold(body: widget.child);
        }

        final selectedIndex = _getSelectedIndex(widget.currentRoute);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.darkGrey,
            foregroundColor: Colors.white,
            toolbarHeight: 36, // Увеличил для нового дизайна
            titleSpacing: 0,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // Левый угол - иконка игры (24px)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.sports_volleyball,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Центр - селектор волейбол/футбол
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  
                    child: DropdownButton<String>(
                      value: 'volleyball',
                      underline: const SizedBox(),
                      icon: const Icon(Icons.expand_more, color: Colors.white, size: 16),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      dropdownColor: AppColors.darkGrey,
                      items: [
                        DropdownMenuItem(
                          value: 'volleyball',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sports_volleyball, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Волейбол'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'football',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sports_soccer, size: 16, color: Colors.grey),
                              SizedBox(width: 6),
                              Text('Футбол', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == 'football') {
                          ErrorHandler.showInfo(context, 'Футбол будет доступен в следующих обновлениях');
                        }
                      },
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Правый угол - hamburger menu
                  const HamburgerMenu(),
                ],
              ),
            ),
            automaticallyImplyLeading: false,
            elevation: 1,
          ),
          body: widget.child,
                bottomNavigationBar: Container(
        height: 52, // Фиксированная высота как в карточках
        decoration: BoxDecoration(
          color: AppColors.darkGrey,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6, // Уменьшил с 10 до 6
              offset: const Offset(0, -1), // Уменьшил с -2 до -1
            ),
          ],
        ),
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => _onTabTapped(context, index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: AppColors.lightGrey,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 10, // Уменьшил с 12 до 10
                color: Colors.white,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 9, // Уменьшил с 11 до 9
                color: AppColors.lightGrey,
              ),
              elevation: 0,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.sports_volleyball_outlined),
                  activeIcon: Icon(Icons.sports_volleyball),
                  label: 'Игры',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.groups_outlined),
                  activeIcon: Icon(Icons.groups),
                  label: 'Команда',
                ),
              ],
            ),
          ),
          floatingActionButton: (user.role == UserRole.organizer || user.role == UserRole.admin)
              ? FloatingActionButton(
                  onPressed: () => context.push('/create-room'),
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
    setState(() {
      selectedIndex = index;
    });

    switch (index) {
      case 0: // Игры
        context.go(AppRoutes.home);
        break;
      case 1: // Команды
        context.go(AppRoutes.myTeam);
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
} 