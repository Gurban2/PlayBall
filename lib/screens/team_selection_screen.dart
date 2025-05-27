import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';

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
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.joinTeam(teamId, user.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы успешно присоединились к команде!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Возвращаемся к экрану комнаты
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка присоединения: ${e.toString()}'),
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

  Future<List<UserModel?>> _loadTeamMembers(List<String> memberIds) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final members = <UserModel?>[];
    
    for (final memberId in memberIds) {
      try {
        final user = await firestoreService.getUserById(memberId);
        members.add(user);
      } catch (e) {
        debugPrint('Ошибка загрузки участника $memberId: $e');
        members.add(null);
      }
    }
    
    return members;
  }

  Widget _buildTeamCard(TeamModel team, UserModel user, RoomModel room) {
    final canJoin = !team.isFull && room.status == RoomStatus.planned;
    
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
                      
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          backgroundImage: member.photoUrl != null 
                              ? NetworkImage(member.photoUrl!) 
                              : null,
                          child: member.photoUrl == null
                              ? Text(
                                  member.name.isNotEmpty 
                                      ? member.name.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(member.name),
                        subtitle: Text('Рейтинг: ${member.rating}'),
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
                        canJoin 
                            ? 'Присоединиться к команде'
                            : team.isFull 
                                ? 'Команда заполнена'
                                : 'Игра уже началась',
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
                        stream: ref.read(firestoreServiceProvider).getTeamsForRoomStream(widget.roomId),
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