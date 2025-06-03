import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  // Обработка различных типов ошибок
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return _getFirestoreErrorMessage(error);
    } else {
      return 'Произошла ошибка: ${error.toString()}';
    }
  }

  // Отображение ошибки пользователю
  static void showError(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Ошибки аутентификации
  static String _getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Этот email уже используется';
      case 'weak-password':
        return 'Слишком слабый пароль';
      case 'invalid-email':
        return 'Неверный формат email';
      default:
        return 'Ошибка входа: ${error.message}';
    }
  }

  // Ошибки Firestore
  static String _getFirestoreErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Недостаточно прав';
      case 'not-found':
        return 'Данные не найдены';
      case 'unavailable':
        return 'Сервис недоступен';
      default:
        return 'Ошибка базы данных: ${error.message}';
    }
  }
} 