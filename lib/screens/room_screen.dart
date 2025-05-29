import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../widgets/confirmation_dialog.dart';

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

  // Новый метод для начала игры с проверками
  Future<void> _startGameWithConfirmation() async {
    final roomAsync = ref.read(roomProvider(widget.roomId));
    final room = roomAsync.value;
    
    if (room == null) return;
    
    final now = DateTime.now();
    final isEarly = now.isBefore(room.startTime);
    
    // Если игра начинается раньше времени, показываем подтверждение
    if (isEarly) {
      final confirmed = await ConfirmationDialog.showStartEarly(context);
      if (confirmed != true) return;
      
      // Проверяем конфликты локации
      final firestoreService = ref.read(firestoreServiceProvider);
      final hasConflict = await firestoreService.checkLocationConflict(
        location: room.location,
        startTime: now,
        endTime: room.endTime,
        excludeRoomId: room.id,
      );
      
      if (hasConflict) {
        // Получаем информацию о конфликтующей игре
        final conflictingRoom = await firestoreService.getConflictingRoom(
          location: room.location,
          startTime: now,
          endTime: room.endTime,
          excludeRoomId: room.id,
        );
        
        if (mounted) {
          ConfirmationDialog.showLocationConflict(
            context,
            plannedStartTime: room.startTime,
            conflictingRoom: conflictingRoom,
          );
        }
        return; // Не начинаем игру
      }
    }
    
    // Если все проверки пройдены, начинаем игру
    await _updateRoomStatus(RoomStatus.active);
  }

  // Новый метод для завершения игры с подтверждением
  Future<void> _endGameWithConfirmation() async {
    final roomAsync = ref.read(roomProvider(widget.roomId));
    final room = roomAsync.value;
    
    if (room == null) return;
    
    final now = DateTime.now();
    final isEarly = now.isBefore(room.endTime);
    
    // Если игра завершается раньше времени, показываем подтверждение
    if (isEarly) {
      final confirmed = await ConfirmationDialog.showEndEarly(context);
      if (confirmed != true) return;
    }
    
    // Завершаем игру
    await _updateRoomStatus(RoomStatus.completed);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Войдите в систему для просмотра игроков'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Загружаем данные игроков
    final firestoreService = ref.read(firestoreServiceProvider);
    final players = <UserModel?>[];
    
    for (final playerId in team.members) {
      try {
        final player = await firestoreService.getUserById(playerId);
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
                return const ListTile(
                  leading: Icon(Icons.error, color: AppColors.error),
                  title: Text('Ошибка загрузки игрока'),
                );
              }
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: player.photoUrl != null 
                      ? NetworkImage(player.photoUrl!) 
                      : null,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: player.photoUrl == null 
                      ? Text(
                          _getInitials(player.name),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(player.name),
                subtitle: Text(
                  '${_getRoleDisplayName(player.role)} • Рейтинг: ${player.rating}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).pop();
                  _showPlayerProfile(player);
                },
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

  void _showPlayerProfile(UserModel player) async {
    final currentUser = ref.read(currentUserProvider).value;
    final canViewEmail = currentUser?.role == UserRole.organizer || currentUser?.role == UserRole.admin;
    
    // Загружаем предстоящие игры игрока
    final firestoreService = ref.read(firestoreServiceProvider);
    final upcomingGames = await firestoreService.getUpcomingGamesForUser(player.id);
    
    // Проверяем статус дружбы
    bool isFriend = false;
    bool isOwnProfile = false;
    if (currentUser != null) {
      if (currentUser.id == player.id) {
        isOwnProfile = true;
      } else {
        isFriend = await firestoreService.isFriend(currentUser.id, player.id);
      }
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(player.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Аватар
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: player.photoUrl != null 
                      ? NetworkImage(player.photoUrl!) 
                      : null,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: player.photoUrl == null 
                      ? Text(
                          _getInitials(player.name),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              
              // Основная информация
              if (canViewEmail) _buildProfileRow('Email', player.email),
              _buildProfileRow('Роль', _getRoleDisplayName(player.role)),
              _buildProfileRow('Рейтинг', player.rating.toString()),
              _buildProfileRow('Всего очков', player.totalScore.toString()),
              _buildProfileRow('Игр сыграно', player.gamesPlayed.toString()),
              _buildProfileRow('Процент побед', '${player.winRate.toStringAsFixed(1)}%'),
              
              if (player.bio.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'О себе:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(player.bio),
              ],
              
              // Предстоящие игры
              if (upcomingGames.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Предстоящие игры:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...upcomingGames.take(3).map((game) => _buildUpcomingGameItem(game)),
              ],
            ],
          ),
        ),
        actions: [
          // Кнопка добавления в друзья (только если это не свой профиль)
          if (!isOwnProfile && currentUser != null) ...[
            TextButton.icon(
              onPressed: () => _handleFriendAction(currentUser!, player, isFriend),
              icon: Icon(
                isFriend ? Icons.person_remove : Icons.person_add,
                size: 18,
              ),
              label: Text(isFriend ? 'Удалить из друзей' : 'Добавить в друзья'),
              style: TextButton.styleFrom(
                foregroundColor: isFriend ? AppColors.error : AppColors.primary,
              ),
            ),
          ],
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
                                  ? () => _startGameWithConfirmation()
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
                                  ? () => _endGameWithConfirmation()
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

  Future<void> _handleFriendAction(UserModel currentUser, UserModel player, bool isFriend) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      if (isFriend) {
        // Удаляем из друзей
        await firestoreService.removeFriend(currentUser.id, player.id);
        if (mounted) {
          Navigator.of(context).pop(); // Закрываем диалог
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${player.name} удален из друзей'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } else {
        // Добавляем в друзья
        await firestoreService.addFriend(currentUser.id, player.id);
        if (mounted) {
          Navigator.of(context).pop(); // Закрываем диалог
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${player.name} добавлен в друзья'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
      
      // Обновляем провайдер пользователя для обновления списка друзей
      ref.refresh(currentUserProvider);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
} 