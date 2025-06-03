import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../teams/domain/entities/user_team_model.dart';

class TeamMembersScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String teamName;

  const TeamMembersScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  ConsumerState<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends ConsumerState<TeamMembersScreen> {
  UserTeamModel? _team;
  List<UserModel> _teamMembers = [];
  List<UserModel> _friends = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final teamService = ref.read(teamServiceProvider);
      final userService = ref.read(userServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;

      if (currentUser == null) {
        setState(() {
          _error = 'Пользователь не найден';
          _isLoading = false;
        });
        return;
      }

      // Получаем команду
      final teamDoc = await teamService.getUserTeamById(widget.teamId);
      if (teamDoc == null) {
        setState(() {
          _error = 'Команда не найдена';
          _isLoading = false;
        });
        return;
      }

      _team = teamDoc;

      // Загружаем участников команды
      final membersFutures = _team!.members
          .map((memberId) => userService.getUserById(memberId))
          .toList();
      
      final membersResults = await Future.wait(membersFutures);
      _teamMembers = membersResults
          .where((member) => member != null)
          .cast<UserModel>()
          .toList();

      // Загружаем друзей текущего пользователя (только если он владелец команды)
      if (_team!.ownerId == currentUser.id) {
        _friends = await userService.getFriends(currentUser.id);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки данных: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(currentUserProvider).value;
    final isOwner = currentUser?.id == _team?.ownerId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.teamName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (isOwner && _team != null && !_team!.isFull)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showInviteFriendDialog,
              tooltip: 'Пригласить друга',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTeamData,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTeamData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Информация о команде
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.groups,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.teamName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Участников: ${_teamMembers.length}/6',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (_team != null && !_team!.isFull) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Свободных мест: ${_team!.availableSlots}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // Список участников
                      Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Text(
                                    'Участники команды',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isOwner && _team != null && !_team!.isFull)
                                    TextButton.icon(
                                      onPressed: _showInviteFriendDialog,
                                      icon: const Icon(Icons.person_add, size: 16),
                                      label: const Text('Пригласить'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _teamMembers.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                return _buildMemberTile(_teamMembers[index], isOwner);
                              },
                            ),
                          ],
                        ),
                      ),

                      // Пустые слоты
                      if (_team != null && !_team!.isFull) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Свободные места',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...List.generate(_team!.availableSlots, (index) => 
                                _buildEmptySlot(index, isOwner)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildMemberTile(UserModel member, bool isOwner) {
    final currentUser = ref.read(currentUserProvider).value;
    final isSelf = currentUser?.id == member.id;
    final isTeamOwner = _team?.ownerId == member.id;

    return ListTile(
      onTap: () {
        // Навигация к профилю игрока
        context.push('/player/${member.id}?playerName=${Uri.encodeComponent(member.name)}');
      },
      leading: CircleAvatar(
        backgroundImage: member.photoUrl != null
            ? NetworkImage(member.photoUrl!)
            : null,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: member.photoUrl == null
            ? Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isTeamOwner) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Капитан',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Рейтинг: ${member.rating.toStringAsFixed(1)} • ${member.gamesPlayed} игр',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (member.bio.isNotEmpty)
            Text(
              member.bio,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: isOwner && !isTeamOwner
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') {
                  _removeMember(member);
                } else if (value == 'replace') {
                  _showReplaceMemberDialog(member);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'replace',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 16),
                      SizedBox(width: 8),
                      Text('Заменить'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, size: 16, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Удалить', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert, size: 20),
            )
          : null,
    );
  }

  Widget _buildEmptySlot(int index, bool isOwner) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        child: Icon(
          Icons.person_add_outlined,
          color: Colors.grey.shade600,
        ),
      ),
      title: Text(
        'Свободное место ${index + 1}',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
      subtitle: Text(
        isOwner ? 'Нажмите "Пригласить" чтобы добавить игрока' : 'Ожидает приглашения',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
      trailing: isOwner
          ? IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.primary,
              onPressed: _showInviteFriendDialog,
            )
          : null,
    );
  }

  void _showInviteFriendDialog() {
    if (_friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('У вас нет друзей для приглашения'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Фильтруем друзей, которые не в команде и не имеют другой команды
    final availableFriends = _friends.where((friend) => 
        !_team!.members.contains(friend.id) && friend.teamId == null
    ).toList();

    if (availableFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Все ваши друзья уже в командах или в этой команде'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пригласить друга'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: availableFriends.length,
            itemBuilder: (context, index) {
              final friend = availableFriends[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: friend.photoUrl != null
                      ? NetworkImage(friend.photoUrl!)
                      : null,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: friend.photoUrl == null
                      ? Text(
                          friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                title: Text(friend.name),
                subtitle: Text(
                  'Рейтинг: ${friend.rating.toStringAsFixed(1)} • ${friend.gamesPlayed} игр',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _inviteFriend(friend);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showReplaceMemberDialog(UserModel memberToReplace) {
    // Фильтруем друзей, которые не в команде и не имеют другой команды
    final availableFriends = _friends.where((friend) => 
        !_team!.members.contains(friend.id) && friend.teamId == null
    ).toList();

    if (availableFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет доступных друзей для замены'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Заменить ${memberToReplace.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${memberToReplace.name} будет исключен из команды',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: availableFriends.length,
                  itemBuilder: (context, index) {
                    final friend = availableFriends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: friend.photoUrl != null
                            ? NetworkImage(friend.photoUrl!)
                            : null,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: friend.photoUrl == null
                            ? Text(
                                friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      title: Text(friend.name),
                      subtitle: Text(
                        'Рейтинг: ${friend.rating.toStringAsFixed(1)} • ${friend.gamesPlayed} игр',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _inviteFriend(friend, replacedMember: memberToReplace);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteFriend(UserModel friend, {UserModel? replacedMember}) async {
    try {
      final teamService = ref.read(teamServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;
      
      if (currentUser == null || _team == null) return;

      await teamService.sendTeamInvitation(
        teamId: _team!.id,
        fromUserId: currentUser.id,
        toUserId: friend.id,
        replacedUserId: replacedMember?.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              replacedMember != null
                  ? 'Приглашение отправлено ${friend.name} для замены ${replacedMember.name}'
                  : 'Приглашение отправлено ${friend.name}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(UserModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить из команды'),
        content: Text('Удалить ${member.name} из команды?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final teamService = ref.read(teamServiceProvider);
        final currentUser = ref.read(currentUserProvider).value;
        
        if (currentUser == null || _team == null) return;

        await teamService.removePlayerFromTeam(_team!.id, member.id, currentUser.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.name} удален из команды'),
              backgroundColor: AppColors.success,
            ),
          );

          // Перезагружаем данные
          await _loadTeamData();
          
          // Обновляем профиль пользователя
          ref.invalidate(currentUserProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
} 