import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/data/datasources/user_service.dart';
import '../../../notifications/data/datasources/game_notification_service.dart';
import '../../../rooms/data/datasources/room_service.dart';
import '../../domain/entities/player_evaluation_model.dart';

class PlayerEvaluationService {
  static const String _collection = 'player_evaluations';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Сохранить оценки игроков
  Future<void> savePlayerEvaluations({
    required String gameId,
    required String organizerId,
    required List<String> selectedPlayerIds,
    String? comment,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();
      final userService = UserService();
      final gameNotificationService = GameNotificationService();
      final roomService = RoomService();

      // Получаем информацию об организаторе и игре для уведомлений
      final organizer = await userService.getUserById(organizerId);
      final room = await roomService.getRoomById(gameId);
      
      if (organizer == null) {
        throw Exception('Организатор не найден');
      }
      
      if (room == null) {
        throw Exception('Игра не найдена');
      }

      debugPrint('💾 Сохраняем оценки от ${organizer.name} для игры $gameId');
      debugPrint('⭐ Оцененные игроки: $selectedPlayerIds');

      for (final playerId in selectedPlayerIds) {
        // Создаем запись оценки
        final evaluation = PlayerEvaluationModel(
          id: _uuid.v4(),
          gameId: gameId,
          organizerId: organizerId,
          playerId: playerId,
          points: 1, // Каждый выбранный игрок получает 1 балл
          comment: comment,
          createdAt: now,
        );

        final evalDoc = _firestore.collection(_collection).doc(evaluation.id);
        batch.set(evalDoc, evaluation.toMap());

        // Начисляем +1 балл игроку
        final playerDoc = _firestore.collection('users').doc(playerId);
        batch.update(playerDoc, {
          'totalScore': FieldValue.increment(1),
          'organizerPoints': FieldValue.increment(1),
          'lastEvaluatedAt': Timestamp.fromDate(now),
        });

        debugPrint('✅ +1 балл для игрока $playerId');
      }

      // Сохраняем все изменения в batch
      await batch.commit();

      // Отправляем уведомления оцененным игрокам
      for (final playerId in selectedPlayerIds) {
        try {
          final evaluatedPlayer = await userService.getUserById(playerId);
          if (evaluatedPlayer != null) {
            await gameNotificationService.notifyPlayerEvaluated(
              room: room,
              organizer: organizer,
              evaluatedPlayer: evaluatedPlayer,
              rating: 5.0, // Максимальная оценка за выбор организатором
              evaluatorName: organizer.name,
            );
            debugPrint('📨 Уведомление отправлено игроку ${evaluatedPlayer.name}');
          }
        } catch (e) {
          debugPrint('❌ Ошибка отправки уведомления игроку $playerId: $e');
          // Продолжаем выполнение, не прерывая процесс
        }
      }

      debugPrint('🎉 Все оценки сохранены и уведомления отправлены!');
      
    } catch (e) {
      debugPrint('❌ Ошибка сохранения оценок: $e');
      rethrow;
    }
  }

  /// Получить оценки для конкретной игры
  Future<List<PlayerEvaluationModel>> getGameEvaluations(String gameId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('gameId', isEqualTo: gameId)
          .get();

      return querySnapshot.docs
          .map((doc) => PlayerEvaluationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения оценок игры: $e');
      return [];
    }
  }

  /// Получить оценки для конкретного игрока
  Future<List<PlayerEvaluationModel>> getPlayerEvaluations(String playerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PlayerEvaluationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения оценок игрока: $e');
      return [];
    }
  }

  /// Проверить, оценил ли организатор уже эту игру
  Future<bool> hasOrganizerEvaluated({
    required String gameId,
    required String organizerId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('gameId', isEqualTo: gameId)
          .where('organizerId', isEqualTo: organizerId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Ошибка проверки оценки организатора: $e');
      return false;
    }
  }

  /// Получить статистику оценок игрока
  Future<Map<String, int>> getPlayerEvaluationStats(String playerId) async {
    try {
      final evaluations = await getPlayerEvaluations(playerId);
      
      final totalEvaluations = evaluations.length;
      final totalPoints = evaluations.fold<int>(0, (sum, eval) => sum + eval.points);
      
      return {
        'totalEvaluations': totalEvaluations,
        'totalPoints': totalPoints,
      };
    } catch (e) {
      debugPrint('❌ Ошибка получения статистики оценок: $e');
      return {
        'totalEvaluations': 0,
        'totalPoints': 0,
      };
    }
  }

  /// Получить топ игроков по оценкам
  Future<List<Map<String, dynamic>>> getTopRatedPlayers({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      // Группируем по игрокам и считаем общие баллы
      final Map<String, int> playerPoints = {};
      
      for (final doc in querySnapshot.docs) {
        final evaluation = PlayerEvaluationModel.fromMap(doc.data());
        playerPoints[evaluation.playerId] = 
            (playerPoints[evaluation.playerId] ?? 0) + evaluation.points;
      }

      // Сортируем и возвращаем топ
      final sortedPlayers = playerPoints.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedPlayers.take(limit).map((entry) => {
        'playerId': entry.key,
        'totalPoints': entry.value,
      }).toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения топ игроков: $e');
      return [];
    }
  }


} 