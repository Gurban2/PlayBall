import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/providers.dart';
import '../../../features/notifications/domain/entities/game_notification_model.dart';

/// Виджет для отображения уведомления о проверке активности команды
class ActivityCheckNotificationWidget extends ConsumerStatefulWidget {
  final GameNotificationModel notification;
  final VoidCallback? onMarkAsRead;

  const ActivityCheckNotificationWidget({
    super.key,
    required this.notification,
    this.onMarkAsRead,
  });

  @override
  ConsumerState<ActivityCheckNotificationWidget> createState() => _ActivityCheckNotificationWidgetState();
}

class _ActivityCheckNotificationWidgetState extends ConsumerState<ActivityCheckNotificationWidget> {
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyResponded();
  }

  /// Проверяем, ответил ли уже игрок
  Future<void> _checkIfAlreadyResponded() async {
    final checkId = widget.notification.additionalData?['checkId'] as String?;
    if (checkId == null) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    try {
      final teamService = ref.read(teamServiceProvider);
      final activityCheck = await teamService.getActivityCheckById(checkId);
      
      if (activityCheck != null && activityCheck.isPlayerReady(currentUser.id)) {
        setState(() {
          _isChecked = true;
        });
      }
    } catch (e) {
      // Игнорируем ошибки, чтобы не блокировать отображение уведомления
    }
  }

  void _navigateToTeam() {
    final teamId = widget.notification.additionalData?['teamId'] as String?;
    if (teamId == null) {
      ErrorHandler.showError(context, 'Не удалось найти команду');
      return;
    }

    // Отмечаем уведомление как прочитанное
    widget.onMarkAsRead?.call();

    // Переходим на страницу команды
    context.push('/team-view/$teamId');
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ч назад';
    } else {
      return '${difference.inDays} дн назад';
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamName = widget.notification.additionalData?['teamName'] as String? ?? 'Команда';
    final isCompletedNotification = widget.notification.type == GameNotificationType.activityCheckCompleted;
    
    return GestureDetector(
      onTap: _navigateToTeam,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompletedNotification 
                ? AppColors.success
                : (_isChecked ? AppColors.success : AppColors.warning),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCompletedNotification 
                        ? AppColors.success.withValues(alpha: 0.1)
                        : ((_isChecked ? AppColors.success : AppColors.warning).withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCompletedNotification 
                        ? Icons.check_circle 
                        : (_isChecked ? Icons.check_circle : Icons.access_time),
                    color: isCompletedNotification 
                        ? AppColors.success
                        : (_isChecked ? AppColors.success : AppColors.warning),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.notification.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Команда
            Text(
              'Команда: $teamName',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Сообщение
            Text(
              widget.notification.message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Статус или призыв к действию
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCompletedNotification 
                    ? AppColors.success.withValues(alpha: 0.1)
                    : (_isChecked 
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isCompletedNotification 
                        ? Icons.assessment 
                        : (_isChecked ? Icons.check_circle : Icons.touch_app),
                    color: isCompletedNotification 
                        ? AppColors.success
                        : (_isChecked ? AppColors.success : AppColors.primary),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCompletedNotification
                          ? 'Нажмите, чтобы посмотреть результаты'
                          : (_isChecked 
                              ? 'Вы уже ответили' 
                              : 'Нажмите, чтобы ответить'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isCompletedNotification 
                            ? AppColors.success
                            : (_isChecked ? AppColors.success : AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Время
            Text(
              _formatTime(widget.notification.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 