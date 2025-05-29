import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedLocation = 'Все локации';
  GameMode? _selectedGameMode;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToRoomDetails(String roomId) {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
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

  List<RoomModel> _filterRooms(List<RoomModel> rooms) {
    return rooms.where((room) {
      // Фильтр по локации
      if (_selectedLocation != 'Все локации' && room.location != _selectedLocation) {
        return false;
      }
      
      // Фильтр по режиму игры
      if (_selectedGameMode != null && room.gameMode != _selectedGameMode) {
        return false;
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeRoomsAsync = ref.watch(activeRoomsProvider);
    final plannedRoomsAsync = ref.watch(plannedRoomsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Расписание игр'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showFilters ? 160 : 48),
          child: Column(
            children: [
              // Фильтры
              if (_showFilters) _buildFiltersSection(),
              
              // Табы
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.play_circle_outline, size: 20),
                    text: 'Активные',
                  ),
                  Tab(
                    icon: Icon(Icons.schedule, size: 20),
                    text: 'Запланированные',
                  ),
                  Tab(
                    icon: Icon(Icons.person, size: 20),
                    text: 'Мои игры',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Активные игры
          _buildGamesList(activeRoomsAsync, 'Нет активных игр'),
          
          // Запланированные игры
          _buildGamesList(plannedRoomsAsync, 'Нет запланированных игр'),
          
          // Мои игры
          _buildMyGames(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          // Локация и режим игры
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLocation,
                      isExpanded: true,
                      icon: const Icon(Icons.location_on, size: 20),
                      items: ['Все локации', ...AppStrings.availableLocations]
                          .map((location) => DropdownMenuItem(
                                value: location,
                                child: Text(
                                  location,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<GameMode?>(
                      value: _selectedGameMode,
                      isExpanded: true,
                      hint: const Text('Режим игры', style: TextStyle(fontSize: 14)),
                      icon: const Icon(Icons.sports, size: 20),
                      items: [
                        const DropdownMenuItem<GameMode?>(
                          value: null,
                          child: Text('Все режимы', style: TextStyle(fontSize: 14)),
                        ),
                        ...GameMode.values.map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(
                                _getGameModeDisplayName(mode),
                                style: const TextStyle(fontSize: 14),
                              ),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGameMode = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Кнопка сброса фильтров
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedLocation = 'Все локации';
                  _selectedGameMode = null;
                });
              },
              icon: const Icon(Icons.clear, color: Colors.white, size: 18),
              label: const Text(
                'Сбросить фильтры',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList(AsyncValue<List<RoomModel>> roomsAsync, String emptyMessage) {
    return roomsAsync.when(
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
              onPressed: () {
                if (roomsAsync == ref.read(activeRoomsProvider)) {
                  ref.refresh(activeRoomsProvider);
                } else {
                  ref.refresh(plannedRoomsProvider);
                }
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
      data: (rooms) {
        final filteredRooms = _filterRooms(rooms);
        
        if (filteredRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_volleyball_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(emptyMessage),
                if (_selectedLocation != 'Все локации' || _selectedGameMode != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Попробуйте изменить фильтры',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            if (roomsAsync == ref.read(activeRoomsProvider)) {
              ref.refresh(activeRoomsProvider);
            } else {
              ref.refresh(plannedRoomsProvider);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRooms.length,
            itemBuilder: (context, index) {
              return _buildEnhancedRoomCard(filteredRooms[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildMyGames() {
    return Consumer(
      builder: (context, ref, child) {
        final userRoomsAsync = ref.watch(userRoomsProvider);
        return userRoomsAsync.when(
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
                  onPressed: () => ref.refresh(userRoomsProvider),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
          data: (userRooms) {
            if (userRooms.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_volleyball_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text('Вы еще не участвуете в играх'),
                    SizedBox(height: 8),
                    Text(
                      'Присоединяйтесь к играм или создайте свою!',
                      style: TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(userRoomsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: userRooms.length,
                itemBuilder: (context, index) {
                  return _buildEnhancedRoomCard(userRooms[index]);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedRoomCard(RoomModel room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: InkWell(
        onTap: () => _navigateToRoomDetails(room.id),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Хедер карточки
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(room.status).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(room.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(room.status),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(room.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Основной контент
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Описание
                  if (room.description.isNotEmpty) ...[
                    Text(
                      room.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Информация о игре
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.location_on,
                          label: room.location,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.people,
                          label: '${room.participants.length}/${room.maxParticipants}',
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.access_time,
                          label: _formatDateTime(room.startTime),
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.sports,
                          label: _getGameModeDisplayName(room.gameMode),
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.planned:
        return AppColors.secondary;
      case RoomStatus.active:
        return AppColors.primary;
      case RoomStatus.completed:
        return AppColors.success;
      case RoomStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(RoomStatus status) {
    switch (status) {
      case RoomStatus.planned:
        return Icons.schedule;
      case RoomStatus.active:
        return Icons.play_circle;
      case RoomStatus.completed:
        return Icons.check_circle;
      case RoomStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(RoomStatus status) {
    switch (status) {
      case RoomStatus.planned:
        return 'Запланирована';
      case RoomStatus.active:
        return 'Активна';
      case RoomStatus.completed:
        return 'Завершена';
      case RoomStatus.cancelled:
        return 'Отменена';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getGameModeDisplayName(GameMode mode) {
    switch (mode) {
      case GameMode.normal:
        return 'Обычный';
      case GameMode.team_friendly:
        return 'Команды';
      case GameMode.tournament:
        return 'Турнир';
    }
  }
} 