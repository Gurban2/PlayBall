import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/providers.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../teams/domain/entities/team_model.dart';
import '../../../teams/data/datasources/team_service.dart';
import '../../../../shared/widgets/cards/player_card.dart';
import '../../domain/entities/room_model.dart';

class RoomTeamsCard extends ConsumerWidget {
  final RoomModel room;
  final String roomId;
  final TeamService teamService;

  const RoomTeamsCard({
    super.key,
    required this.room,
    required this.roomId,
    required this.teamService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              stream: teamService.watchTeamsForRoom(roomId),
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
                  children: teams.map((team) => _TeamItem(
                    team: team,
                    onTap: () => _showTeamPlayersDialog(context, ref, team),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamPlayersDialog(BuildContext context, WidgetRef ref, TeamModel team) async {
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

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Команда "${team.name}"'),
        content: SizedBox(
          width: double.maxFinite,
          child: players.isEmpty
              ? const Text('В команде нет игроков')
              : ListView.builder(
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
                      onTap: () => _showPlayerProfileDialog(context, ref, player),
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

  void _showPlayerProfileDialog(BuildContext context, WidgetRef ref, UserModel player) async {
    final currentUser = ref.read(currentUserProvider).value;
    
    if (currentUser == null) return;
    
    final userService = ref.read(userServiceProvider);
    final isOwnProfile = currentUser.id == player.id;
    final isFriend = currentUser.friends.contains(player.id);

    // Загружаем предстоящие игры игрока
    final upcomingGames = <GameRef>[];
    // TODO: Реализовать загрузку предстоящих игр

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                _getInitials(player.name),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(player.name),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProfileRow('Роль', _getRoleDisplayName(player.role)),
                _buildProfileRow('Email', player.email),
                
                if (upcomingGames.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Предстоящие игры:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...upcomingGames.map((game) => _buildUpcomingGameItem(context, game)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (!isOwnProfile && currentUser != null) ...[
            TextButton.icon(
              onPressed: () => _handleFriendAction(context, ref, currentUser, player, isFriend),
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

  Widget _buildUpcomingGameItem(BuildContext context, GameRef game) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(); // Закрываем текущий диалог
          // context.push('${AppRoutes.room}/${game.id}');
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

  Future<void> _handleFriendAction(BuildContext context, WidgetRef ref, UserModel currentUser, UserModel player, bool isFriend) async {
    try {
      final userService = ref.read(userServiceProvider);
      
      if (isFriend) {
        // Удаляем из друзей
        await userService.removeFriend(currentUser.id, player.id);
        if (context.mounted) {
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
        await userService.addFriend(currentUser.id, player.id);
        if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
}

// Компонент для отображения одной команды
class _TeamItem extends StatelessWidget {
  final TeamModel team;
  final VoidCallback onTap;

  const _TeamItem({
    required this.team,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.smallSpace),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: InkWell(
          onTap: onTap,
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
}

// Класс для представления предстоящих игр
class GameRef {
  final String id;
  final String title;
  final String location;
  final DateTime date;

  GameRef({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
  });
} 