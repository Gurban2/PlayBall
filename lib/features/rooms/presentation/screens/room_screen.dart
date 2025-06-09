import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/game_time_utils.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../teams/domain/entities/team_model.dart';

import '../../../rooms/domain/entities/room_model.dart';

import '../../../../shared/widgets/cards/player_card.dart';
import '../../../../shared/widgets/dialogs/player_profile_dialog.dart';
import '../widgets/room_action_buttons.dart';
import '../../../../shared/widgets/dialogs/unified_dialogs.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  
  const RoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    // Запускаем автоматическую очистку при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoUpdateGameStatuses();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _autoUpdateGameStatuses() async {
    try {
      final roomService = ref.read(roomServiceProvider);
      
      // Автоматически запускаем запланированные игры
      await roomService.autoStartScheduledGames();
      
      // Автоматически завершаем активные игры
      await roomService.autoCompleteExpiredGames();
      
      // Отменяем просроченные запланированные игры
      await roomService.autoCancelExpiredPlannedGames();
      
      debugPrint('✅ Статусы игр обновлены автоматически в RoomScreen');
    } catch (e) {
      debugPrint('❌ Ошибка обновления статусов игр в RoomScreen: $e');
    }
  }

  Future<void> _selectTeam() async {
    final user = ref.read(currentUserProvider).value;
    final room = ref.read(roomProvider(widget.roomId)).value;
    
    // Проверяем авторизацию
    if (user == null) {
      ErrorHandler.showError(context, 'Необходимо войти в систему');
      return;
    }
    
    // Для командных игр и организаторов - вызываем специальную функцию
    if (room != null && room.isTeamMode && user.role == UserRole.organizer) {
      await _joinTeamGameAsOrganizer(user, room);
      return;
    }
    
    // Проверяем роль для командных игр
    if (room != null && room.isTeamMode && user.role == UserRole.user) {
      // Проверяем, является ли пользователь участником игры
      final isParticipant = room.participants.contains(user.id);
      
      if (!isParticipant) {
        ErrorHandler.permissionDenied(context);
        return;
      }
    }
    
    // Переходим к экрану выбора команды (для обычного режима)
    context.push('/team-selection/${widget.roomId}');
  }

  Future<void> _joinTeamGameAsOrganizer(UserModel user, RoomModel room) async {
    setState(() {
      _isJoining = true;
    });

    try {
      final roomService = ref.read(roomServiceProvider);
      await roomService.addOrganizerTeamToGame(
        roomId: room.id,
        organizerId: user.id,
      );
      
      if (mounted) {
        ErrorHandler.teamJoined(context, 'игру');
        
        // Обновляем провайдеры
        ref.invalidate(roomProvider(widget.roomId));
        ref.invalidate(teamsProvider(widget.roomId));
        ref.invalidate(currentUserProvider);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _leaveTeam(String teamId, UserModel user) async {
    final room = ref.read(roomProvider(widget.roomId)).value;
    if (room == null) return;

    // Получаем информацию о команде
    final teamService = ref.read(teamServiceProvider);
    final team = await teamService.getTeamById(teamId);
    if (team == null) return;

    // Проверяем, является ли пользователь организатором команды в командном режиме
    if (room.isTeamMode && team.ownerId == user.id) {
      // Показываем предупреждающий диалог
      final confirmed = await UnifiedDialogs.showLeaveTeamWarning(
        context: context,
        teamName: team.name,
        teamSize: team.members.length,
        isOwner: true,
      );

      if (confirmed != true) return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      await teamService.leaveTeam(teamId, user.id);
      
      if (mounted) {
        String message = 'Вы покинули команду';
        if (room.isTeamMode && team.ownerId == user.id) {
          message = 'Вся команда "${team.name}" покинула матч';
        }
        
        ErrorHandler.showWarning(context, message);
        
        // Принудительно обновляем все связанные провайдеры
        ref.invalidate(roomProvider(widget.roomId));
        ref.invalidate(teamsProvider(widget.roomId));
        ref.invalidate(currentUserProvider);
        ref.invalidate(userProvider(user.id));
        
        // Ждем немного для синхронизации Firebase
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ошибка выхода из команды: ${e.toString()}');
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
      final roomService = ref.read(roomServiceProvider);
      await roomService.updateRoom(roomId: widget.roomId, status: newStatus);
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Статус игры обновлен');
        // Обновляем провайдер
        ref.invalidate(roomProvider(widget.roomId));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ошибка обновления статуса: ${e.toString()}');
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
      default:
        return 'Неизвестно';
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
      default:
        return AppColors.textSecondary;
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
      appBar: AppBar(
        title: Text(
          'Детали игры',
          style: AppTextStyles.appBarTitle,
        ),
        backgroundColor: AppColors.darkGrey,
        foregroundColor: Colors.white,
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
              ref.invalidate(roomProvider(widget.roomId));
              // ignore: unused_result
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
                onPressed: () {
                  // ignore: unused_result
                  ref.refresh(roomProvider(widget.roomId));
                },
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
                        onPressed: () {
                          // ignore: unused_result
                          ref.refresh(currentUserProvider);
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
                data: (user) => Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/schedule/schedule_bg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(roomProvider(widget.roomId));
                      // ignore: unused_result
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
                        
                        // Выбор команды-победителя теперь доступен через отдельный экран по уведомлению
                        
                        // Кнопки действий
                        if (user != null) ...[
                          const SizedBox(height: AppSizes.mediumSpace),
                          RoomActionButtons(
                            user: user,
                            room: room,
                            teamService: ref.read(teamServiceProvider),
                            isJoining: _isJoining,
                            roomId: widget.roomId,
                            onSelectTeam: _selectTeam,
                            onLeaveTeam: _leaveTeam,
                            onUpdateRoomStatus: _updateRoomStatus,
                          ),
                        ],
                      ],
                    ),
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
                    style: AppTextStyles.heading1,
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
            const SizedBox(height: AppSizes.smallSpace),
            
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
            _buildInfoRow(Icons.sports, 'Режим игры', _getGameModeDisplayName(room.gameMode)),
            // Отображение участников/команд в зависимости от режима
            if (room.isTeamMode)
              _buildTeamsInfoRow(room)
            else
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
              stream: ref.read(teamServiceProvider).watchTeamsForRoom(widget.roomId),
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
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: InkWell(
          onTap: () => _showTeamPlayersDialog(team),
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          child: Container(
            padding: AppSizes.cardPadding,
            decoration: BoxDecoration(
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.smallSpace),
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
          ),
        ),
      ),
    );
  }

  void _showTeamPlayersDialog(TeamModel team) async {
    final user = ref.read(currentUserProvider).value;
    
    // Проверяем, авторизован ли пользователь
    if (user == null) {
      ErrorHandler.showWarning(context, 'Войдите в систему для просмотра игроков');
      return;
    }

    // Загружаем данные игроков
    final userService = ref.read(userServiceProvider);
    final players = <UserModel?>[];
    
    for (final playerId in team.members) {
      try {
        final player = await userService.getUserById(playerId);
        players.add(player);
      } catch (e) {
        debugPrint('Ошибка загрузки игрока $playerId: $e');
        players.add(null);
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Команда "${team.name}"'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              if (player == null) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.error, color: AppColors.error),
                    title: Text('Ошибка загрузки игрока'),
                  ),
                );
              }
              
              return PlayerCard(
                player: player,
                compact: true,
                // Убираем переопределение onTap, используем стандартное поведение
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }



  Widget _buildUpcomingGameItem(GameRef game) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(); // Закрываем текущий диалог
          context.push('${AppRoutes.room}/${game.id}');
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${game.location} • ${game.date.day}.${game.date.month}.${game.date.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '';
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Игрок';
      case UserRole.organizer:
        return 'Организатор';
      case UserRole.admin:
        return 'Администратор';
    }
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
            future: ref.read(teamServiceProvider).getUserTeamInRoom(user.id, widget.roomId),
            builder: (context, snapshot) {
              final userTeam = snapshot.data;
              final hasTeam = userTeam != null;
              
              if (hasTeam) {
                // Пользователь уже в команде - показываем кнопку выхода
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Используем новую утилиту для проверки
                      if (!GameTimeUtils.canLeaveGame(room)) return null;
                      
                      if (_isJoining) return null;
                      
                      return () => _leaveTeam(userTeam.id, user);
                    }(),
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
                        : Builder(
                            builder: (context) {
                              // Используем новую утилиту
                              if (!GameTimeUtils.canLeaveGame(room)) {
                                final now = DateTime.now();
                                final remainingMinutes = room.startTime.difference(now).inMinutes;
                                if (remainingMinutes > 0) {
                                  return Text(
                                    'Выход заблокирован (${remainingMinutes} мин до игры)',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                } else {
                                  return const Text(
                                    'Игра уже началась',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                              }
                              
                              // Проверяем, является ли пользователь организатором команды в командном режиме
                              if (room.isTeamMode && userTeam.ownerId == user.id) {
                                return Text(
                                  'Покинуть матч (вся команда "${userTeam.name}")',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              } else {
                                return Text(
                                  'Покинуть команду "${userTeam.name}"',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              }
                            },
                          ),
                  ),
                );
              } else {
                // Пользователь не в команде - показываем кнопку выбора команды
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Используем новую утилиту для проверки
                      if (!GameTimeUtils.canJoinGame(room)) return null;
                      
                      // Дополнительная проверка для командного режима
                      if (room.isTeamMode && user.role == UserRole.user && !room.participants.contains(user.id)) {
                        return null; // Кнопка неактивна для обычных пользователей в командном режиме
                      }
                      
                      return () {
                        // Дополнительная проверка для командного режима с уведомлением
                        if (room.isTeamMode && user.role == UserRole.user && !room.participants.contains(user.id)) {
                          ErrorHandler.showWarning(context, 'Вы можете участвовать в командных играх только через организатора вашей команды');
                          return;
                        }
                        _selectTeam();
                      };
                    }(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
                        : Builder(
                            builder: (context) {
                              // Используем новую утилиту
                              if (!GameTimeUtils.canJoinGame(room)) {
                                if (room.status != RoomStatus.planned) {
                                  return const Text(
                                    'Игра уже активна',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                                
                                final now = DateTime.now();
                                final remainingMinutes = room.startTime.difference(now).inMinutes;
                                if (remainingMinutes > 0) {
                                  return Text(
                                    'Присоединение заблокировано (${remainingMinutes} мин до игры)',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                } else {
                                  return const Text(
                                    'Игра уже началась',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                              }
                              
                              // Проверяем командный режим
                              if (room.isTeamMode) {
                                if (user.role == UserRole.organizer) {
                                  return const Text(
                                    'Присоединиться моей командой',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                } else {
                                  return const Text(
                                    'Только через организатора команды',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                }
                              }
                              
                              return const Text(
                                'Выбрать команду',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                  ),
                );
              }
            },
          ),
        ],
        
                                // Кнопки для организатора
                        if (isOrganizer) ...[
                          // Кнопка отмены игры - только для запланированных игр
                          if (room.status == RoomStatus.planned) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: GameTimeUtils.canCancelGame(room)
                                    ? () => _updateRoomStatus(RoomStatus.cancelled)
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
                        
                        // Кнопка "Назад" для всех пользователей
                        const SizedBox(height: AppSizes.largeSpace),
                        Row(
                          children: [
                            Expanded(
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => context.go(AppRoutes.home),
                                icon: const Icon(Icons.home),
                                label: const Text('На главную'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
      ],
    );
  }

  Future<void> _handleFriendAction(UserModel currentUser, UserModel player, bool isFriend) async {
    try {
      final userService = ref.read(userServiceProvider);
      
      if (isFriend) {
        // Удаляем из друзей
        await userService.removeFriend(currentUser.id, player.id);
        if (mounted) {
          Navigator.of(context).pop(); // Закрываем диалог
          ErrorHandler.friendRemoved(context, player.name);
        }
      } else {
        // Добавляем в друзья
        await userService.addFriend(currentUser.id, player.id);
        if (mounted) {
          Navigator.of(context).pop(); // Закрываем диалог
          ErrorHandler.friendAdded(context, player.name);
        }
      }
      
      // Обновляем провайдер пользователя для обновления списка друзей
      // ignore: unused_result
      ref.refresh(currentUserProvider);
      
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  String _getGameModeDisplayName(GameMode gameMode) {
    switch (gameMode) {
      case GameMode.normal:
        return 'Обычный';
      case GameMode.team_friendly:
        return 'Командный';
      case GameMode.tournament:
        return 'Турнир';
      default:
        return 'Неизвестно';
    }
  }

  Widget _buildTeamsInfoRow(RoomModel room) {
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
              stream: ref.read(teamServiceProvider).watchTeamsForRoom(room.id),
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