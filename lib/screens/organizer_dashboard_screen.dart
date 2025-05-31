import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../models/user_team_model.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';

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

  void _calculateStatistics() {
    // Статистика игр
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
    
    // Статистика команд
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Статистические карточки игр
          const Text(
            'Статистика игр',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildGamesStatsGrid(),
          
          const SizedBox(height: 24),
          
          // Быстрые действия
          _buildQuickActions(),
          
          const SizedBox(height: 24),
          
          // Статистика по режимам игр
          _buildGameModeStats(),
          
          const SizedBox(height: 24),
          
          // Аналитика
          _buildAnalytics(),
          
          const SizedBox(height: 24),
          
          // Последние игры
          _buildRecentGames(),
        ],
      ),
    );
  }

  Widget _buildGamesStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Всего игр',
          _totalGames.toString(),
          Icons.sports_volleyball,
          AppColors.primary,
        ),
        _buildStatCard(
          'Активные',
          _activeGames.toString(),
          Icons.play_arrow,
          AppColors.success,
        ),
        _buildStatCard(
          'Запланированные',
          _plannedGames.toString(),
          Icons.schedule,
          AppColors.warning,
        ),
        _buildStatCard(
          'Завершенные',
          _completedGames.toString(),
          Icons.check_circle,
          AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Переключаемся на соответствующую вкладку
          if (title == 'Активные') _tabController.animateTo(1);
          else if (title == 'Запланированные') _tabController.animateTo(2);
          else if (title == 'Завершенные') _tabController.animateTo(3);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Быстрые действия',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Создать игру',
                    Icons.add_circle,
                    AppColors.primary,
                    () => context.push(AppRoutes.createRoom),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Управление командами',
                    Icons.groups,
                    AppColors.secondary,
                    () => _tabController.animateTo(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Статистика команд',
                    Icons.analytics,
                    AppColors.accent,
                    () => _tabController.animateTo(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'История игр',
                    Icons.history,
                    AppColors.warning,
                    () => _tabController.animateTo(3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика по режимам игр',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_gameModeStats.isEmpty)
              const Center(
                child: Text(
                  'Нет данных о режимах игр',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ..._gameModeStats.entries.map((entry) => 
                _buildGameModeRow(entry.key, entry.value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeRow(GameMode mode, int count) {
    final percentage = _totalGames > 0 ? (count / _totalGames * 100) : 0.0;
    final color = _getGameModeColor(mode);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getGameModeDisplayName(mode),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$count игр (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: _totalGames > 0 ? count / _totalGames : 0,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
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

  Widget _buildAnalytics() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Аналитика',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Заполняемость игр
            _buildAnalyticsRow(
              'Средняя заполняемость',
              '${_averageOccupancy.toStringAsFixed(1)}%',
              Icons.people,
            ),
            
            // Общее количество участников
            _buildAnalyticsRow(
              'Всего участников',
              _totalParticipants.toString(),
              Icons.person,
            ),
            
            // Отмененные игры
            if (_cancelledGames > 0)
              _buildAnalyticsRow(
                'Отмененные игры',
                _cancelledGames.toString(),
                Icons.cancel,
              ),
            
            const SizedBox(height: 16),
            
            // Популярные локации
            if (_locationStats.isNotEmpty) ...[
              const Text(
                'Популярные локации:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ..._locationStats.entries.map((entry) => 
                _buildAnalyticsRow(
                  entry.key,
                  '${entry.value} игр',
                  Icons.location_on,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGames() {
    final recentGames = _organizerRooms
        .where((room) => room.status != RoomStatus.cancelled)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final displayGames = recentGames.take(3).toList();
    
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
                  'Последние игры',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (recentGames.length > 3)
                  TextButton(
                    onPressed: () => _tabController.animateTo(3),
                    child: const Text('Все'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (displayGames.isEmpty)
              const Center(
                child: Text(
                  'Нет созданных игр',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...displayGames.map((room) => _buildCompactRoomCard(room)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRoomCard(RoomModel room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.room}/${room.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(room.status),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${room.location} • ${_formatDateTime(room.startTime)}',
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(room.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(room.status),
                      style: TextStyle(
                        color: _getStatusColor(room.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${room.participants.length}/${room.maxParticipants}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Всего команд',
          _totalTeams.toString(),
          Icons.groups,
          AppColors.secondary,
        ),
        _buildStatCard(
          'Активные в играх',
          _activeTeamsInGames.toString(),
          Icons.sports,
          AppColors.success,
        ),
      ],
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
          padding: const EdgeInsets.all(20),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editGame(room),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Изменить'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startGame(room),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Начать'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
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

  // Вспомогательные методы
  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.planned:
        return AppColors.warning;
      case RoomStatus.active:
        return AppColors.success;
      case RoomStatus.completed:
        return AppColors.secondary;
      case RoomStatus.cancelled:
        return AppColors.error;
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

  void _editGame(RoomModel room) {
    // TODO: Реализовать редактирование игры
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция редактирования в разработке')),
    );
  }

  void _startGame(RoomModel room) async {
    try {
      final roomService = ref.read(roomServiceProvider);
      await roomService.updateRoomStatus(room.id, RoomStatus.active.toString().split('.').last);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Игра начата!'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadDashboardData(); // Обновляем данные
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