import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers.dart';
import '../widgets/dashboard_overview_tab.dart';
import '../widgets/active_games_tab.dart';

class OrganizerDashboardRefactoredScreen extends ConsumerStatefulWidget {
  const OrganizerDashboardRefactoredScreen({super.key});

  @override
  ConsumerState<OrganizerDashboardRefactoredScreen> createState() => 
      _OrganizerDashboardRefactoredScreenState();
}

class _OrganizerDashboardRefactoredScreenState 
    extends ConsumerState<OrganizerDashboardRefactoredScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  bool _isLoading = false;
  
  // Статистика игр
  int _totalGames = 0;
  int _activeGames = 0;
  int _plannedGames = 0;
  int _completedGames = 0;
  int _cancelledGames = 0;
  
  // Статистика команд
  int _totalTeams = 0;

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
        // TODO: Загрузка реальных данных
        // Пока используем заглушки
        await Future.delayed(const Duration(seconds: 1));
        
        _totalGames = 15;
        _activeGames = 3;
        _plannedGames = 5;
        _completedGames = 7;
        _cancelledGames = 0;
        _totalTeams = 8;
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
                DashboardOverviewTab(
                  totalGames: _totalGames,
                  activeGames: _activeGames,
                  plannedGames: _plannedGames,
                  completedGames: _completedGames,
                  cancelledGames: _cancelledGames,
                  tabController: _tabController,
                  onRefresh: _loadDashboardData,
                ),
                ActiveGamesTab(
                  activeGamesCount: _activeGames,
                  onRefresh: _loadDashboardData,
                ),
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

  Widget _buildPlannedGamesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.schedule,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Запланированные игры ($_plannedGames)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Функционал в разработке',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'История игр ($_completedGames завершено)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Функционал в разработке',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.groups,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Управление командами ($_totalTeams команд)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Функционал в разработке',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
} 