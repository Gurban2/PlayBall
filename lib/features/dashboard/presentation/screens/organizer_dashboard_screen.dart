import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../../teams/domain/entities/user_team_model.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../shared/widgets/universal_card.dart';


class OrganizerDashboardScreen extends ConsumerStatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  ConsumerState<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends ConsumerState<OrganizerDashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  
  late TabController _tabController;
  bool _isLoading = false;
  List<RoomModel> _organizerRooms = [];
  List<UserTeamModel> _organizerTeams = [];
  
  // Статистика игр
  int _totalGames = 0;
  int _activeGames = 0;
  int _plannedGames = 0;
  int _completedGames = 0;

  final Map<String, int> _locationStats = {};
  final Map<String, int> _gameModeStats = {};
  
  // Статистика команд
  int _totalTeams = 0;
  int _activeTeamsInGames = 0;
  final Map<String, Map<String, int>> _teamWinStats = {};



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Подписываемся на изменения состояния приложения
    WidgetsBinding.instance.addObserver(this);
    
    _loadDashboardData();
    
    // Автоматически обновляем статусы игр при загрузке
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateGameStatuses();
    });
  }

  @override
  void dispose() {
    // Отписываемся от изменений состояния приложения
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Обновляем данные при возвращении в приложение
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 Приложение возобновлено - обновляем dashboard организатора');
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;
      
      if (user != null) {
        final roomService = ref.read(roomServiceProvider);
        final teamService = ref.read(teamServiceProvider);
        
        // Автоматически завершаем просроченные игры
        await roomService.autoCompleteExpiredGames();
        
        // Автоматически отменяем просроченные запланированные игры
        await roomService.autoCancelExpiredPlannedGames();
        
        // Загружаем игры организатора
        _organizerRooms = await roomService.getRoomsByOrganizer(user.id);
        
        // Загружаем команды организатора
        _organizerTeams = await teamService.getTeamsByOrganizer(user.id);
        
        _calculateStatistics();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных dashboard: $e');
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateGameStatuses() async {
    try {
      final roomService = ref.read(roomServiceProvider);
      
      // Автоматически запускаем запланированные игры
      await roomService.autoStartScheduledGames();
      
      // Автоматически завершаем активные игры
      await roomService.autoCompleteExpiredGames();
      
      // Отменяем просроченные запланированные игры
      await roomService.autoCancelExpiredPlannedGames();
      
      debugPrint('✅ Статусы игр обновлены в OrganizerDashboard');
    } catch (e) {
      debugPrint('❌ Ошибка обновления статусов игр в OrganizerDashboard: $e');
    }
  }

  void _calculateStatistics() {
    // Статистика игр с учетом эффективного статуса (автоматическая активация за 5 минут)
    _totalGames = _organizerRooms.length;
    _activeGames = _organizerRooms.where((r) => r.status == RoomStatus.active).length;
    _plannedGames = _organizerRooms.where((r) => r.status == RoomStatus.planned).length;
    _completedGames = _organizerRooms.where((r) => r.status == RoomStatus.completed).length;
    

    
    // Статистика по локациям
    _locationStats.clear();
    for (final room in _organizerRooms) {
      _locationStats[room.location] = (_locationStats[room.location] ?? 0) + 1;
    }
    
    // Статистика по режимам игр
    _gameModeStats.clear();
    for (final room in _organizerRooms) {
      _gameModeStats[room.gameMode.toString()] = (_gameModeStats[room.gameMode.toString()] ?? 0) + 1;
    }
    
    // Статистика команд с учетом эффективного статуса
    _totalTeams = _organizerTeams.length;
    _activeTeamsInGames = _organizerTeams.where((team) => 
        _organizerRooms.any((room) => 
            room.status == RoomStatus.active || room.status == RoomStatus.planned)).length;
    
    // Статистика побед команд (пока заглушка)
    _teamWinStats.clear();
    for (final team in _organizerTeams) {
      _teamWinStats[team.name] = {}; // TODO: Реализовать подсчет побед
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        toolbarHeight: 44, // Компактная высота
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _loadDashboardData,
            padding: const EdgeInsets.all(6),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => context.push(AppRoutes.createRoom),
            padding: const EdgeInsets.all(6),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36), // Компактная высота табов
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            isScrollable: true,
            labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Обзор'),
              Tab(text: 'Активные'),
              Tab(text: 'План'),
              Tab(text: 'История'),
              Tab(text: 'Команды'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildActiveGamesTab(),
                _buildPlannedGamesTab(),
                _buildHistoryTab(),
                _buildTeamsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.createRoom),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8), // Уменьшил padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Компактная статистика игр
          _buildCompactGamesStats(),
          
          const SizedBox(height: 12), // Уменьшил spacing
          
          // Быстрые действия
          _buildQuickActionsList(),
          
          const SizedBox(height: 12), // Уменьшил spacing
          
          // Ближайшие игры
          _buildUpcomingGames(),
          
          const SizedBox(height: 12), // Уменьшил spacing
          
          // Статистика команд
          _buildCompactTeamsStats(),
        ],
      ),
    );
  }

  // Компактная статистика игр в стиле карточек
  Widget _buildCompactGamesStats() {
    return Row(
      children: [
        Expanded(child: _buildCompactStatCard('Активные', _activeGames, AppColors.success, Icons.play_arrow)),
        const SizedBox(width: 8),
        Expanded(child: _buildCompactStatCard('План', _plannedGames, AppColors.warning, Icons.schedule)),
        const SizedBox(width: 8),
        Expanded(child: _buildCompactStatCard('Завершены', _completedGames, AppColors.primary, Icons.check_circle)),
      ],
    );
  }

  // Компактная статистика команд
  Widget _buildCompactTeamsStats() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(0.5),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.groups, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Команды: $_totalTeams',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'В играх: $_activeTeamsInGames',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$_totalTeams',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Компактная карточка статистики используя универсальный компонент
  Widget _buildCompactStatCard(String title, int value, Color color, IconData icon) {
    return UniversalCard(
      title: title,
      accentColor: color,
      leading: Icon(icon, color: color, size: 16),
      trailing: Text(
        value.toString(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }



  Widget _buildOrganizerTeamsStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.groups,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Ваши команды',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _tabController.animateTo(4),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Все',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_organizerTeams.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_add,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'У вас пока нет команд',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTeamStat(
                        'Команд создано',
                        _totalTeams.toString(),
                        Icons.groups,
                      ),
                      _buildTeamStat(
                        'Участников',
                        _organizerTeams.fold(0, (sum, team) => sum + team.members.length).toString(),
                        Icons.people,
                      ),
                    ],
                  ),
                  if (_organizerTeams.length <= 3) ...[
                    const SizedBox(height: 16),
                    ..._organizerTeams.take(3).map((team) => 
                      _buildTeamPreview(team),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamStat(String label, String value, IconData icon) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPreview(UserTeamModel team) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
                      Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  team.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${team.members.length} участников',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingGames() {
    final upcomingGames = _organizerRooms
        .where((room) => room.status == RoomStatus.planned)
        .toList();
        
    upcomingGames.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (upcomingGames.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Ближайшие игры',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        ...upcomingGames.take(3).map((game) => _buildCompactGameCard(game)),
      ],
    );
  }

  Widget _buildCompactGameCard(RoomModel game) {
    final isToday = _isSameDay(game.startTime, DateTime.now());
    
    return UniversalCard(
      title: game.title,
      subtitle: game.location,
      accentColor: AppColors.warning,
      onTap: () => _showGameDetails(game),
      badge: isToday ? 'Today' : null,
      badgeColor: AppColors.warning,
      trailing: Text(
        _formatTime(game.startTime),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.warning,
          height: 0.8,
        ),
      ),
    );
  }



  Widget _buildRecentCompletedGames() {
    final recentGames = _organizerRooms
        .where((room) => room.status == RoomStatus.completed)
        .toList();
        
    recentGames.sort((a, b) => b.startTime.compareTo(a.startTime));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Недавние игры',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (recentGames.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _tabController.animateTo(3),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'История',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            if (recentGames.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sports_volleyball,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Пока нет завершённых игр',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentGames.take(3).map((game) => 
                _buildGamePreview(game),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamePreview(RoomModel game) {
    final isUpcoming = game.status == RoomStatus.planned;
    final timeUntil = game.startTime.difference(DateTime.now());
    final isStartingSoon = isUpcoming && timeUntil.inHours < 2 && timeUntil.inMinutes > 0;
    final statusColor = _getStatusColor(game.status);
    final isActive = game.status == RoomStatus.active;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Градиентный фон для активных игр
          gradient: isActive ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withValues(alpha: 0.8),
              statusColor.withValues(alpha: 0.6),
            ],
          ) : null,
          color: isActive ? null : (isStartingSoon 
              ? AppTheme.warningColor.withValues(alpha: 0.05)
              : Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border(
            left: BorderSide(
              color: statusColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и время
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      game.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Время в правом верхнем углу
                  Text(
                    '${game.startTime.hour.toString().padLeft(2, '0')}:${game.startTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : statusColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Локация
              Text(
                game.location,
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? Colors.white70 : Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Дополнительная информация внизу
              Row(
                children: [
                  // Участники
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people,
                        size: 12,
                        color: isActive ? Colors.white70 : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.participants.length}/${game.maxParticipants}',
                        style: TextStyle(
                          color: isActive ? Colors.white70 : Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  if (isStartingSoon) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Скоро',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Статус
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive 
                            ? Colors.white.withValues(alpha: 0.2)
                            : statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(game.status),
                        style: TextStyle(
                          color: isActive ? Colors.white : statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.active:
        return AppTheme.successColor;
      case RoomStatus.planned:
        return AppTheme.warningColor;
      case RoomStatus.completed:
        return Theme.of(context).colorScheme.primary;
      case RoomStatus.cancelled:
        return Theme.of(context).colorScheme.error;
    }
  }



  Widget _buildQuickActionsList() {
    return Row(
      children: [
        Expanded(child: _buildCompactActionCard('Создать игру', Icons.add_circle, AppColors.primary, () => context.push(AppRoutes.createRoom))),
        const SizedBox(width: 8),
        Expanded(child: _buildCompactActionCard('Команды', Icons.groups, AppColors.secondary, () => _tabController.animateTo(4))),
        const SizedBox(width: 8),
        Expanded(child: _buildCompactActionCard('История', Icons.history, AppColors.warning, () => _tabController.animateTo(3))),
      ],
    );
  }

  Widget _buildCompactActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return UniversalCard(
      title: title,
      accentColor: color,
      onTap: onTap,
      leading: Icon(icon, color: color, size: 16),
    );
  }



  Widget _buildActiveGamesTab() {
    final activeGames = _organizerRooms
        .where((room) => room.status == RoomStatus.active)
        .toList();
    
    return _buildCompactGamesList(activeGames, 'Нет активных игр', AppColors.success);
  }

  Widget _buildPlannedGamesTab() {
    final plannedGames = _organizerRooms
        .where((room) => room.status == RoomStatus.planned)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return _buildCompactGamesList(plannedGames, 'Нет запланированных игр', AppColors.warning);
  }

  Widget _buildCompactGamesList(List<RoomModel> games, String emptyMessage, Color accentColor) {
    if (games.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_volleyball_outlined,
                size: 48,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final isToday = _isSameDay(game.startTime, DateTime.now());
        
        return UniversalCard(
          title: game.title,
          subtitle: '${game.location} • ${game.participants.length}/${game.maxParticipants}',
          accentColor: accentColor,
          onTap: () => _showGameDetails(game),
          badge: isToday ? 'Today' : null,
          badgeColor: accentColor,
          trailing: Text(
            _formatTime(game.startTime),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
              height: 0.8,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final historyGames = _organizerRooms
        .where((room) => 
            room.status == RoomStatus.completed || 
            room.status == RoomStatus.cancelled)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    return Column(
      children: [
        // Компактная кнопка очистки истории
        if (historyGames.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(8),
            height: 36,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _clearCompletedGames,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Очистить', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        
        // Список игр
        Expanded(
          child: _buildCompactGamesList(historyGames, 'Нет завершенных игр', AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildTeamsTab() {
    if (_organizerTeams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.groups_outlined,
                size: 48,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              const Text(
                'У вас пока нет команд',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showCreateTeamDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Создать команду'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _organizerTeams.length,
      itemBuilder: (context, index) {
        final team = _organizerTeams[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showTeamDetails(team),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                      backgroundImage: team.photoUrl != null ? NetworkImage(team.photoUrl!) : null,
                      child: team.photoUrl == null 
                          ? Text(
                              team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            team.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${team.members.length}/${team.maxMembers} участников',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      team.members.length >= team.maxMembers ? Icons.check_circle : Icons.people,
                      size: 16,
                      color: team.members.length >= team.maxMembers ? AppColors.success : AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamsStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTeamStatCard(
                'Всего команд',
                          _totalTeams.toString(),
                          Icons.groups,
                AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
              child: _buildTeamStatCard(
                'Активные в играх',
                _activeTeamsInGames.toString(),
                Icons.sports,
                AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTeamCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _showCreateTeamDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Создать команду',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Создайте свою команду для участия в играх',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Мои команды',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_organizerTeams.isNotEmpty)
                  IconButton(
                    onPressed: _showCreateTeamDialog,
                    icon: const Icon(Icons.add),
                    tooltip: 'Создать команду',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_organizerTeams.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'У вас пока нет команд',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ..._organizerTeams.map((team) => _buildTeamCard(team)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(UserTeamModel team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: () => _showTeamDetails(team),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  child: Text(
                    team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${team.members.length} участников',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Побед: ${_teamWinStats[team.name]?.values.fold(0, (sum, value) => sum + value) ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: team.members.length >= 6 
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        team.members.length >= 6 ? 'Готова' : 'Неполная',
                        style: TextStyle(
                          color: team.members.length >= 6 
                              ? AppColors.success 
                              : AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGamesTable(List<RoomModel> games, String emptyMessage) {
    if (games.isEmpty) {
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
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: games.length,
        itemBuilder: (context, index) {
          return _buildDetailedRoomCard(games[index]);
        },
      ),
    );
  }

  Widget _buildDetailedRoomCard(RoomModel room) {
    final isToday = _isSameDay(room.startTime, DateTime.now());
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.room}/${room.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и статус
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Бейдж "Today" если игра сегодня
                  if (isToday) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(room.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(room.status),
                      style: TextStyle(
                        color: _getStatusColor(room.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Информация об игре
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoChip(Icons.location_on, room.location),
                        const SizedBox(height: 4),
                        _buildInfoChip(Icons.access_time, _formatDateTime(room.startTime)),
                        const SizedBox(height: 4),
                        _buildInfoChip(Icons.sports, _getGameModeDisplayName(room.gameMode)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${room.participants.length}/${room.maxParticipants}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        'участников',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Действия для запланированных игр
              if (room.status == RoomStatus.planned) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _editGame(room),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Изменить'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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
    final now = DateTime.now();
    final isThisYear = dateTime.year == now.year;
    
    if (isThisYear) {
      return '${dateTime.day}.${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
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

  void _editGame(RoomModel room) {
    // TODO: Реализовать редактирование игры
    ErrorHandler.showWarning(context, 'Функция редактирования в разработке');
  }

  void _showCreateTeamDialog() {
    // Проверяем, есть ли уже команда у организатора
    if (_organizerTeams.isNotEmpty) {
      ErrorHandler.showWarning(context, 'У организатора может быть только одна команда');
      return;
    }

    final TextEditingController teamNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать команду'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: teamNameController,
              decoration: const InputDecoration(
                labelText: 'Название команды',
                hintText: 'Введите название команды',
                border: OutlineInputBorder(),
              ),
              maxLength: 30,
            ),
            const SizedBox(height: 16),
            const Text(
              'Вы будете автоматически добавлены в команду как капитан.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => _createTeam(teamNameController.text.trim()),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTeam(String teamName) async {
    if (teamName.isEmpty) {
      ErrorHandler.showError(context, 'Введите название команды');
      return;
    }

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;

      final teamService = ref.read(teamServiceProvider);
      
      final newTeam = UserTeamModel(
        id: '',
        name: teamName,
        ownerId: user.id,
        members: [user.id],
        createdAt: DateTime.now(),
      );

      await teamService.createUserTeam(newTeam);
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Закрываем диалог
      
      // Перезагружаем данные
      await _loadDashboardData();
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Команда "$teamName" создана успешно!');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  void _showTeamDetails(UserTeamModel team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              child: Text(
                team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                team.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTeamDetailRow('Участников', '${team.members.length}/6'),
              _buildTeamDetailRow('Создана', _formatDate(team.createdAt)),
              _buildTeamDetailRow('Статус', team.members.length >= 6 ? 'Готова к игре' : 'Неполная команда'),
              
              const SizedBox(height: 16),
              
              // Кнопка управления участниками
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showTeamMembersManagement(team),
                  icon: const Icon(Icons.people, size: 16),
                  label: const Text('Участники'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Кнопка удаления команды
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteTeam(team),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Удалить команду'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showTeamMembersManagement(UserTeamModel team) {
    Navigator.of(context).pop(); // Закрываем диалог деталей команды
    
    // Переходим к полному экрану управления участниками
    context.push('/team-members/${team.id}?teamName=${Uri.encodeComponent(team.name)}');
  }

  Widget _buildTeamDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }



  // Очистка завершенных игр
  Future<void> _clearCompletedGames() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю'),
        content: const Text(
          'Удалить все завершенные и отмененные игры? '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = ref.read(currentUserProvider).value;
        if (user == null) return;

        final roomService = ref.read(roomServiceProvider);
        await roomService.clearCompletedGames(user.id);

        // Перезагружаем данные
        await _loadDashboardData();

        if (mounted) {
          ErrorHandler.showSuccess(context, 'История игр очищена');
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }
  }

  // Удаление команды
  Future<void> _deleteTeam(UserTeamModel team) async {
    Navigator.of(context).pop(); // Закрываем диалог деталей

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить команду'),
        content: Text(
          'Удалить команду "${team.name}"? '
          'Все участники будут исключены из команды.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final teamService = ref.read(teamServiceProvider);
        await teamService.deleteUserTeam(team.id);

        // Перезагружаем данные
        await _loadDashboardData();

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Команда "${team.name}" удалена');
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }
  }

  // Функция для проверки, является ли дата сегодняшней
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showGameDetails(RoomModel game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(game.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Место: ${game.location}'),
            Text('Время: ${_formatTime(game.startTime)}'),
            Text('Участники: ${game.participants.length}/${game.maxParticipants}'),
            Text('Статус: ${_getStatusText(game.status)}'),
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
  }


} 