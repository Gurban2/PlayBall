import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../auth/domain/entities/user_model.dart';

class PlayerGamesHistoryCard extends StatelessWidget {
  final UserModel player;

  const PlayerGamesHistoryCard({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final recentGames = player.recentGames;

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
                Icon(Icons.history, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Последние игры',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (recentGames.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sports_volleyball_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Еще не сыграно ни одной игры',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: recentGames.map((game) => _GameItem(game: game)).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// Виджет для отображения одной игры
class _GameItem extends StatelessWidget {
  final GameRef game;

  const _GameItem({required this.game});

  @override
  Widget build(BuildContext context) {
    final isWin = game.result == 'win';
    final isLoss = game.result == 'loss';
    final isCancelled = game.result == 'cancelled';

    Color resultColor;
    String resultText;
    IconData resultIcon;

    if (isCancelled) {
      resultColor = AppColors.textSecondary;
      resultText = 'Отменена';
      resultIcon = Icons.cancel;
    } else if (isWin) {
      resultColor = AppColors.success;
      resultText = 'Победа';
      resultIcon = Icons.emoji_events;
    } else {
      resultColor = AppColors.error;
      resultText = 'Поражение';
      resultIcon = Icons.close;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: resultColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: resultColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Полоска результата
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: resultColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            
            // Информация об игре
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        game.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.date.day}.${game.date.month}.${game.date.year}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  // Информация о напарниках если есть
                  if (game.teammates.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Партнеры: ${game.teammates.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Результат игры
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: resultColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    resultIcon,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    resultText,
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
    );
  }
} 