import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/providers.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../teams/domain/entities/team_model.dart';
import '../../../../shared/widgets/dialogs/unified_dialogs.dart';
import '../../../../shared/widgets/dialogs/player_profile_dialog.dart';


class TeamScreen extends ConsumerStatefulWidget {
  final String roomId;
  
  const TeamScreen({super.key, required this.roomId});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  UserModel? _currentUser;
  List<TeamModel> _teams = [];
  List<UserModel> _availableUsers = [];
  List<UserModel> _roomParticipants = [];
  bool _isLoading = true;
  bool _isCreatingTeam = false;

  late Map<String, String> teamNames = {
    'team1': 'Команда 1',
    'team2': 'Команда 2',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTeamNames();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      final room = await ref.read(roomServiceProvider).getRoomById(widget.roomId);
      
      if (room != null) {
        // Загружаем участников комнаты
        final participants = await Future.wait(
          room.participants.map((id) => ref.read(userServiceProvider).getUserById(id))
        );
        
        // Загружаем команды
        final teams = await ref.read(teamServiceProvider).getTeamsForRoom(widget.roomId);

        if (mounted) {
          setState(() {
            _currentUser = currentUser;
            _teams = teams;
            _roomParticipants = participants.whereType<UserModel>().toList();
            _availableUsers = _roomParticipants
                .where((user) => !_teams.any((team) => team.members.contains(user.id)))
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _loadTeamNames() async {
    try {
      final teamService = ref.read(teamServiceProvider);
      final teams = await teamService.getTeamsForRoom(widget.roomId);
      
      if (teams.length >= 2) {
        setState(() {
          teamNames = {
            'team1': teams[0].name,
            'team2': teams[1].name,
          };
        });
      }
    } catch (e) {
      // Используем значения по умолчанию
    }
  }

  Future<void> _createTeam() async {
    final result = await UnifiedDialogs.showCreateTeam(context: context);

    if (result != null) {
      setState(() {
        _isCreatingTeam = true;
      });

      try {
        // Создаем новую команду
        final newTeam = TeamModel(
          id: 'team-${DateTime.now().millisecondsSinceEpoch}',
          name: result,
          members: [],
          roomId: widget.roomId,
          createdAt: DateTime.now(),
        );

        // TODO: Сохранить команду в Firestore
        // await _teamService.createTeam(newTeam);

        setState(() {
          _teams.add(newTeam);
          _isCreatingTeam = false;
        });

        if (mounted) {
          ErrorHandler.teamCreated(context, result);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCreatingTeam = false;
          });
          ErrorHandler.showError(context, e);
        }
      }
    }
  }

  Future<void> _addUserToTeam(TeamModel team, UserModel user) async {
    try {
      // TODO: Обновить команду в Firestore
      // await _teamService.addUserToTeam(team.id, user.id);

      setState(() {
        final teamIndex = _teams.indexWhere((t) => t.id == team.id);
        if (teamIndex != -1) {
          _teams[teamIndex] = TeamModel(
            id: team.id,
            name: team.name,
            members: [...team.members, user.id],
            roomId: team.roomId,
            createdAt: team.createdAt,
          );
        }
        _availableUsers.remove(user);
      });

      if (mounted) {
        ErrorHandler.showSuccess(context, '${user.name} добавлен в команду ${team.name}');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _removeUserFromTeam(TeamModel team, String userId) async {
    try {
      // TODO: Обновить команду в Firestore
      // await _teamService.removeUserFromTeam(team.id, userId);

      final user = _roomParticipants.firstWhere((u) => u.id == userId);
      
      setState(() {
        final teamIndex = _teams.indexWhere((t) => t.id == team.id);
        if (teamIndex != -1) {
          _teams[teamIndex] = TeamModel(
            id: team.id,
            name: team.name,
            members: team.members.where((id) => id != userId).toList(),
            roomId: team.roomId,
            createdAt: team.createdAt,
          );
        }
        _availableUsers.add(user);
      });

      if (mounted) {
        ErrorHandler.showWarning(context, '${user.name} удален из команды ${team.name}');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Widget _buildTeamCard(TeamModel team) {
    final teamMembers = _roomParticipants
        .where((user) => team.members.contains(user.id))
        .toList();

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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${teamMembers.length} участников',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            if (teamMembers.isEmpty)
              const Text(
                'Нет участников',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: teamMembers.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final member = teamMembers[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => PlayerProfileDialog.show(context, ref, member.id, playerName: member.name),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: member.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                member.photoUrl!,
                                width: AppSizes.smallAvatarSize,
                                height: AppSizes.smallAvatarSize,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.person, color: Colors.white);
                                },
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(member.name),
                    subtitle: Text('${member.gamesPlayed} игр'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: AppColors.error),
                      onPressed: () => _removeUserFromTeam(team, member.id),
                    ),
                  );
                },
              ),
            
            const SizedBox(height: AppSizes.mediumSpace),
            
            // Кнопка добавления участников
            if (_availableUsers.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddUserDialog(team),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Добавить участника'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(TeamModel team) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Добавить в ${team.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableUsers.length,
              itemBuilder: (context, index) {
                final user = _availableUsers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null 
                          ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', 
                                style: const TextStyle(color: AppColors.primary))
                          : null,
                    ),
                    title: Text(user.name),
                    subtitle: Text('${user.gamesPlayed} игр'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _addUserToTeam(team, user);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.cancel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableUsersCard() {
    if (_availableUsers.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Участники без команды (${_availableUsers.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.mediumSpace),
            
            Column(
              children: _availableUsers.map((user) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    onTap: () => PlayerProfileDialog.show(context, ref, user.id, playerName: user.name),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null 
                          ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', 
                                style: const TextStyle(color: AppColors.primary))
                          : null,
                    ),
                    title: Text(user.name),
                    subtitle: Text('${user.gamesPlayed} игр'),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teams),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isCreatingTeam ? null : _createTeam,
            icon: _isCreatingTeam
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSizes.screenPadding,
              child: Column(
                children: [
                  if (_teams.isEmpty)
                    Card(
                      child: Padding(
                        padding: AppSizes.cardPadding,
                        child: Column(
                          children: [
                            const Icon(
                              Icons.groups,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppSizes.mediumSpace),
                            const Text(
                              AppStrings.noTeams,
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.mediumSpace),
                            ElevatedButton.icon(
                              onPressed: _createTeam,
                              icon: const Icon(Icons.add),
                              label: const Text(AppStrings.createTeam),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Список команд
                    ...(_teams.map((team) => _buildTeamCard(team)).toList()),
                    
                    const SizedBox(height: AppSizes.mediumSpace),
                    
                    // Участники без команды
                    _buildAvailableUsersCard(),
                  ],
                ],
              ),
            ),
    );
  }
} 