import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/constants.dart';

class ErrorHandler {
  // Базовый метод для создания SnackBar с единым стилем
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              )
            : null,
      ),
    );
  }

  // Обработка различных типов ошибок
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return _getFirestoreErrorMessage(error);
    } else if (error is String) {
      return error;
    } else {
      return 'Произошла неожиданная ошибка: ${error.toString()}';
    }
  }

  // Основные методы отображения
  static void showError(BuildContext context, dynamic error, {Duration? duration}) {
    final message = getErrorMessage(error);
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
      duration: duration ?? const Duration(seconds: 4),
      actionLabel: 'OK',
    );
  }

  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showWarning(BuildContext context, String message, {Duration? duration}) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.primary,
      icon: Icons.info_outline,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  // Быстрые методы для частых операций
  static void saved(BuildContext context, [String? item]) {
    showSuccess(context, item != null ? '$item сохранен' : 'Сохранено');
  }

  static void deleted(BuildContext context, [String? item]) {
    showSuccess(context, item != null ? '$item удален' : 'Удалено');
  }

  static void created(BuildContext context, [String? item]) {
    showSuccess(context, item != null ? '$item создан' : 'Создано');
  }

  static void updated(BuildContext context, [String? item]) {
    showSuccess(context, item != null ? '$item обновлен' : 'Обновлено');
  }

  static void joined(BuildContext context, [String? item]) {
    showSuccess(context, item != null ? 'Присоединились к $item' : 'Присоединились');
  }

  static void left(BuildContext context, [String? item]) {
    showInfo(context, item != null ? 'Покинули $item' : 'Покинули');
  }

  static void sent(BuildContext context, [String? item]) {
    showSuccess(context, item != null ? '$item отправлен' : 'Отправлено');
  }

  static void cancelled(BuildContext context, [String? item]) {
    showWarning(context, item != null ? '$item отменен' : 'Отменено');
  }

  static void accepted(BuildContext context, [String? item]) {
    showSuccess(context, item != null ? '$item принят' : 'Принято');
  }

  static void rejected(BuildContext context, [String? item]) {
    showWarning(context, item != null ? '$item отклонен' : 'Отклонено');
  }

  static void invited(BuildContext context, String target) {
    showSuccess(context, 'Приглашение отправлено $target');
  }

  static void removed(BuildContext context, String target) {
    showInfo(context, '$target исключен');
  }

  static void added(BuildContext context, String target) {
    showSuccess(context, '$target добавлен');
  }

  // Методы для команд
  static void teamCreated(BuildContext context, String teamName) {
    showSuccess(context, 'Команда "$teamName" создана');
  }

  static void teamJoined(BuildContext context, String teamName) {
    showSuccess(context, 'Вы присоединились к команде "$teamName"');
  }

  static void teamLeft(BuildContext context, String teamName) {
    showInfo(context, 'Вы покинули команду "$teamName"');
  }

  static void teamDeleted(BuildContext context, String teamName) {
    showInfo(context, 'Команда "$teamName" удалена');
  }

  // Методы для игр
  static void gameCreated(BuildContext context) {
    showSuccess(context, 'Игра создана успешно');
  }

  static void gameJoined(BuildContext context) {
    showSuccess(context, 'Вы присоединились к игре');
  }

  static void gameLeft(BuildContext context) {
    showInfo(context, 'Вы покинули игру');
  }

  static void gameStarted(BuildContext context) {
    showSuccess(context, 'Игра началась');
  }

  static void gameEnded(BuildContext context) {
    showSuccess(context, 'Игра завершена');
  }

  static void gameCancelled(BuildContext context) {
    showWarning(context, 'Игра отменена');
  }

  // Методы для друзей
  static void friendAdded(BuildContext context, String name) {
    showSuccess(context, '$name добавлен в друзья');
  }

  static void friendRemoved(BuildContext context, String name) {
    showInfo(context, '$name удален из друзей');
  }

  static void friendRequestSent(BuildContext context, String name) {
    showSuccess(context, 'Запрос дружбы отправлен $name');
  }

  static void friendRequestAccepted(BuildContext context, String name) {
    showSuccess(context, '$name принял запрос дружбы');
  }

  static void friendRequestRejected(BuildContext context, String name) {
    showWarning(context, 'Запрос дружбы к $name отклонен');
  }

  static void friendRequestCancelled(BuildContext context, String name) {
    showWarning(context, 'Запрос дружбы к $name отменен');
  }

  // Методы для валидации
  static void validation(BuildContext context, String field) {
    showWarning(context, 'Проверьте поле "$field"');
  }

  static void required(BuildContext context, String field) {
    showWarning(context, 'Поле "$field" обязательно для заполнения');
  }

  static void invalidFormat(BuildContext context, String field) {
    showWarning(context, 'Неверный формат поля "$field"');
  }

  // Методы для сети и системы
  static void networkError(BuildContext context) {
    showError(context, 'Проблемы с подключением к интернету');
  }

  static void permissionDenied(BuildContext context) {
    showError(context, 'Недостаточно прав для выполнения операции');
  }

  static void notFound(BuildContext context, [String? item]) {
    showError(context, item != null ? '$item не найден' : 'Данные не найдены');
  }

  static void alreadyExists(BuildContext context, [String? item]) {
    showWarning(context, item != null ? '$item уже существует' : 'Данные уже существуют');
  }

  static void loading(BuildContext context, [String? action]) {
    showInfo(context, action != null ? '$action...' : 'Загрузка...');
  }

  static void noData(BuildContext context, [String? type]) {
    showInfo(context, type != null ? 'Нет данных: $type' : 'Нет данных');
  }

  // Методы для навигации и маршрутизации
  static void navigationError(BuildContext context, String route) {
    showError(context, 'Ошибка навигации: страница "$route" не найдена');
  }

  static void authenticationError(BuildContext context) {
    showError(context, 'Ошибка проверки авторизации. Попробуйте войти заново.');
  }

  static void invalidRoute(BuildContext context, String route) {
    showError(context, 'Неверный маршрут: $route');
  }

  static void invalidParameter(BuildContext context, String parameter) {
    showError(context, 'Недопустимый параметр: $parameter');
  }

  static void routeNotFound(BuildContext context, String path) {
    showError(context, 'Страница не найдена: $path', 
      duration: const Duration(seconds: 5));
  }

  // Методы для длительных операций с действием
  static void withAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    bool isError = false,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      icon: isError ? Icons.error_outline : Icons.info_outline,
      duration: const Duration(seconds: 6),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  // Ошибки аутентификации
  static String _getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'Пользователь с таким email не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Пользователь с таким email уже существует';
      case 'weak-password':
        return 'Пароль слишком слабый (минимум 6 символов)';
      case 'invalid-email':
        return 'Неверный формат email адреса';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток входа. Попробуйте позже';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      case 'network-request-failed':
        return 'Ошибка сети. Проверьте подключение к интернету';
      default:
        return 'Ошибка аутентификации: ${error.message ?? error.code}';
    }
  }

  // Ошибки Firestore
  static String _getFirestoreErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Недостаточно прав для выполнения операции';
      case 'not-found':
        return 'Запрашиваемые данные не найдены';
      case 'unavailable':
        return 'Сервис временно недоступен. Попробуйте позже';
      case 'cancelled':
        return 'Операция была отменена';
      case 'deadline-exceeded':
        return 'Время ожидания истекло';
      case 'already-exists':
        return 'Данные уже существуют';
      case 'resource-exhausted':
        return 'Превышена квота запросов';
      case 'failed-precondition':
        return 'Не выполнены условия для операции';
      case 'aborted':
        return 'Операция прервана из-за конфликта';
      case 'out-of-range':
        return 'Значение вне допустимого диапазона';
      case 'unimplemented':
        return 'Операция не поддерживается';
      case 'internal':
        return 'Внутренняя ошибка сервера';
      case 'data-loss':
        return 'Потеря данных';
      case 'unauthenticated':
        return 'Требуется авторизация';
      default:
        return 'Ошибка базы данных: ${error.message ?? error.code}';
    }
  }
} 