import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/providers.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../teams/domain/entities/user_team_model.dart';
import '../../../teams/domain/entities/team_activity_check_model.dart';
import '../../../../shared/widgets/dialogs/player_profile_dialog.dart';
import 'dart:async';

class TeamViewScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String teamName;

  const TeamViewScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  ConsumerState<TeamViewScreen> createState() => _TeamViewScreenState();
}

class _TeamViewScreenState extends ConsumerState<TeamViewScreen> {
  UserTeamModel? _team;
  List<UserModel> _teamMembers = [];
  bool _isLoading = true;
  bool _isLoadingMembers = false;
  bool _isJoining = false;
  bool _isLeaving = false;
  bool _isCheckingActivity = false;
  TeamActivityCheckModel? _activeCheck;
  Timer? _refreshTimer;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadTeamData();
    
    // Автообновление каждые 30 секунд
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadTeamData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final teamService = ref.read(teamServiceProvider);
      final userService = ref.read(userServiceProvider);

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

      // Загружаем активную проверку активности
      _activeCheck = await teamService.getActiveActivityCheck(widget.teamId);

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
    return Scaffold(
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
              : Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/schedule/schedule_bg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadTeamData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                      // Информация о команде
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Основная информация о команде
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                                    child: Text(
                                      widget.teamName.isNotEmpty 
                                          ? widget.teamName[0].toUpperCase() 
                                          : 'T',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.teamName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '${_teamMembers.length}/6 игроков',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _team!.isFull ? AppColors.success : AppColors.warning,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _team!.isFull ? 'Готова' : 'Неполная',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Компактная статистика команды
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildCompactStat('Очки', '${_team!.teamScore}', Icons.stars, AppColors.warning),
                                    Container(width: 1, height: 30, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                                    _buildCompactStat('Игр', '${_team!.gamesPlayed}', Icons.sports_volleyball, AppColors.primary),
                                    Container(width: 1, height: 30, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                                    _buildCompactStat('Побед', '${_team!.gamesWon}', Icons.emoji_events, AppColors.success),
                                    Container(width: 1, height: 30, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                                    _buildCompactStat('Винрейт', '${_team!.winRate.toStringAsFixed(0)}%', Icons.trending_up, AppColors.secondary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // Проверка активности команды (только для организаторов)
                      _buildActivityCheckSection(),

                      // Состав команды
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Состав команды',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
                                return _buildMemberTile(_teamMembers[index]);
                              },
                            ),
                          ],
                        ),
                      ),

                      // Кнопка действий для пользователя
                      Builder(
                        builder: (context) {
                          final currentUser = ref.read(currentUserProvider).value;
                          if (currentUser == null || _team == null) {
                            return const SizedBox.shrink();
                          }

                          // Если пользователь участник команды (но не владелец) - показываем кнопку выхода
                          if (_team!.members.contains(currentUser.id) && _team!.ownerId != currentUser.id) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _showLeaveTeamDialog,
                                  icon: const Icon(Icons.exit_to_app),
                                  label: const Text('Покинуть команду'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.warning,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(UserModel member) {
    final isTeamOwner = _team?.ownerId == member.id;
    final currentUser = ref.read(currentUserProvider).value;
    final isOwnProfile = currentUser?.id == member.id;

    return ListTile(
      onTap: () {
        PlayerProfileDialog.show(context, ref, member.id, playerName: member.name);
      },
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: member.photoUrl != null
            ? NetworkImage(member.photoUrl!)
            : null,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: member.photoUrl == null
            ? Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 16,
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
                fontSize: 16,
              ),
            ),
          ),
          if (isTeamOwner) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.sports_volleyball, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${member.gamesPlayed} игр',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (member.bio.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              member.bio,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Иконка добавления в друзья (только если это не свой профиль)
          if (!isOwnProfile && currentUser != null) ...[
            FutureBuilder<String>(
              future: ref.read(userServiceProvider).getFriendshipStatus(currentUser!.id, member.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                
                final friendshipStatus = snapshot.data ?? 'none';
                IconData icon;
                Color color;
                String tooltip;
                
                switch (friendshipStatus) {
                  case 'friends':
                    icon = Icons.person_remove;
                    color = AppColors.error;
                    tooltip = 'Удалить из друзей';
                    break;
                  case 'request_sent':
                    icon = Icons.schedule;
                    color = AppColors.warning;
                    tooltip = 'Запрос отправлен';
                    break;
                  case 'request_received':
                    icon = Icons.person_add_alt;
                    color = AppColors.success;
                    tooltip = 'Ответить на запрос';
                    break;
                  case 'none':
                  default:
                    icon = Icons.person_add;
                    color = AppColors.primary;
                    tooltip = 'Добавить в друзья';
                    break;
                }
                
                return IconButton(
                  onPressed: () => _handleFriendAction(member, friendshipStatus),
                  icon: Icon(icon, size: 18),
                  color: color,
                  tooltip: tooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
          ],
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Future<void> _handleFriendAction(UserModel player, String friendshipStatus) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final userService = ref.read(userServiceProvider);

      switch (friendshipStatus) {
        case 'friends':
          // Удаляем из друзей
          await userService.removeFriend(currentUser.id, player.id);
          if (mounted) {
            setState(() {
              // Обновляем UI
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${player.name} удален из друзей'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          break;

        case 'none':
          // Отправляем запрос дружбы
          await userService.sendFriendRequest(currentUser.id, player.id);
          if (mounted) {
            setState(() {
              // Обновляем UI
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Запрос дружбы отправлен ${player.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          break;

        case 'request_sent':
          // Отменяем запрос дружбы
          await userService.cancelFriendRequest(currentUser.id, player.id);
          if (mounted) {
            setState(() {
              // Обновляем UI
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Запрос дружбы ${player.name} отменен'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          break;

        case 'request_received':
          // Показываем диалог принятия/отклонения
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
        
        // Находим запрос дружбы
        final requests = await userService.getIncomingFriendRequests(currentUser.id);
        final request = requests.firstWhere(
          (r) => r.fromUserId == player.id,
          orElse: () => throw Exception('Запрос не найден'),
        );

        if (result) {
          // Принимаем запрос
          await userService.acceptFriendRequest(request.id);
          if (mounted) {
            setState(() {
              // Обновляем UI
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${player.name} добавлен в друзья'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          // Отклоняем запрос
          await userService.declineFriendRequest(request.id);
          if (mounted) {
            setState(() {
              // Обновляем UI
            });
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildCompactStat(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }



  Future<bool> _canApplyToTeam() async {
    // Функция больше не используется, но оставлена для совместимости
    return false;
  }

  void _showApplicationDialog() {
    // Функция больше не используется
  }

  Future<void> _submitApplication(String message) async {
    // Функция больше не используется
  }

  void _showLeaveTeamDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Покинуть команду "${widget.teamName}"'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вы уверены, что хотите покинуть эту команду?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.warning, color: AppColors.warning, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Это действие нельзя отменить',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveTeam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Покинуть'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveTeam() async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null || _team == null) return;

      final teamService = ref.read(teamServiceProvider);
      await teamService.leaveUserTeam(currentUser.id);

      if (mounted) {
        ErrorHandler.teamLeft(context, widget.teamName);
        
        // Принудительно обновляем все связанные провайдеры
        ref.invalidate(currentUserProvider);
        ref.invalidate(userProvider(currentUser.id));
        
        // Ждем немного для синхронизации
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Обновляем данные команды
        await _loadTeamData();
        
        // Дополнительная проверка - перезагружаем пользователя
        final userService = ref.read(userServiceProvider);
        final updatedUser = await userService.getUserById(currentUser.id);
        debugPrint('🔄 Пользователь после покидания команды: teamId=${updatedUser?.teamId}, teamName=${updatedUser?.teamName}');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  // === МЕТОДЫ ДЛЯ ПРОВЕРКИ АКТИВНОСТИ ===

  Widget _buildActivityCheckSection() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || _team == null) {
      return const SizedBox.shrink();
    }

    final isOwner = _team!.ownerId == currentUser.id;
    
    // Отладка: показываем секцию всем участникам команды
    debugPrint('🔍 Activity check section: isOwner=$isOwner, teamId=${_team!.id}, currentUserId=${currentUser.id}');
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Готовность команды',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Отображаем статус активной проверки или кнопку запуска
            if (_activeCheck != null) ...[
              _buildActiveCheckStatus(),
            ] else if (isOwner) ...[
              _buildStartCheckButton(),
            ] else ...[
              _buildNoActiveCheckMessage(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCheckStatus() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || _activeCheck == null) {
      return const SizedBox.shrink();
    }

    final isOwner = _team!.ownerId == currentUser.id;
    final timeLeft = _activeCheck!.expiresAt.difference(DateTime.now());
    final timeLeftMinutes = timeLeft.inMinutes;
    final isExpired = _activeCheck!.isExpired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Статистика готовности
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Готовы: ${_activeCheck!.readyPlayers.length}/${_activeCheck!.teamMembers.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _activeCheck!.readinessPercentage / 100,
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _activeCheck!.areAllPlayersReady 
                            ? AppColors.success 
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isExpired 
                          ? 'Время истекло'
                          : 'Осталось: ${timeLeftMinutes} мин',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_activeCheck!.areAllPlayersReady) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Все готовы!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 12),

        // Кнопки действий
        Row(
          children: [
            // Кнопки для игроков (не организаторов)
            if (!isOwner && !isExpired) ...[
              if (!_activeCheck!.hasPlayerResponded(currentUser.id)) ...[
                // Кнопка "Готов"
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmReadiness(_activeCheck!.id),
                    icon: const Icon(Icons.check),
                    label: const Text('Готов'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Кнопка "Не готов"
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _declineReadiness(_activeCheck!.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Не готов'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Показываем статус ответа игрока
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _activeCheck!.isPlayerReady(currentUser.id) 
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _activeCheck!.isPlayerReady(currentUser.id) 
                            ? AppColors.success 
                            : AppColors.error,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _activeCheck!.isPlayerReady(currentUser.id) 
                              ? Icons.check_circle 
                              : Icons.cancel,
                          color: _activeCheck!.isPlayerReady(currentUser.id) 
                              ? AppColors.success 
                              : AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _activeCheck!.isPlayerReady(currentUser.id) 
                              ? 'Готовность подтверждена'
                              : 'Готовность отклонена',
                          style: TextStyle(
                            color: _activeCheck!.isPlayerReady(currentUser.id) 
                                ? AppColors.success 
                                : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            
            // Кнопка отмены для организатора
            if (isOwner && !isExpired) ...[
              if (!isOwner || _activeCheck!.hasPlayerResponded(currentUser.id)) const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _cancelActivityCheck(_activeCheck!.id),
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text('Отменить'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ],
        ),

        // Детальная статистика для организатора
        if (isOwner) ...[
          const SizedBox(height: 16),
          _buildDetailedPlayerStats(),
        ],
      ],
    );
  }

  Widget _buildStartCheckButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isCheckingActivity ? null : _startActivityCheck,
        icon: _isCheckingActivity 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.notification_important),
        label: Text(_isCheckingActivity 
            ? 'Запуск проверки...' 
            : 'Проверить активность игроков'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warning,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildNoActiveCheckMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Нет активной проверки готовности. Организатор может запустить проверку для подтверждения готовности команды к игре.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startActivityCheck() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || _team == null) return;

    setState(() {
      _isCheckingActivity = true;
    });

    try {
      final activityService = ref.read(teamActivityServiceProvider);
      final checkId = await activityService.startActivityCheck(
        teamId: widget.teamId,
        organizer: currentUser,
      );

      if (mounted) {
        ErrorHandler.showSuccess(context, 'Проверка активности запущена! Уведомления отправлены всем игрокам команды.');

        // Обновляем данные
        await _loadTeamData();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingActivity = false;
        });
      }
    }
  }

  Future<void> _confirmReadiness(String checkId) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    try {
      final activityService = ref.read(teamActivityServiceProvider);
      await activityService.confirmReadiness(
        checkId: checkId,
        playerId: currentUser.id,
      );

      if (mounted) {
        ErrorHandler.showSuccess(context, 'Готовность подтверждена!');

        // Обновляем данные
        await _loadTeamData();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _declineReadiness(String checkId) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    try {
      final activityService = ref.read(teamActivityServiceProvider);
      await activityService.declineReadiness(
        checkId: checkId,
        playerId: currentUser.id,
      );

      if (mounted) {
        ErrorHandler.showSuccess(context, 'Готовность отклонена');

        // Обновляем данные
        await _loadTeamData();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _cancelActivityCheck(String checkId) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    try {
      final activityService = ref.read(teamActivityServiceProvider);
      await activityService.cancelCheck(
        checkId: checkId,
        organizerId: currentUser.id,
      );

      if (mounted) {
        ErrorHandler.cancelled(context, 'Проверка активности');

        // Обновляем данные
        await _loadTeamData();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  /// Детальная статистика игроков для организатора
  Widget _buildDetailedPlayerStats() {
    if (_activeCheck == null || _teamMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статус игроков:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          ..._teamMembers.where((member) => member.id != _activeCheck!.organizerId).map((member) {
            final isReady = _activeCheck!.isPlayerReady(member.id);
            final isNotReady = _activeCheck!.isPlayerNotReady(member.id);
            final hasResponded = _activeCheck!.hasPlayerResponded(member.id);
            
            IconData icon;
            Color color;
            String status;
            
            if (isReady) {
              icon = Icons.check_circle;
              color = AppColors.success;
              status = 'Готов';
            } else if (isNotReady) {
              icon = Icons.cancel;
              color = AppColors.error;
              status = 'Не готов';
            } else {
              icon = Icons.access_time;
              color = AppColors.warning;
              status = 'Ждем ответа';
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
} 