import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../../teams/domain/entities/user_team_model.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_theme.dart';

class OrganizerDashboardScreen extends ConsumerStatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  ConsumerState<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends ConsumerState<OrganizerDashboardScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  bool _isLoading = false;
  List<RoomModel> _organizerRooms = [];
  List<UserTeamModel> _organizerTeams = [];
  
  // Статистика игр
  int _totalGames = 0;
  int _activeGames = 0;
  int _plannedGames = 0;
  int _completedGames = 0;
  int _cancelledGames = 0;
  int _totalParticipants = 0;
  double _averageOccupancy = 0.0;
  Map<String, int> _locationStats = {};
  Map<GameMode, int> _gameModeStats = {};
  
  // Статистика команд
  int _totalTeams = 0;
  int _activeTeamsInGames = 0;
  Map<String, int> _teamWinStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDashboardData();
    
    // Автоматически обновляем статусы игр при загрузке
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateGameStatuses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
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
    _cancelledGames = _organizerRooms.where((r) => r.status == RoomStatus.cancelled).length;
    
    _totalParticipants = _organizerRooms.fold(0, (sum, room) => sum + room.participants.length);
    
    if (_totalGames > 0) {
      final totalCapacity = _organizerRooms.fold(0, (sum, room) => sum + room.maxParticipants);
      _averageOccupancy = totalCapacity > 0 ? (_totalParticipants / totalCapacity) * 100 : 0;
    }
    
    // Статистика по локациям
    _locationStats.clear();
    for (final room in _organizerRooms) {
      _locationStats[room.location] = (_locationStats[room.location] ?? 0) + 1;
    }
    
    // Статистика по режимам игр
    _gameModeStats.clear();
    for (final room in _organizerRooms) {
      _gameModeStats[room.gameMode] = (_gameModeStats[room.gameMode] ?? 0) + 1;
    }
    
    // Статистика команд с учетом эффективного статуса
    _totalTeams = _organizerTeams.length;
    _activeTeamsInGames = _organizerTeams.where((team) => 
        _organizerRooms.any((room) => 
            room.status == RoomStatus.active || room.status == RoomStatus.planned)).length;
    
    // Статистика побед команд (пока заглушка)
    _teamWinStats.clear();
    for (final team in _organizerTeams) {
      _teamWinStats[team.name] = 0; // TODO: Реализовать подсчет побед
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard организатора'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.createRoom),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
         
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Обзор'),
            Tab(icon: Icon(Icons.play_arrow), text: 'Активные'),
            Tab(icon: Icon(Icons.schedule), text: 'Запланированные'),
            Tab(icon: Icon(Icons.history), text: 'История'),
            Tab(icon: Icon(Icons.groups), text: 'Команды'),
          ],
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
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Приветствие организатора
          _buildOrganizerWelcome(),
          
          const SizedBox(height: 20),
          
          // Статистика игр организатора
          _buildOrganizerGamesStats(),
          
          const SizedBox(height: 24),
          
          // Быстрые действия
          _buildQuickActionsList(),
          
          const SizedBox(height: 24),
          
          // Статистика команд организатора
          _buildOrganizerTeamsStats(),
          
          const SizedBox(height: 24),
          
          // Ближайшие игры
          _buildUpcomingGames(),
          
          const SizedBox(height: 24),
          
          // Недавние завершенные игры
          _buildRecentCompletedGames(),
        ],
      ),
    );
  }

  Widget _buildOrganizerWelcome() {
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.value?.name ?? 'Организатор';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.waving_hand,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Привет, $userName!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadDashboardData,
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Управляйте своими играми и командами',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizerGamesStats() {
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
                Icon(
                  Icons.sports_volleyball,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ваши игры',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Статистика игр - заменяем GridView на Column с Row
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Активные',
                        _activeGames.toString(),
                        Icons.play_arrow,
                        AppTheme.successColor,
                        () => _tabController.animateTo(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Запланированы',
                        _plannedGames.toString(),
                        Icons.schedule,
                        AppTheme.warningColor,
                        () => _tabController.animateTo(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Завершены',
                        _completedGames.toString(),
                        Icons.check_circle,
                        Theme.of(context).colorScheme.primary,
                        () => _tabController.animateTo(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Всего игр',
                        _totalGames.toString(),
                        Icons.sports_volleyball,
                        Theme.of(context).colorScheme.secondary,
                        () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 80, // Фиксированная высота для предсказуемости
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
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
                        Icons.upcoming,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Ближайшие игры',
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
                if (upcomingGames.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _tabController.animateTo(2),
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
              ],
            ),
            const SizedBox(height: 16),
            
            if (upcomingGames.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Нет запланированных игр',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...upcomingGames.take(3).map((game) => 
                _buildGamePreview(game),
              ),
          ],
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
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isStartingSoon 
              ? AppTheme.warningColor.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isStartingSoon 
                ? AppTheme.warningColor.withOpacity(0.3)
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(game.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(game.status),
                  color: _getStatusColor(game.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            game.location,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${game.participants.length}/${game.maxParticipants}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isStartingSoon) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Скоро',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
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

  IconData _getStatusIcon(RoomStatus status) {
    switch (status) {
      case RoomStatus.active:
        return Icons.play_arrow;
      case RoomStatus.planned:
        return Icons.schedule;
      case RoomStatus.completed:
        return Icons.check_circle;
      case RoomStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getGameModeColor(GameMode mode) {
    switch (mode) {
      case GameMode.normal:
        return AppColors.primary;
      case GameMode.team_friendly:
        return AppColors.secondary;
      case GameMode.tournament:
        return AppColors.accent;
    }
  }

  Widget _buildQuickActionsList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Быстрые действия',
              style: AppTextStyles.heading3,
              
            ),
            const SizedBox(height: 16),
            
            _buildActionTile(
              'Создать новую игру',
              'Организовать волейбольную игру',
              Icons.add_circle,
              AppColors.primary,
              () => context.push(AppRoutes.createRoom),
            ),
            
            const SizedBox(height: 8),
            
            _buildActionTile(
              'Управление командами',
              'Посмотреть и управлять командами',
              Icons.groups,
              AppColors.secondary,
              () => _tabController.animateTo(4),
            ),
            
            const SizedBox(height: 8),
            
            _buildActionTile(
              'История игр',
              'Просмотр завершенных игр',
              Icons.history,
              AppColors.warning,
              () => _tabController.animateTo(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGamesTab() {
    final activeGames = _organizerRooms
        .where((room) => room.status == RoomStatus.active)
        .toList();
    
    return _buildGamesTable(activeGames, 'Нет активных игр');
  }

  Widget _buildPlannedGamesTab() {
    final plannedGames = _organizerRooms
        .where((room) => room.status == RoomStatus.planned)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return _buildGamesTable(plannedGames, 'Нет запланированных игр');
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
        // Кнопка очистки истории
        if (historyGames.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _clearCompletedGames,
              icon: const Icon(Icons.clear_all),
              label: const Text('Очистить историю'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        
        // Список игр
        Expanded(
          child: _buildGamesTable(historyGames, 'Нет завершенных игр'),
        ),
      ],
    );
  }

  Widget _buildTeamsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Статистика команд
          _buildTeamsStatsGrid(),
          
          const SizedBox(height: 24),
          
          // Кнопка создания команды
          if (_organizerTeams.isEmpty) ...[
            _buildCreateTeamCard(),
            const SizedBox(height: 24),
          ],
          
          // Список команд
          _buildTeamsList(),
        ],
      ),
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
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
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
                      'Побед: ${_teamWinStats[team.name] ?? 0}',
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
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(room.status).withOpacity(0.1),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция редактирования в разработке')),
    );
  }

  void _showCreateTeamDialog() {
    // Проверяем, есть ли уже команда у организатора
    if (_organizerTeams.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('У организатора может быть только одна команда'),
          backgroundColor: AppColors.warning,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название команды')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Команда "$teamName" создана успешно!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания команды: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
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
              backgroundColor: AppColors.secondary.withOpacity(0.1),
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
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editTeam(team),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Редактировать'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
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
                ],
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

  void _editTeam(UserTeamModel team) {
    Navigator.of(context).pop(); // Закрываем текущий диалог
    
    final TextEditingController teamNameController = TextEditingController(text: team.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать команду'),
        content: TextField(
          controller: teamNameController,
          decoration: const InputDecoration(
            labelText: 'Название команды',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => _updateTeamName(team, teamNameController.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTeamName(UserTeamModel team, String newName) async {
    if (newName.isEmpty || newName == team.name) {
      Navigator.of(context).pop();
      return;
    }

    try {
      final teamService = ref.read(teamServiceProvider);
      await teamService.updateUserTeam(team.id, {'name': newName});
      
      if (!mounted) return;
      Navigator.of(context).pop();
      
      // Перезагружаем данные
      await _loadDashboardData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Название команды изменено на "$newName"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('История игр очищена'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Команда "${team.name}" удалена'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
} 