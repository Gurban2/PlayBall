import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../../teams/domain/entities/team_model.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/game_time_utils.dart';
import '../../../../shared/widgets/dialogs/player_profile_dialog.dart';
import '../../../../shared/widgets/cards/team_member_card.dart';

class TeamSelectionScreen extends ConsumerStatefulWidget {
  final String roomId;
  
  const TeamSelectionScreen({super.key, required this.roomId});

  @override
  ConsumerState<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends ConsumerState<TeamSelectionScreen> {
  bool _isJoining = false;

  Future<void> _joinTeam(String teamId, UserModel user) async {
    setState(() {
      _isJoining = true;
    });

    try {
      final teamService = ref.read(teamServiceProvider);
      await teamService.joinTeam(teamId, user.id);
      
      if (mounted) {
        ErrorHandler.teamJoined(context, 'команде');
        // Возвращаемся к экрану комнаты
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ошибка присоединения: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<List<UserModel?>> _loadTeamMembers(List<String> memberIds) async {
    final userService = ref.read(userServiceProvider);
    final members = <UserModel?>[];
    
    for (final memberId in memberIds) {
      try {
        final user = await userService.getUserById(memberId);
        members.add(user);
      } catch (e) {
        debugPrint('Ошибка загрузки участника $memberId: $e');
        members.add(null);
      }
    }
    
    return members;
  }

  void _showPlayerProfile(UserModel player) {
    PlayerProfileDialog.show(
      context,
      ref,
      player.id,
      playerName: player.name,
    );
  }

  Future<void> _handleFriendAction(UserModel player, String friendshipStatus) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final userService = ref.read(userServiceProvider);

      switch (friendshipStatus) {
        case 'friends':
          await userService.removeFriend(currentUser.id, player.id);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${player.name} удален из друзей'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          break;

        case 'none':
          await userService.sendFriendRequest(currentUser.id, player.id);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Запрос дружбы отправлен ${player.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          break;

        case 'request_sent':
          await userService.cancelFriendRequest(currentUser.id, player.id);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Запрос дружбы ${player.name} отменен'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          break;

        case 'request_received':
          _showFriendRequestDialog(player);
          break;
      }
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

  void _showFriendRequestDialog(UserModel player) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Запрос дружбы от ${player.name}'),
        content: Text('${player.name} хочет добавить вас в друзья'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отклонить'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Принять'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final userService = ref.read(userServiceProvider);
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser == null) return;
        
        final requests = await userService.getIncomingFriendRequests(currentUser.id);
        final request = requests.firstWhere(
          (r) => r.fromUserId == player.id,
          orElse: () => throw Exception('Запрос не найден'),
        );

        if (result) {
          await userService.acceptFriendRequest(request.id);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${player.name} добавлен в друзья'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          await userService.declineFriendRequest(request.id);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Запрос дружбы ${player.name} отклонен'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
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

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
    return '?';
  }

  Widget _buildTeamCard(TeamModel team, UserModel user, RoomModel room) {
    // В командном режиме проверяем логику доступа
    if (room.isTeamMode && user.role == UserRole.user) {
      // Проверяем, является ли пользователь участником игры
      final isParticipant = room.participants.contains(user.id);
      final isInThisTeam = team.members.contains(user.id);
      
      if (!isParticipant) {
        // Обычные игроки, которые НЕ участники игры
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
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${team.members.length}/${team.maxMembers}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.mediumSpace),
                
                if (team.members.isEmpty)
                  const Text(
                    'Нет участников',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  FutureBuilder<List<UserModel?>>(
                    future: _loadTeamMembers(team.members),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final members = snapshot.data ?? [];
                      
                      return Column(
                        children: members.map((member) {
                          if (member == null) {
                            return const ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text('Пользователь не найден'),
                            );
                          }
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
                                child: member.photoUrl == null 
                                    ? Text(_getInitials(member.name), style: const TextStyle(color: AppColors.primary))
                                    : null,
                              ),
                              title: Text(member.name),
                              subtitle: Text('${member.gamesPlayed} игр'),
                              onTap: () => _showPlayerProfile(member),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                
                const SizedBox(height: AppSizes.mediumSpace),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null, // Всегда неактивна
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Обратитесь к организатору своей команды',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Обычные игроки, которые ЯВЛЯЮТСЯ участниками игры
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
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isInThisTeam ? AppColors.success : AppColors.secondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${team.members.length}/${team.maxMembers}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.mediumSpace),
                
                if (team.members.isEmpty)
                  const Text(
                    'Нет участников',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  FutureBuilder<List<UserModel?>>(
                    future: _loadTeamMembers(team.members),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final members = snapshot.data ?? [];
                      
                      return Column(
                        children: members.map((member) {
                          if (member == null) {
                            return const ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text('Пользователь не найден'),
                            );
                          }
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
                                child: member.photoUrl == null 
                                    ? Text(_getInitials(member.name), style: const TextStyle(color: AppColors.primary))
                                    : null,
                              ),
                              title: Text(member.name),
                              subtitle: Text('${member.gamesPlayed} игр'),
                              onTap: () => _showPlayerProfile(member),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                
                const SizedBox(height: AppSizes.mediumSpace),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null, // Всегда неактивна для обычных игроков
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInThisTeam ? AppColors.success : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isInThisTeam 
                          ? 'Вы в этой команде' 
                          : 'Только просмотр',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Логика для организаторов
    final isMyTeam = team.ownerId == user.id;
    final isOtherOrganizerTeam = team.ownerId != null && team.ownerId != user.id;
    
    // Проверяем временные ограничения
    final now = DateTime.now();
    
    bool canJoin = !team.isFull && 
                   GameTimeUtils.canJoinGame(room);
    
    // Организатор не может присоединиться к команде другого организатора
    if (isOtherOrganizerTeam) {
      canJoin = false;
    }
    
    String getButtonText() {
      if (isMyTeam) {
        return 'Присоединиться со своей командой';
      } else if (isOtherOrganizerTeam) {
        return 'Команда соперника';
      } else if (team.isFull) {
        return 'Команда заполнена';
      } else if (!GameTimeUtils.canJoinGame(room)) {
        if (room.status != RoomStatus.planned) {
          return 'Игра уже активна';
        } else {
          final remainingMinutes = room.startTime.difference(now).inMinutes;
          if (remainingMinutes > 0) {
            return 'Присоединение заблокировано (${remainingMinutes} мин до игры)';
          } else {
            return 'Игра уже началась';
          }
        }
      } else {
        return 'Присоединиться к команде';
      }
    }
    
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
                Text(
                  team.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: team.isFull ? AppColors.error : AppColors.success,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${team.members.length}/${team.maxMembers}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            if (team.members.isEmpty)
              const Text(
                'Нет участников',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              FutureBuilder<List<UserModel?>>(
                future: _loadTeamMembers(team.members),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  final members = snapshot.data ?? [];
                  
                  return Column(
                    children: members.map((member) {
                      if (member == null) {
                        return const ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text('Пользователь не найден'),
                        );
                      }
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
                            child: member.photoUrl == null 
                                ? Text(_getInitials(member.name), style: const TextStyle(color: AppColors.primary))
                                : null,
                          ),
                          title: Text(member.name),
                          subtitle: Text('${member.gamesPlayed} игр'),
                          onTap: () => _showPlayerProfile(member),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            
            const SizedBox(height: AppSizes.mediumSpace),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isJoining || !canJoin) ? null : () => _joinTeam(team.id, user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canJoin ? AppColors.primary : Colors.grey,
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
                        getButtonText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Выбор команды'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go(AppRoutes.home),
            tooltip: 'На главную',
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
              Text('Ошибка загрузки: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(roomProvider(widget.roomId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (room) => room == null
            ? const Center(child: Text('Комната не найдена'))
            : userAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Ошибка пользователя: $error')),
                data: (user) => user == null
                    ? const Center(child: Text('Пользователь не найден'))
                    : StreamBuilder<List<TeamModel>>(
                        stream: ref.read(teamServiceProvider).watchTeamsForRoom(widget.roomId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Ошибка загрузки команд: ${snapshot.error}'),
                            );
                          }
                          
                          final teams = snapshot.data ?? [];
                          
                          if (teams.isEmpty) {
                            return const Center(
                              child: Text('Команды не найдены'),
                            );
                          }
                          
                          return RefreshIndicator(
                            onRefresh: () async {
                              ref.refresh(roomProvider(widget.roomId));
                            },
                            child: SingleChildScrollView(
                              padding: AppSizes.screenPadding,
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Выберите команду для игры "${room.title}"',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.mediumSpace),
                                  
                                  ...teams.map((team) => _buildTeamCard(team, user, room)).toList(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
} 