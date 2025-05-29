import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';

// Модель команды (временная, пока не создана отдельная модель)
class TeamModel {
  final String id;
  final String name;
  final List<String> members;
  final String roomId;
  final DateTime createdAt;

  TeamModel({
    required this.id,
    required this.name,
    required this.members,
    required this.roomId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'members': members,
      'roomId': roomId,
      'createdAt': createdAt,
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    return TeamModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      roomId: map['roomId'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }
}

class TeamScreen extends StatefulWidget {
  final String roomId;
  
  const TeamScreen({super.key, required this.roomId});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  List<TeamModel> _teams = [];
  List<UserModel> _availableUsers = [];
  List<UserModel> _roomParticipants = [];
  bool _isLoading = true;
  bool _isCreatingTeam = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await _authService.getCurrentUserModel();
      final room = await _firestoreService.getRoomById(widget.roomId);
      
      if (room != null) {
        // Загружаем участников комнаты
        final participants = await Future.wait(
          room.participants.map((id) => _firestoreService.getUserById(id))
        );
        
        // Пока что создаем тестовые команды
        final testTeams = [
          TeamModel(
            id: 'team-1',
            name: 'Команда А',
            members: room.participants.take(3).toList(),
            roomId: widget.roomId,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          TeamModel(
            id: 'team-2',
            name: 'Команда Б',
            members: room.participants.skip(3).take(3).toList(),
            roomId: widget.roomId,
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ];

        if (mounted) {
          setState(() {
            _currentUser = currentUser;
            _teams = testTeams;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _createTeam() async {
    final teamNameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppStrings.createTeam),
          content: TextFormField(
            controller: teamNameController,
            decoration: const InputDecoration(
              labelText: 'Название команды',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите название команды';
              }
              return null;
            },
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final teamName = teamNameController.text.trim();
                if (teamName.isNotEmpty) {
                  Navigator.of(context).pop(teamName);
                }
              },
              child: const Text(AppStrings.createTeam),
            ),
          ],
        );
      },
    );

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
        // await _firestoreService.createTeam(newTeam);

        setState(() {
          _teams.add(newTeam);
          _isCreatingTeam = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Команда успешно создана!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCreatingTeam = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка создания команды: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _addUserToTeam(TeamModel team, UserModel user) async {
    try {
      // TODO: Обновить команду в Firestore
      // await _firestoreService.addUserToTeam(team.id, user.id);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} добавлен в команду ${team.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления в команду: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeUserFromTeam(TeamModel team, String userId) async {
    try {
      // TODO: Обновить команду в Firestore
      // await _firestoreService.removeUserFromTeam(team.id, userId);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} удален из команды ${team.name}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления из команды: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
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
                    subtitle: Text('Рейтинг: ${member.rating}'),
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
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: user.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user.photoUrl!,
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
                  title: Text(user.name),
                  subtitle: Text('Рейтинг: ${user.rating}'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _addUserToTeam(team, user);
                  },
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
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableUsers.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final user = _availableUsers[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: user.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user.photoUrl!,
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
                  title: Text(user.name),
                  subtitle: Text('Рейтинг: ${user.rating}'),
                );
              },
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