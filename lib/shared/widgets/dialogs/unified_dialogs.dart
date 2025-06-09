import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

/// Система унифицированных диалогов для приложения
class UnifiedDialogs {
  
  /// Диалог подтверждения (да/нет)
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Да',
    String cancelText = 'Отмена',
    Color? confirmColor,
    IconData? icon,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isDangerous ? AppColors.error : (confirmColor ?? AppColors.primary),
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
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous 
                  ? AppColors.error 
                  : (confirmColor ?? AppColors.primary),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Информационный диалог с одной кнопкой
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Понятно',
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? AppColors.primary,
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
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Диалог предупреждения с выделенным дизайном
  static Future<bool?> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Продолжить',
    String cancelText = 'Отмена',
    String? additionalInfo,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (additionalInfo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        additionalInfo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              cancelText,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Диалог ошибки с красивым дизайном
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Закрыть',
    String? additionalInfo,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (additionalInfo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  additionalInfo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Диалог выбора из списка
  static Future<T?> showSelection<T>({
    required BuildContext context,
    required String title,
    required List<SelectionItem<T>> items,
    String cancelText = 'Отмена',
    IconData? icon,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: AppColors.primary,
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
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: item.icon != null 
                      ? Icon(item.icon, color: AppColors.primary)
                      : null,
                  title: Text(item.title),
                  subtitle: item.subtitle != null 
                      ? Text(item.subtitle!)
                      : null,
                  onTap: () => Navigator.of(context).pop(item.value),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              cancelText,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Диалог с кастомным содержимым
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    IconData? icon,
    Color? iconColor,
    bool scrollable = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? AppColors.primary,
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
        content: scrollable
            ? SingleChildScrollView(child: content)
            : content,
        actions: actions,
      ),
    );
  }

  /// Диалог с текстовым полем для ввода
  static Future<String?> showTextInput({
    required BuildContext context,
    required String title,
    required String labelText,
    String confirmText = 'Создать',
    String cancelText = 'Отмена',
    String? hintText,
    String? Function(String?)? validator,
    IconData? icon,
    Color? confirmColor,
    bool autofocus = true,
  }) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
            validator: validator ?? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Поле не может быть пустым';
              }
              return null;
            },
            autofocus: autofocus,
            onFieldSubmitted: (value) {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              cancelText,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(context).pop(controller.text.trim());
              }
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Готовые специализированные диалоги

  /// Диалог отмены заявки
  static Future<bool?> showCancelApplication({
    required BuildContext context,
    required String teamName,
  }) {
    return showConfirmation(
      context: context,
      title: 'Отменить заявку',
      message: 'Отменить заявку в команду "$teamName"?',
      confirmText: 'Отменить заявку',
      icon: Icons.cancel,
      isDangerous: true,
    );
  }

  /// Диалог выхода из команды с предупреждением
  static Future<bool?> showLeaveTeamWarning({
    required BuildContext context,
    required String teamName,
    required int teamSize,
    bool isOwner = false,
  }) {
    if (isOwner) {
      return showWarning(
        context: context,
        title: '⚠️ Предупреждение',
        message: 'Вы являетесь организатором команды "$teamName".\n\n'
                'При вашем выходе из матча ВСЯ КОМАНДА ($teamSize игроков) '
                'автоматически покинет матч.\n\n'
                'Вы уверены, что хотите продолжить?',
        confirmText: 'Да, вся команда покинет матч',
        additionalInfo: 'Это действие нельзя отменить',
      );
    } else {
      return showConfirmation(
        context: context,
        title: 'Покинуть команду',
        message: 'Вы уверены, что хотите покинуть команду "$teamName"?',
        confirmText: 'Покинуть',
        icon: Icons.exit_to_app,
        isDangerous: true,
      );
    }
  }

  /// Диалог удаления участника из команды
  static Future<bool?> showRemoveMember({
    required BuildContext context,
    required String memberName,
    required String teamName,
  }) {
    return showConfirmation(
      context: context,
      title: 'Удалить участника',
      message: 'Удалить $memberName из команды "$teamName"?',
      confirmText: 'Удалить',
      icon: Icons.person_remove,
      isDangerous: true,
    );
  }

  /// Диалог подтверждения старта игры
  static Future<bool?> showStartGameEarly({
    required BuildContext context,
  }) {
    return showConfirmation(
      context: context,
      title: 'Начать игру раньше?',
      message: AppStrings.confirmStartEarly,
      confirmText: 'Начать',
      icon: Icons.play_arrow,
      confirmColor: AppColors.success,
    );
  }

  /// Диалог подтверждения завершения игры
  static Future<bool?> showEndGameEarly({
    required BuildContext context,
  }) {
    return showConfirmation(
      context: context,
      title: 'Завершить игру раньше?',
      message: AppStrings.confirmEndEarly,
      confirmText: 'Завершить',
      icon: Icons.stop,
      confirmColor: AppColors.primary,
    );
  }

  /// Диалог создания команды
  static Future<String?> showCreateTeam({
    required BuildContext context,
  }) {
    return showTextInput(
      context: context,
      title: AppStrings.createTeam,
      labelText: 'Название команды',
      confirmText: AppStrings.createTeam,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Введите название команды';
        }
        return null;
      },
      icon: Icons.groups,
    );
  }
}

/// Элемент для диалога выбора
class SelectionItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;

  const SelectionItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
  });
} 