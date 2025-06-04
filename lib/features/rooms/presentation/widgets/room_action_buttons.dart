import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/game_time_utils.dart';
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
              onPressed: GameTimeUtils.canLeaveGame(room) && !isJoining
                  ? () => onLeaveTeam(userTeam.id, user)
                  : null,
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
              onPressed: GameTimeUtils.canJoinGame(room) && !isJoining
                  ? () => _handleSelectTeam(context)
                  : null,
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
    return Column(
      children: [
        // Кнопка отмены игры - только для запланированных игр
        if (room.status == RoomStatus.planned) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: GameTimeUtils.canCancelGame(room)
                  ? () => onUpdateRoomStatus(RoomStatus.cancelled)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                GameTimeUtils.canCancelGame(room)
                    ? AppStrings.cancelGame
                    : 'Отмена заблокирована (все команды заполнены)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
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