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
      margin: const EdgeInsets.only(bottom: 12),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: notification.isRead 
                ? null 
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getNotificationColor().withOpacity(0.05),
                      _getNotificationColor().withOpacity(0.02),
                    ],
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и время
              Row(
                children: [
                  // Иконка типа уведомления
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notification.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Заголовок и время
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead 
                                ? FontWeight.w600 
                                : FontWeight.bold,
                            color: _getNotificationColor(),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
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
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getNotificationColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Сообщение
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                  fontWeight: notification.isRead 
                      ? FontWeight.normal 
                      : FontWeight.w500,
                  height: 1.4,
                ),
              ),
              
              // Дополнительная информация
              if (notification.scheduledDateTime != null) ...[
                const SizedBox(height: 8),
                _buildScheduleInfo(),
              ],
              
              // Дополнительные данные
              if (notification.additionalData != null) ...[
                const SizedBox(height: 8),
                _buildAdditionalInfo(),
              ],
              
              const SizedBox(height: 12),
              
              // Кнопки действий
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Кнопка "Перейти к игре"
                  TextButton.icon(
                    onPressed: () => _navigateToRoom(context),
                    icon: const Icon(Icons.sports_volleyball, size: 16),
                    label: const Text('К игре'),
                    style: TextButton.styleFrom(
                      foregroundColor: _getNotificationColor(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Кнопка "Отметить как прочитанное"
                  if (!notification.isRead && onMarkAsRead != null)
                    TextButton.icon(
                      onPressed: onMarkAsRead,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Прочитано'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  
                  // Кнопка удаления
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppColors.textSecondary,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDateTime(notification.scheduledDateTime!),
            style: TextStyle(
              fontSize: 12,
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
      spacing: 8,
      runSpacing: 4,
      children: data.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getNotificationColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${_formatKey(entry.key)}: ${entry.value}',
            style: TextStyle(
              fontSize: 11,
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
    // Отмечаем как прочитанное при нажатии
    if (!notification.isRead && onMarkAsRead != null) {
      onMarkAsRead!();
    }
    
    // Переходим к игре
    _navigateToRoom(context);
  }

  /// Переход к странице игры
  void _navigateToRoom(BuildContext context) {
    context.push('/room/${notification.roomId}');
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