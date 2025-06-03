import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../teams/domain/entities/team_model.dart';
import '../../../teams/data/datasources/team_service.dart';
import '../../domain/entities/room_model.dart';

class RoomActionButtons extends StatelessWidget {
  final UserModel user;
  final RoomModel room;
  final TeamService teamService;
  final bool isJoining;
  final String roomId;
  final VoidCallback onSelectTeam;
  final Function(String teamId, UserModel user) onLeaveTeam;
  final Function(RoomStatus status) onUpdateRoomStatus;
  final VoidCallback onStartGameWithConfirmation;
  final VoidCallback onEndGameWithConfirmation;

  const RoomActionButtons({
    super.key,
    required this.user,
    required this.room,
    required this.teamService,
    required this.isJoining,
    required this.roomId,
    required this.onSelectTeam,
    required this.onLeaveTeam,
    required this.onUpdateRoomStatus,
    required this.onStartGameWithConfirmation,
    required this.onEndGameWithConfirmation,
  });

  @override
  Widget build(BuildContext context) {
    final isOrganizer = _isUserOrganizer(user, room);
    final now = DateTime.now();
    final hasStarted = room.startTime.isBefore(now);

    return Column(
      children: [
        // Кнопки для обычных пользователей
        if (!isOrganizer) ...[
          _buildUserButtons(context),
        ],

        // Кнопки для организатора
        if (isOrganizer) ...[
          _buildOrganizerButtons(context),
        ],

        // Кнопка "Назад" для всех пользователей
        const SizedBox(height: AppSizes.largeSpace),
        _buildBackButton(context),
      ],
    );
  }

  Widget _buildUserButtons(BuildContext context) {
    final now = DateTime.now();
    final hasStarted = room.startTime.isBefore(now);

    return FutureBuilder<TeamModel?>(
      future: teamService.getUserTeamInRoom(user.id, roomId),
      builder: (context, snapshot) {
        final userTeam = snapshot.data;
        final hasTeam = userTeam != null;

        if (hasTeam) {
          // Пользователь уже в команде - показываем кнопку выхода
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isJoining || room.status != RoomStatus.planned || hasStarted)
                  ? null
                  : () => onLeaveTeam(userTeam.id, user),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isJoining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Покинуть команду "${userTeam.name}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          );
        } else {
          // Пользователь не в команде - показываем кнопку выбора команды
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (room.status != RoomStatus.planned || hasStarted || isJoining)
                  ? null
                  : () => _handleSelectTeam(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isJoining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Выбрать команду',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          );
        }
      },
    );
  }

  Widget _buildOrganizerButtons(BuildContext context) {
    final now = DateTime.now();

    return Column(
      children: [
        // Кнопка начала игры
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: room.status == RoomStatus.planned
                ? onStartGameWithConfirmation
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _buildStartGameButtonText(now),
          ),
        ),
        const SizedBox(height: AppSizes.smallSpace),

        // Кнопка завершения игры
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: room.status == RoomStatus.active && room.canBeEndedManually
                ? onEndGameWithConfirmation
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              room.status == RoomStatus.active && !room.canBeEndedManually
                  ? 'Завершить игру (через ${room.startTime.add(const Duration(hours: 1)).difference(DateTime.now()).inMinutes} мин)'
                  : AppStrings.endGame,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.smallSpace),

        // Кнопка отмены игры
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: room.status == RoomStatus.planned
                ? () => onUpdateRoomStatus(RoomStatus.cancelled)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              AppStrings.cancelGame,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartGameButtonText(DateTime now) {
    if (isJoining) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final allowedStartTime = room.startTime.add(const Duration(minutes: 5));

    if (now.isBefore(allowedStartTime)) {
      final remainingMinutes = allowedStartTime.difference(now).inMinutes;
      final remainingSeconds = allowedStartTime.difference(now).inSeconds % 60;

      return Text(
        'Начать игру (через ${remainingMinutes}:${remainingSeconds.toString().padLeft(2, '0')})',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    return const Text(
      AppStrings.startGame,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text('Назад'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primary,
        ),
      ),
    );
  }

  void _handleSelectTeam(BuildContext context) {
    // Дополнительная проверка для командного режима
    if (room.isTeamMode && user.role == UserRole.user && !room.participants.contains(user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вы можете участвовать в командных играх только через организатора вашей команды'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    onSelectTeam();
  }

  bool _isUserOrganizer(UserModel user, RoomModel room) {
    return user.id == room.organizerId;
  }
} 