import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Базовый сервис для всех типов уведомлений
abstract class BaseNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Название коллекции в Firestore
  String get collectionName;

  /// Генерировать уникальный ID
  String generateId() => _uuid.v4();

  /// Логирование успешных операций
  void logSuccess(String operation, {int? count, String? details}) {
    if (count != null) {
      debugPrint('✅ $operation: $count уведомлений${details != null ? ' - $details' : ''}');
    } else {
      debugPrint('✅ $operation${details != null ? ': $details' : ''}');
    }
  }

  /// Логирование ошибок
  void logError(String operation, dynamic error) {
    debugPrint('❌ Ошибка $operation: $error');
  }

  /// Логирование предупреждений
  void logWarning(String message) {
    debugPrint('⚠️ $message');
  }

  /// Логирование информационных сообщений
  void logInfo(String message) {
    debugPrint('🔍 $message');
  }

  /// Выполнить операцию с логированием и обработкой ошибок
  Future<T> executeWithLogging<T>(
    String operationName,
    Future<T> Function() operation, {
    String? successDetails,
    bool rethrowErrors = true,
  }) async {
    try {
      final result = await operation();
      logSuccess(operationName, details: successDetails);
      return result;
    } catch (e) {
      logError(operationName, e);
      if (rethrowErrors) rethrow;
      throw e;
    }
  }

  /// Выполнить операцию без возврата значения
  Future<void> executeVoidWithLogging(
    String operationName,
    Future<void> Function() operation, {
    String? successDetails,
    bool rethrowErrors = true,
  }) async {
    await executeWithLogging<void>(
      operationName,
      operation,
      successDetails: successDetails,
      rethrowErrors: rethrowErrors,
    );
  }

  /// Отправить множественные уведомления через batch операцию
  Future<void> sendBatchNotifications(
    List<Map<String, dynamic>> notifications,
    String operationName,
  ) async {
    if (notifications.isEmpty) {
      logWarning('Нет уведомлений для отправки: $operationName');
      return;
    }

    await executeVoidWithLogging(
      operationName,
      () async {
        final batch = _firestore.batch();
        
        for (final notificationData in notifications) {
          final docRef = _firestore
              .collection(collectionName)
              .doc(notificationData['id']);
          
          batch.set(docRef, notificationData);
        }

        await batch.commit();
      },
      successDetails: '${notifications.length} уведомлений отправлено',
    );
  }

  /// Получить уведомления для пользователя с базовой фильтрацией
  Future<List<Map<String, dynamic>>> getUserNotifications(
    String userId, {
    int limit = 50,
    String? whereField,
    dynamic whereValue,
  }) async {
    return executeWithLogging(
      'получения уведомлений для пользователя $userId',
      () async {
        Query query = _firestore
            .collection(collectionName)
            .where('recipientIds', arrayContains: userId)
            .orderBy('createdAt', descending: true)
            .limit(limit);

        if (whereField != null && whereValue != null) {
          query = query.where(whereField, isEqualTo: whereValue);
        }

        final querySnapshot = await query.get();
        return querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      },
      rethrowErrors: false,
    ).catchError((e) {
      logError('получения уведомлений для пользователя $userId', e);
      return <Map<String, dynamic>>[];
    });
  }

  /// Получить стрим уведомлений для пользователя
  Stream<List<Map<String, dynamic>>> getUserNotificationsStream(
    String userId, {
    int limit = 50,
    String? whereField,
    dynamic whereValue,
  }) {
    Query query = _firestore
        .collection(collectionName)
        .where('recipientIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (whereField != null && whereValue != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }

    return query.snapshots().map((snapshot) => 
        snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    await executeVoidWithLogging(
      'отметки уведомления как прочитанного',
      () async {
        await _firestore
            .collection(collectionName)
            .doc(notificationId)
            .update({'isRead': true});
      },
      successDetails: 'ID: $notificationId',
    );
  }

  /// Отметить все уведомления пользователя как прочитанные
  Future<void> markAllAsRead(String userId) async {
    await executeVoidWithLogging(
      'отметки всех уведомлений как прочитанных',
      () async {
        final querySnapshot = await _firestore
            .collection(collectionName)
            .where('recipientIds', arrayContains: userId)
            .where('isRead', isEqualTo: false)
            .get();

        if (querySnapshot.docs.isEmpty) {
          logInfo('Нет непрочитанных уведомлений для пользователя $userId');
          return;
        }

        final batch = _firestore.batch();
        
        for (var doc in querySnapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }

        await batch.commit();
      },
      successDetails: 'пользователь $userId',
    );
  }

  /// Удалить уведомление
  Future<void> deleteNotification(String notificationId) async {
    await executeVoidWithLogging(
      'удаления уведомления',
      () async {
        await _firestore
            .collection(collectionName)
            .doc(notificationId)
            .delete();
      },
      successDetails: 'ID: $notificationId',
    );
  }

  /// Получить количество непрочитанных уведомлений
  Future<int> getUnreadCount(String userId) async {
    return executeWithLogging(
      'получения количества непрочитанных уведомлений',
      () async {
        final querySnapshot = await _firestore
            .collection(collectionName)
            .where('recipientIds', arrayContains: userId)
            .where('isRead', isEqualTo: false)
            .get();

        return querySnapshot.docs.length;
      },
      rethrowErrors: false,
    ).catchError((e) {
      logError('получения количества непрочитанных уведомлений', e);
      return 0;
    });
  }

  /// Удалить старые уведомления (старше указанного времени)
  Future<void> cleanupOldNotifications(Duration maxAge) async {
    await executeVoidWithLogging(
      'очистки старых уведомлений',
      () async {
        final cutoffDate = DateTime.now().subtract(maxAge);
        final querySnapshot = await _firestore
            .collection(collectionName)
            .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
            .get();

        if (querySnapshot.docs.isEmpty) {
          logInfo('Нет старых уведомлений для удаления');
          return;
        }

        final batch = _firestore.batch();
        
        for (var doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      },
      successDetails: 'старше ${maxAge.inDays} дней',
    );
  }
} 