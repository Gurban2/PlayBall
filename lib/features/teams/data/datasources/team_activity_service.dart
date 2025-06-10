import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../notifications/data/datasources/game_notification_service.dart';
import '../../../teams/domain/entities/team_activity_check_model.dart';
import 'team_service.dart';

/// Сервис для управления проверками активности команды
class TeamActivityService {
  final TeamService _teamService;
  final GameNotificationService _notificationService;

  TeamActivityService(this._teamService, this._notificationService);

  /// Запустить проверку активности для команды
  Future<String> startActivityCheck({
    required String teamId,
    required UserModel organizer,
  }) async {
    try {
      debugPrint('🚀 Запуск проверки активности для команды $teamId организатором ${organizer.name}');

      // Получаем данные команды
      final team = await _teamService.getUserTeamById(teamId);
      if (team == null) {
        throw Exception('Команда не найдена');
      }

      // Проверяем, что пользователь является организатором команды
      if (team.ownerId != organizer.id) {
        throw Exception('Только организатор команды может запустить проверку активности');
      }

      // Проверяем, что в команде есть игроки кроме организатора
      final teamMembers = team.members.where((id) => id != organizer.id).toList();
      if (teamMembers.isEmpty) {
        throw Exception('В команде нет игроков для проверки активности');
      }

      // Создаем проверку активности
      final checkId = await _teamService.createActivityCheck(
        teamId: teamId,
        organizerId: organizer.id,
        organizerName: organizer.name,
        teamMembers: team.members,
      );

      // Отправляем уведомления ТОЛЬКО игрокам команды (не организатору)
      await _notificationService.notifyActivityCheck(
        teamId: teamId,
        teamName: team.name,
        teamMembers: teamMembers, // Только игроки, без организатора
      );

      debugPrint('✅ Проверка активности $checkId успешно запущена для команды "${team.name}"');
      return checkId;
    } catch (e) {
      debugPrint('❌ Ошибка запуска проверки активности: $e');
      rethrow;
    }
  }

  /// Игрок подтверждает готовность
  Future<void> confirmReadiness({
    required String checkId,
    required String playerId,
  }) async {
    try {
      debugPrint('✋ Игрок $playerId подтверждает готовность в проверке $checkId');

      await _teamService.confirmPlayerReadiness(checkId, playerId);

      debugPrint('✅ Готовность игрока $playerId подтверждена');
    } catch (e) {
      debugPrint('❌ Ошибка подтверждения готовности: $e');
      rethrow;
    }
  }

  /// Игрок отклоняет готовность
  Future<void> declineReadiness({
    required String checkId,
    required String playerId,
  }) async {
    try {
      debugPrint('❌ Игрок $playerId отклоняет готовность в проверке $checkId');

      await _teamService.declinePlayerReadiness(checkId, playerId);

      debugPrint('✅ Отклонение готовности игрока $playerId зафиксировано');
    } catch (e) {
      debugPrint('❌ Ошибка отклонения готовности: $e');
      rethrow;
    }
  }

  /// Получить активную проверку активности для команды
  Future<TeamActivityCheckModel?> getActiveCheck(String teamId) async {
    try {
      return await _teamService.getActiveActivityCheck(teamId);
    } catch (e) {
      debugPrint('❌ Ошибка получения активной проверки: $e');
      return null;
    }
  }

  /// Получить проверку активности по ID
  Future<TeamActivityCheckModel?> getCheckById(String checkId) async {
    try {
      return await _teamService.getActivityCheckById(checkId);
    } catch (e) {
      debugPrint('❌ Ошибка получения проверки активности: $e');
      return null;
    }
  }

  /// Получить проверки активности для игрока
  Future<List<TeamActivityCheckModel>> getPlayerChecks(String playerId) async {
    try {
      return await _teamService.getPlayerActivityChecks(playerId);
    } catch (e) {
      debugPrint('❌ Ошибка получения проверок для игрока: $e');
      return [];
    }
  }

  /// Stream для отслеживания проверок активности игрока
  Stream<List<TeamActivityCheckModel>> watchPlayerChecks(String playerId) {
    return _teamService.watchPlayerActivityChecks(playerId);
  }

  /// Stream для отслеживания конкретной проверки активности
  Stream<TeamActivityCheckModel?> watchCheck(String checkId) {
    return _teamService.watchActivityCheck(checkId);
  }

  /// Отменить проверку активности (только организатор)
  Future<void> cancelCheck({
    required String checkId,
    required String organizerId,
  }) async {
    try {
      debugPrint('🚫 Отмена проверки активности $checkId организатором $organizerId');

      await _teamService.cancelActivityCheck(checkId, organizerId);

      debugPrint('✅ Проверка активности $checkId отменена');
    } catch (e) {
      debugPrint('❌ Ошибка отмены проверки активности: $e');
      rethrow;
    }
  }

  /// Проверить все ли игроки команды готовы
  Future<bool> areAllPlayersReady(String checkId) async {
    try {
      final check = await getCheckById(checkId);
      return check?.areAllPlayersReady ?? false;
    } catch (e) {
      debugPrint('❌ Ошибка проверки готовности всех игроков: $e');
      return false;
    }
  }

  /// Получить статистику готовности команды
  Future<Map<String, dynamic>> getReadinessStats(String checkId) async {
    try {
      final check = await getCheckById(checkId);
      if (check == null) {
        return {
          'total': 0,
          'ready': 0,
          'notResponded': 0,
          'percentage': 0.0,
          'allReady': false,
          'isExpired': true,
        };
      }

      return {
        'total': check.teamMembers.length,
        'ready': check.readyPlayers.length,
        'notResponded': check.notRespondedCount,
        'percentage': check.readinessPercentage,
        'allReady': check.areAllPlayersReady,
        'isExpired': check.isExpired,
        'timeLeft': check.isExpired ? 0 : check.expiresAt.difference(DateTime.now()).inMinutes,
      };
    } catch (e) {
      debugPrint('❌ Ошибка получения статистики готовности: $e');
      return {
        'total': 0,
        'ready': 0,
        'notResponded': 0,
        'percentage': 0.0,
        'allReady': false,
        'isExpired': true,
      };
    }
  }

  /// Очистить старые проверки активности
  Future<void> cleanupOldChecks() async {
    try {
      await _teamService.cleanupOldActivityChecks();
    } catch (e) {
      debugPrint('❌ Ошибка очистки старых проверок: $e');
    }
  }
} 