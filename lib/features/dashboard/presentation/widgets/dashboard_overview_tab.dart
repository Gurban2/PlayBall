import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../shared/widgets/cards/stat_card.dart';
import '../widgets/quick_actions_list.dart';

class DashboardOverviewTab extends StatelessWidget {
  final int totalGames;
  final int activeGames;
  final int plannedGames;
  final int completedGames;
  final int cancelledGames;
  final TabController tabController;
  final VoidCallback onRefresh;

  const DashboardOverviewTab({
    super.key,
    required this.totalGames,
    required this.activeGames,
    required this.plannedGames,
    required this.completedGames,
    required this.cancelledGames,
    required this.tabController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и кнопка обновления
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Обзор статистики',
                style: AppTextStyles.heading2,
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                color: AppColors.primary,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Горизонтальная прокрутка со статистикой
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                StatCard(
                  title: 'Всего игр',
                  value: totalGames.toString(),
                  icon: Icons.sports_volleyball,
                  color: AppColors.primary,
                  onTap: () {},
                ),
                StatCard(
                  title: 'Активные',
                  value: activeGames.toString(),
                  icon: Icons.play_arrow,
                  color: AppColors.success,
                  onTap: () => tabController.animateTo(1),
                ),
                StatCard(
                  title: 'Запланированные',
                  value: plannedGames.toString(),
                  icon: Icons.schedule,
                  color: AppColors.warning,
                  onTap: () => tabController.animateTo(2),
                ),
                StatCard(
                  title: 'Завершенные',
                  value: completedGames.toString(),
                  icon: Icons.check_circle,
                  color: AppColors.secondary,
                  onTap: () => tabController.animateTo(3),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Быстрые действия
          QuickActionsList(tabController: tabController),
          
          const SizedBox(height: 24),
          
          // TODO: Добавить остальные компоненты
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Статистика по режимам игр - в разработке'),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Аналитика - в разработке'),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Последние игры - в разработке'),
            ),
          ),
        ],
      ),
    );
  }
} 