import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../features/rooms/domain/entities/room_model.dart';
import 'unified_dialogs.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = AppStrings.confirm,
    this.cancelText = AppStrings.cancel,
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: confirmColor ?? AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: AppSizes.smallSpace),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(
            cancelText,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Упрощенные статические методы с использованием UnifiedDialogs
  static Future<bool?> showStartEarly(BuildContext context) {
    return UnifiedDialogs.showStartGameEarly(context: context);
  }

  static Future<bool?> showEndEarly(BuildContext context) {
    return UnifiedDialogs.showEndGameEarly(context: context);
  }

  static void showLocationConflict(
    BuildContext context, {
    required DateTime plannedStartTime,
    RoomModel? conflictingRoom,
  }) {
    final timeFormat = '${plannedStartTime.hour}:${plannedStartTime.minute.toString().padLeft(2, '0')}';
    
    String message = '${AppStrings.locationConflict} ($timeFormat)';
    String? additionalInfo;
    if (conflictingRoom != null) {
      final conflictEndTime = '${conflictingRoom.endTime.hour}:${conflictingRoom.endTime.minute.toString().padLeft(2, '0')}';
      additionalInfo = 'Зал будет свободен в $conflictEndTime';
    }

    UnifiedDialogs.showWarning(
      context: context,
      title: 'Зал занят',
      message: message,
      confirmText: 'Изменить время',
      cancelText: 'Понятно',
      additionalInfo: additionalInfo,
    );
  }
} 