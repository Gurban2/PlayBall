import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isConfirming = false;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyConfirmed();
  }

  /// Проверяем, подтвердил ли уже игрок готовность
  Future<void> _checkIfAlreadyConfirmed() async {
    final checkId = widget.notification.additionalData?['checkId'] as String?;
    if (checkId == null) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    try {
      final teamService = ref.read(teamServiceProvider);
      final activityCheck = await teamService.getActivityCheckById(checkId);
      
      if (activityCheck != null && activityCheck.isPlayerReady(currentUser.id)) {
        setState(() {
          _isConfirmed = true;
        });
      }
    } catch (e) {
      // Игнорируем ошибки, чтобы не блокировать отображение уведомления
    }
  }

  Future<void> _confirmReadiness() async {
    final checkId = widget.notification.additionalData?['checkId'] as String?;
    if (checkId == null) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      final activityService = ref.read(teamActivityServiceProvider);
      await activityService.confirmReadiness(
        checkId: checkId,
        playerId: currentUser.id,
      );

      setState(() {
        _isConfirmed = true;
      });

      if (mounted) {
        ErrorHandler.showSuccess(context, 'Готовность подтверждена!');

        // Отмечаем уведомление как прочитанное
        widget.onMarkAsRead?.call();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkId = widget.notification.additionalData?['checkId'] as String?;
    final teamName = widget.notification.additionalData?['teamName'] as String? ?? 'Команда';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с иконкой
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notification_important,
                    color: AppColors.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.notification.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Команда: $teamName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Сообщение
            Text(
              widget.notification.message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Кнопка действия или статус
            if (checkId != null) ...[
              if (_isConfirmed) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Готовность подтверждена',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isConfirming ? null : _confirmReadiness,
                    icon: _isConfirming 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isConfirming ? 'Подтверждение...' : 'Готов'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
            
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }
} 