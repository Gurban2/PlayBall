import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToProfile() {
    context.push(AppRoutes.profile);
  }

  void _navigateToCreateRoom() {
    context.push(AppRoutes.createRoom);
  }

  void _navigateToRoomDetails(String roomId) {
    // Проверяем, авторизован ли пользователь
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      // Если не авторизован, показываем диалог с предложением войти
      _showLoginDialog();
    } else {
      context.push('${AppRoutes.room}/$roomId');
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуется авторизация'),
        content: const Text(
          'Чтобы присоединиться к игре, необходимо войти в аккаунт.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.login);
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выхода: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildRoomCard(RoomModel room) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.mediumSpace),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      elevation: AppSizes.cardElevation,
      child: InkWell(
        onTap: () => _navigateToRoomDetails(room.id),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: AppSizes.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: room.status == RoomStatus.active
                          ? AppColors.primary
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      room.status == RoomStatus.active
                          ? AppStrings.active
                          : AppStrings.planned,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.smallSpace),
              Text(
                room.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.smallSpace),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: AppSizes.smallIconSize,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      room.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: AppSizes.smallIconSize,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.startTime.day}.${room.startTime.month}.${room.startTime.year} ${room.startTime.hour}:${room.startTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    size: AppSizes.smallIconSize,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.participants.length}/${room.maxParticipants}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRoomsAsync = ref.watch(activeRoomsProvider);
    final plannedRoomsAsync = ref.watch(plannedRoomsProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.welcome),
        ),
        actions: [
          userAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            error: (error, stack) => TextButton(
              onPressed: () => context.push(AppRoutes.login),
              child: const Text(
                'Войти',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            data: (user) {
              if (user == null) {
                return TextButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: const Text(
                    'Войти',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              } else {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.bug_report),
                      onPressed: () {
                        // Простая диагностика - показываем количество комнат
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Диагностика'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Пользователь: ${user.name}'),
                                Text('Роль: ${_getRoleText(user.role)}'),
                                const SizedBox(height: 16),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final activeRooms = ref.watch(activeRoomsProvider);
                                    final plannedRooms = ref.watch(plannedRoomsProvider);
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        activeRooms.when(
                                          loading: () => const Text('Загрузка активных...'),
                                          error: (e, s) => Text('Ошибка активных: $e'),
                                          data: (rooms) => Text('Активных игр: ${rooms.length}'),
                                        ),
                                        const SizedBox(height: 8),
                                        plannedRooms.when(
                                          loading: () => const Text('Загрузка запланированных...'),
                                          error: (e, s) => Text('Ошибка запланированных: $e'),
                                          data: (rooms) => Text('Запланированных игр: ${rooms.length}'),
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Может создавать игры: ${user.role == UserRole.organizer || user.role == UserRole.admin ? "Да" : "Нет"}'),
                                        const SizedBox(height: 16),
                                        // Временная кнопка создания игры для тестирования
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _navigateToCreateRoom();
                                          },
                                          icon: const Icon(Icons.add),
                                          label: const Text('Создать игру (тест)'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Закрыть'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Принудительно обновляем данные пользователя
                                  ref.invalidate(currentUserProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Данные пользователя обновлены'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                                child: const Text('Обновить данные'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person),
                      onPressed: _navigateToProfile,
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                    ),
                  ],
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Активные игры'),
            Tab(text: 'Запланированные'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Активные игры
          activeRoomsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(activeRoomsProvider),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
            data: (activeRooms) => activeRooms.isEmpty
                ? const Center(child: Text('Нет активных игр'))
                : RefreshIndicator(
                    onRefresh: () async => ref.refresh(activeRoomsProvider),
                    child: ListView.builder(
                      padding: AppSizes.screenPadding,
                      itemCount: activeRooms.length,
                      itemBuilder: (context, index) {
                        return _buildRoomCard(activeRooms[index]);
                      },
                    ),
                  ),
          ),
          // Запланированные игры
          plannedRoomsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(plannedRoomsProvider),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
            data: (plannedRooms) => plannedRooms.isEmpty
                ? const Center(child: Text('Нет запланированных игр'))
                : RefreshIndicator(
                    onRefresh: () async => ref.refresh(plannedRoomsProvider),
                    child: ListView.builder(
                      padding: AppSizes.screenPadding,
                      itemCount: plannedRooms.length,
                      itemBuilder: (context, index) {
                        return _buildRoomCard(plannedRooms[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final userAsync = ref.watch(currentUserProvider);
          return userAsync.when(
            loading: () {
              debugPrint('🔄 FloatingActionButton: Загрузка пользователя...');
              return const SizedBox.shrink();
            },
            error: (error, stack) {
              debugPrint('❌ FloatingActionButton: Ошибка загрузки пользователя: $error');
              return const SizedBox.shrink();
            },
            data: (user) {
              debugPrint('👤 FloatingActionButton: Пользователь загружен');
              debugPrint('   - ID: ${user?.id}');
              debugPrint('   - Имя: ${user?.name}');
              debugPrint('   - Роль: ${user?.role}');
              debugPrint('   - Может создавать игры: ${user?.role == UserRole.organizer || user?.role == UserRole.admin}');
              
              // Показываем кнопку только организаторам и админам
              if (user?.role == UserRole.organizer || user?.role == UserRole.admin) {
                debugPrint('✅ FloatingActionButton: Показываем кнопку создания игры');
                return FloatingActionButton(
                  onPressed: _navigateToCreateRoom,
                  child: const Icon(Icons.add),
                );
              } else {
                debugPrint('🚫 FloatingActionButton: Скрываем кнопку (роль: ${user?.role})');
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.organizer:
        return 'Организатор';
      case UserRole.admin:
        return 'Администратор';
      case UserRole.user:
        return 'Игрок';
      default:
        return 'Неизвестная роль';
    }
  }
} 