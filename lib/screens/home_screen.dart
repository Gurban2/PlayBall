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
    context.push('${AppRoutes.room}/$roomId');
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              // Простая диагностика - показываем количество комнат
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Диагностика комнат'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final activeRooms = ref.watch(activeRoomsProvider);
                          final plannedRooms = ref.watch(plannedRoomsProvider);
                          
                          return Column(
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
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
            data: (user) {
              // Показываем кнопку только организаторам и админам
              if (user?.role == UserRole.organizer || user?.role == UserRole.admin) {
                return FloatingActionButton(
                  onPressed: _navigateToCreateRoom,
                  child: const Icon(Icons.add),
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
} 