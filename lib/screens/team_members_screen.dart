import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../models/user_team_model.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';

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
  List<String> _friendsList = [];
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

      // Получаем участников команды
      final members = await userService.getUsersByIds(teamDoc.members);
      
      // Получаем список друзей текущего пользователя
      final friends = await userService.getFriends(currentUser.id);
      final friendsIds = friends.map((f) => f.id).toList();

      if (mounted) {
        setState(() {
          _team = teamDoc;
          _teamMembers = members;
          _friendsList = friendsIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFriend(UserModel member) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final userService = ref.read(userServiceProvider);
      final isFriend = _friendsList.contains(member.id);

      if (isFriend) {
        await userService.removeFriend(currentUser.id, member.id);
        setState(() {
          _friendsList.remove(member.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.name} удален из друзей'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await userService.addFriend(currentUser.id, member.id);
        setState(() {
          _friendsList.add(member.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.name} добавлен в друзья'),
              backgroundColor: AppColors.success,
            ),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.teamName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Участники команды',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _teamMembers.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                return _buildMemberTile(_teamMembers[index]);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMemberTile(UserModel member) {
    final currentUser = ref.read(currentUserProvider).value;
    final isSelf = currentUser?.id == member.id;
    final isFriend = _friendsList.contains(member.id);
    final isOwner = _team?.ownerId == member.id;

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
          if (isOwner) ...[
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
            'Игр: ${member.gamesPlayed} • Побед: ${member.wins} • Винрейт: ${member.winRate.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (member.bio.isNotEmpty) ...[
            const SizedBox(height: 2),
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
        ],
      ),
      trailing: isSelf
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Это вы',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : IconButton(
              icon: Icon(
                isFriend ? Icons.person_remove : Icons.person_add,
                color: isFriend ? AppColors.error : AppColors.success,
              ),
              onPressed: () => _toggleFriend(member),
              tooltip: isFriend ? 'Удалить из друзей' : 'Добавить в друзья',
            ),
    );
  }
} 