import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../domain/entities/user_team_model.dart';
import '../../domain/entities/team_model.dart';
import '../widgets/team_winner_selector_widget.dart';

class WinnerSelectionScreen extends ConsumerStatefulWidget {
  final String roomId;

  const WinnerSelectionScreen({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<WinnerSelectionScreen> createState() => _WinnerSelectionScreenState();
}

class _WinnerSelectionScreenState extends ConsumerState<WinnerSelectionScreen> {
  String? selectedTeamId;
  Set<String> selectedPlayers = {};
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Выбор команды-победителя'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки игры',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (room) {
          if (room == null) {
            return const Center(
              child: Text(
                'Игра не найдена',
                style: AppTextStyles.heading2,
              ),
            );
          }

          if (currentUser == null) {
            return const Center(
              child: Text(
                'Необходима авторизация',
                style: AppTextStyles.heading2,
              ),
            );
          }

          // Проверяем права доступа
          if (currentUser.id != room.organizerId) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Доступ запрещен',
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Только организатор может выбирать победителей',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (room.status != RoomStatus.completed) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: AppColors.warning),
                  const SizedBox(height: 16),
                  Text(
                    'Игра еще не завершена',
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Выбор победителей доступен только после завершения игры',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (room.isTeamMode) {
            // Командный режим - используем существующий виджет
            return _buildTeamModeSelection(room, currentUser);
          } else {
            // Обычный режим - выбор команды-победителя и 4 лучших игроков
            return _buildNormalModeSelection(room, currentUser);
          }
        },
      ),
    );
  }

  Widget _buildTeamModeSelection(RoomModel room, UserModel organizer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(room),
          const SizedBox(height: 16),
          StreamBuilder<List<TeamModel>>(
            stream: ref.read(teamServiceProvider).watchTeamsForRoom(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Ошибка загрузки команд: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                );
              }
              
              final teams = snapshot.data ?? [];
              
              // Конвертируем TeamModel в UserTeamModel для совместимости
              final participatingTeams = teams
                  .where((team) => team.members.isNotEmpty)
                  .map((team) => UserTeamModel(
                    id: team.id,
                    name: team.name,
                    ownerId: team.ownerId ?? '',
                    members: team.members,
                    maxMembers: team.maxMembers,
                    photoUrl: null,
                    createdAt: DateTime.now(),
                  ))
                  .toList();
              
              return TeamWinnerSelectorWidget(
                room: room,
                organizer: organizer,
                participatingTeams: participatingTeams,
                onWinnerSelected: () {
                  // Показываем уведомление и возвращаемся
                  ErrorHandler.showSuccess(context, '✅ Команда-победитель выбрана!');
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNormalModeSelection(RoomModel room, UserModel organizer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(room),
          const SizedBox(height: 16),
          _buildNormalModeWinnerSelector(room, organizer),
        ],
      ),
    );
  }

  Widget _buildInfoCard(RoomModel room) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.title,
                        style: AppTextStyles.heading2,
                      ),
                      Text(
                        'Игра завершена • ${room.isTeamMode ? "Командный режим" : "Обычный режим"}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  room.location,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${room.participants.length} игроков',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalModeWinnerSelector(RoomModel room, UserModel organizer) {
    // Для обычного режима создаем временные команды из игроков
    final participants = room.finalParticipants ?? room.participants;
    
    // Создаем две команды
    final halfSize = (participants.length / 2).ceil();
    final team1Players = participants.take(halfSize).toList();
    final team2Players = participants.skip(halfSize).toList();
    
    final teams = [
      if (team1Players.isNotEmpty)
        UserTeamModel(
          id: 'team_1',
          name: 'Команда 1',
          ownerId: organizer.id,
          members: team1Players,
          maxMembers: team1Players.length,
          photoUrl: null,
          createdAt: DateTime.now(),
        ),
      if (team2Players.isNotEmpty)
        UserTeamModel(
          id: 'team_2',
          name: 'Команда 2',
          ownerId: organizer.id,
          members: team2Players,
          maxMembers: team2Players.length,
          photoUrl: null,
          createdAt: DateTime.now(),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.warning),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'В обычном режиме игроки автоматически разделены на две команды. Выберите команду-победителя.',
                  style: TextStyle(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Используем существующий виджет для выбора команды
        TeamWinnerSelectorWidget(
          room: room,
          organizer: organizer,
          participatingTeams: teams,
          onWinnerSelected: () {
            ErrorHandler.showSuccess(context, '✅ Команда-победитель выбрана!');
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
} 