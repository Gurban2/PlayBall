import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../teams/data/datasources/team_service.dart';
import '../../../teams/domain/entities/team_model.dart';
import '../../domain/entities/room_model.dart';

class RoomInfoCard extends StatelessWidget {
  final RoomModel room;
  final TeamService teamService;

  const RoomInfoCard({
    super.key,
    required this.room,
    required this.teamService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.mediumSpace),
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и статус
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    room.title,
                    style: AppTextStyles.heading2,
                  ),
                ),
                _StatusBadge(status: room.effectiveStatus),
              ],
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            // Описание
            Text(
              room.description,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            // Информация о комнате
            _InfoRow(
              icon: Icons.location_on,
              label: AppStrings.location,
              value: room.location,
            ),
            _InfoRow(
              icon: Icons.access_time,
              label: AppStrings.startTime,
              value: _formatDateTime(room.startTime),
            ),
            _InfoRow(
              icon: Icons.access_time_filled,
              label: AppStrings.endTime,
              value: _formatDateTime(room.endTime),
            ),
            _InfoRow(
              icon: Icons.sports,
              label: 'Режим игры',
              value: _getGameModeDisplayName(room.gameMode),
            ),
            
            // Участники/команды
            if (room.isTeamMode)
              _TeamsInfoRow(room: room, teamService: teamService)
            else
              _InfoRow(
                icon: Icons.people,
                label: AppStrings.participants,
                value: '${room.participants.length}/${room.maxParticipants}',
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getGameModeDisplayName(GameMode gameMode) {
    switch (gameMode) {
      case GameMode.normal:
        return 'Обычный';
      case GameMode.team_friendly:
        return 'Командный';
      case GameMode.tournament:
        return 'Турнир';
    }
  }
}

// Виджет для отображения статуса
class _StatusBadge extends StatelessWidget {
  final RoomStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getStatusText(status),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.planned:
        return AppColors.warning;
      case RoomStatus.active:
        return AppColors.success;
      case RoomStatus.completed:
        return AppColors.secondary;
      case RoomStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getStatusText(RoomStatus status) {
    switch (status) {
      case RoomStatus.planned:
        return 'Запланировано';
      case RoomStatus.active:
        return 'Активно';
      case RoomStatus.completed:
        return 'Завершено';
      case RoomStatus.cancelled:
        return 'Отменено';
    }
  }
}

// Виджет для строки информации
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.smallSpace),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.smallIconSize, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.smallSpace),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Виджет для информации о командах
class _TeamsInfoRow extends StatelessWidget {
  final RoomModel room;
  final TeamService teamService;

  const _TeamsInfoRow({
    required this.room,
    required this.teamService,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.smallSpace),
      child: Row(
        children: [
          Icon(Icons.groups, size: AppSizes.smallIconSize, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.smallSpace),
          Text(
            '${AppStrings.participants}: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TeamModel>>(
              stream: teamService.watchTeamsForRoom(room.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final teams = snapshot.data ?? [];
                return Text(
                  '${teams.length}/${room.numberOfTeams} команд',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 