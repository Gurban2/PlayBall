import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  
  const RoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  bool _isJoining = false;

  Future<void> _selectTeam() async {
    // Переходим к экрану выбора команды
    context.push('/team-selection/${widget.roomId}');
  }

  Future<void> _leaveTeam(String teamId, UserModel user) async {
    setState(() {
      _isJoining = true;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.leaveTeam(teamId, user.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы покинули команду'),
            backgroundColor: AppColors.warning,
          ),
        );
        // Обновляем провайдер
        ref.refresh(roomProvider(widget.roomId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выхода из команды: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _updateRoomStatus(RoomStatus newStatus) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateRoom(roomId: widget.roomId, status: newStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Статус игры обновлен'),
            backgroundColor: AppColors.success,
          ),
        );
        // Обновляем провайдер
        ref.refresh(roomProvider(widget.roomId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления статуса: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getStatusText(RoomStatus status) {
    switch (status) {
      case RoomStatus.planned:
        return AppStrings.planned;
      case RoomStatus.active:
        return AppStrings.active;
      case RoomStatus.completed:
        return AppStrings.completed;
      case RoomStatus.cancelled:
        return AppStrings.cancelled;
    }
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.planned:
        return AppColors.secondary;
      case RoomStatus.active:
        return AppColors.primary;
      case RoomStatus.completed:
        return AppColors.success;
      case RoomStatus.cancelled:
        return AppColors.error;
    }
  }

  bool _isUserParticipant(UserModel? user, RoomModel? room) {
    return user != null && room != null && room.participants.contains(user.id);
  }

  bool _isUserOrganizer(UserModel? user, RoomModel? room) {
    return user != null && room != null && room.organizerId == user.id;
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Детали игры'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(roomProvider(widget.roomId));
              ref.refresh(currentUserProvider);
            },
          ),
        ],
      ),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Ошибка загрузки комнаты: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(roomProvider(widget.roomId)),
                child: const Text('Повторить'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
        data: (room) => room == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    const Text('Комната не найдена'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.home);
                        }
                      },
                      child: const Text('Назад'),
                    ),
                  ],
                ),
              )
            : userAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('Ошибка загрузки пользователя: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(currentUserProvider),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
                data: (user) => RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(roomProvider(widget.roomId));
                    ref.refresh(currentUserProvider);
                  },
                  child: SingleChildScrollView(
                    padding: AppSizes.screenPadding,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Информация о комнате
                        _buildInfoCard(room),
                        
                        // Команды
                        _buildTeamsCard(room),
                        
                        // Кнопки действий
                        if (user != null) ...[
                          const SizedBox(height: AppSizes.mediumSpace),
                          _buildActionButtons(user, room),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(RoomModel room) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.mediumSpace),
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    room.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(room.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(room.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            Text(
              room.description,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            _buildInfoRow(Icons.location_on, AppStrings.location, room.location),
            _buildInfoRow(Icons.access_time, AppStrings.startTime, 
              '${room.startTime.day}.${room.startTime.month}.${room.startTime.year} '
              '${room.startTime.hour.toString().padLeft(2, '0')}:'
              '${room.startTime.minute.toString().padLeft(2, '0')}'),
            _buildInfoRow(Icons.access_time_filled, AppStrings.endTime, 
              '${room.endTime.day}.${room.endTime.month}.${room.endTime.year} '
              '${room.endTime.hour.toString().padLeft(2, '0')}:'
              '${room.endTime.minute.toString().padLeft(2, '0')}'),
            _buildInfoRow(Icons.people, AppStrings.participants, 
              '${room.participants.length}/${room.maxParticipants}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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

  Widget _buildTeamsCard(RoomModel room) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.mediumSpace),
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Команды (${room.participants.length} участников)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            StreamBuilder<List<TeamModel>>(
              stream: ref.read(firestoreServiceProvider).getTeamsForRoomStream(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Text(
                    'Ошибка загрузки команд: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.error),
                  );
                }
                
                final teams = snapshot.data ?? [];
                
                if (teams.isEmpty) {
                  return const Text(
                    'Команды не созданы',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }
                
                return Column(
                  children: teams.map((team) => _buildTeamItem(team)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamItem(TeamModel team) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.smallSpace),
      padding: AppSizes.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(
            Icons.groups,
            color: team.isFull ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: AppSizes.mediumSpace),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${team.members.length}/${team.maxMembers} игроков',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: team.isFull ? AppColors.error : AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              team.isFull ? 'Заполнена' : 'Свободна',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<UserModel?>> _loadParticipants(List<String> participantIds) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final participants = <UserModel?>[];
    
    for (final participantId in participantIds) {
      try {
        final user = await firestoreService.getUserById(participantId);
        participants.add(user);
      } catch (e) {
        debugPrint('Ошибка загрузки участника $participantId: $e');
        participants.add(null);
      }
    }
    
    return participants;
  }

  Widget _buildActionButtons(UserModel user, RoomModel room) {
    final isParticipant = _isUserParticipant(user, room);
    final isOrganizer = _isUserOrganizer(user, room);
    final now = DateTime.now();
    final hasStarted = room.startTime.isBefore(now);
    
    return Column(
      children: [
        // Кнопки для обычных пользователей
        if (!isOrganizer) ...[
          // Проверяем, в какой команде пользователь
          FutureBuilder<TeamModel?>(
            future: ref.read(firestoreServiceProvider).getUserTeamInRoom(user.id, widget.roomId),
            builder: (context, snapshot) {
              final userTeam = snapshot.data;
              final hasTeam = userTeam != null;
              
              if (hasTeam) {
                // Пользователь уже в команде - показываем кнопку выхода
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isJoining || room.status != RoomStatus.planned || hasStarted) 
                        ? null 
                        : () => _leaveTeam(userTeam.id, user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isJoining
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
                    onPressed: (room.status != RoomStatus.planned || hasStarted) 
                        ? null 
                        : _selectTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      room.status != RoomStatus.planned 
                          ? 'Игра уже началась'
                          : hasStarted
                              ? 'Игра уже началась'
                              : 'Выбрать команду',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
        
                                // Кнопки для организатора
                        if (isOrganizer) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: room.status == RoomStatus.planned 
                                  ? () => _updateRoomStatus(RoomStatus.active)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                AppStrings.startGame,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.smallSpace),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: room.status == RoomStatus.active 
                                  ? () => _updateRoomStatus(RoomStatus.completed)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                AppStrings.endGame,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.smallSpace),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: room.status == RoomStatus.planned 
                                  ? () => _updateRoomStatus(RoomStatus.cancelled)
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
                        
                        // Кнопка "Назад" для всех пользователей
                        const SizedBox(height: AppSizes.largeSpace),
                        SizedBox(
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
                        ),
      ],
    );
  }
} 