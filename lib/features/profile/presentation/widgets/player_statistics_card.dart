import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../auth/domain/entities/user_model.dart';

class PlayerStatisticsCard extends StatelessWidget {
  final UserModel player;

  const PlayerStatisticsCard({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Статистика',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Основная статистика в сетке
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _StatisticItem(
                  icon: Icons.sports_volleyball,
                  label: 'Игр сыграно',
                  value: '${player.gamesPlayed}',
                  color: AppColors.primary,
                ),
                _StatisticItem(
                  icon: Icons.trending_up,
                  label: 'Винрейт',
                  value: '${player.winRate.toStringAsFixed(0)}%',
                  color: AppColors.success,
                ),
                _StatisticItem(
                  icon: Icons.emoji_events,
                  label: 'Побед',
                  value: '${player.wins}',
                  color: AppColors.warning,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Дополнительная статистика
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _DetailedStatRow(
                    label: 'Поражений',
                    value: '${player.losses}',
                    icon: Icons.trending_down,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 8),
                  _DetailedStatRow(
                    label: 'Средняя оценка',
                    value: player.rating.toStringAsFixed(1),
                    icon: Icons.star,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 8),
                  _DetailedStatRow(
                    label: 'Друзей',
                    value: '${player.friends.length}',
                    icon: Icons.people,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Виджет для отображения элемента статистики в сетке
class _StatisticItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatisticItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Виджет для отображения подробной статистики
class _DetailedStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailedStatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
} 