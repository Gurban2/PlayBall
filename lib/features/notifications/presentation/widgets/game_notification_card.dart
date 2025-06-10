import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/game_notification_model.dart';
import '../../../../core/constants/constants.dart';

/// Карточка уведомления о игре с красивым дизайном
class GameNotificationCard extends StatelessWidget {
  final GameNotificationModel notification;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const GameNotificationCard({
    super.key,
    required this.notification,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: notification.isRead ? 1 : 4,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead 
              ? Colors.transparent 
              : _getNotificationColor(),
          width: notification.isRead ? 0 : 2,
        ),
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и время
              Row(
                children: [
                  // Иконка типа уведомления
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getNotificationColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notification.icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Заголовок и время
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead 
                                ? FontWeight.w600 
                                : FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _formatDateTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Индикатор непрочитанного
                  if (!notification.isRead)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getNotificationColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Сообщение
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.text,
                  fontWeight: notification.isRead 
                      ? FontWeight.normal 
                      : FontWeight.w500,
                  height: 1.3,
                ),
              ),
              
              // Дополнительная информация
              if (notification.scheduledDateTime != null) ...[
                const SizedBox(height: 6),
                _buildScheduleInfo(),
              ],
              
              // Дополнительные данные
              if (notification.additionalData != null) ...[
                const SizedBox(height: 6),
                _buildAdditionalInfo(),
              ],
              
              const SizedBox(height: 8),
              
              // Кнопки действий
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Кнопка "Перейти к игре" или "Оценить игроков"
                  TextButton.icon(
                    onPressed: () {
                      // Удаляем уведомление после просмотра
                      if (onDelete != null) {
                        onDelete!();
                      }
                      _navigateToRoom(context);
                    },
                    icon: Icon(
                      _getActionIcon(), 
                      size: 14,
                    ),
                    label: Text(
                      _getActionText(),
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _getNotificationColor(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                  
                  // Кнопка удаления
                  if (onDelete != null) ...[
                    const SizedBox(width: 6),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Скрыть', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
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

  /// Информация о времени проведения игры
  Widget _buildScheduleInfo() {
    if (notification.scheduledDateTime == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 3),
          Text(
            _formatDateTime(notification.scheduledDateTime!),
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Дополнительная информация из additionalData
  Widget _buildAdditionalInfo() {
    final data = notification.additionalData;
    if (data == null || data.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 6,
      runSpacing: 3,
      children: data.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _getNotificationColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${_formatKey(entry.key)}: ${entry.value}',
            style: TextStyle(
              fontSize: 10,
              color: _getNotificationColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Получить цвет уведомления по типу
  Color _getNotificationColor() {
    final colorHex = notification.colorHex;
    return Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  /// Форматировать дату и время
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    }
  }

  /// Форматировать ключ дополнительных данных
  String _formatKey(String key) {
    switch (key) {
      case 'location':
        return 'Место';
      case 'minutesLeft':
        return 'Осталось мин';
      case 'winner':
        return 'Победитель';
      case 'reason':
        return 'Причина';
      case 'playerName':
        return 'Игрок';
      default:
        return key;
    }
  }

  /// Обработчик нажатия на карточку
  void _handleTap(BuildContext context) {
    // Удаляем уведомление после просмотра
    if (onDelete != null) {
      onDelete!();
    }
    
    // Переходим к игре
    _navigateToRoom(context);
  }

  /// Переход к странице игры
  void _navigateToRoom(BuildContext context) {
    if (notification.type == GameNotificationType.evaluationRequired) {
      // Для уведомлений об оценке переходим на экран оценки
      context.push('/game-evaluation/${notification.roomId}');
    } else if (notification.type == GameNotificationType.winnerSelectionRequired) {
      // Для уведомлений о выборе победителя переходим на экран выбора победителя
      context.push('/winner-selection/${notification.roomId}');
    } else if (notification.type == GameNotificationType.activityCheck || 
               notification.type == GameNotificationType.activityCheckCompleted) {
      // Для уведомлений о проверке готовности переходим на страницу команды
      final teamId = notification.additionalData?['teamId'] ?? notification.roomId;
      context.push('/team-view/$teamId');
    } else {
      // Для остальных уведомлений переходим к комнате
      context.push('/room/${notification.roomId}');
    }
  }

  /// Получить иконку действия
  IconData _getActionIcon() {
    switch (notification.type) {
      case GameNotificationType.evaluationRequired:
        return Icons.star;
      case GameNotificationType.winnerSelectionRequired:
        return Icons.sports_volleyball;
      case GameNotificationType.activityCheck:
        return Icons.check;
      case GameNotificationType.activityCheckCompleted:
        return Icons.assessment;
      default:
        return Icons.sports_volleyball;
    }
  }

  /// Получить текст действия
  String _getActionText() {
    switch (notification.type) {
      case GameNotificationType.evaluationRequired:
        return 'Оценить';
      case GameNotificationType.winnerSelectionRequired:
        return 'К игре';
      case GameNotificationType.activityCheck:
        return 'Ответить';
      case GameNotificationType.activityCheckCompleted:
        return 'Результаты';
      default:
        return 'К игре';
    }
  }
}

/// Карточка-заглушка для состояния загрузки
class GameNotificationSkeletonCard extends StatelessWidget {
  const GameNotificationSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 14,
              width: 200,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 