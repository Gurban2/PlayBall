import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;
  List<GameRef> _upcomingGames = [];
  bool _isLoadingGames = false;

  @override
  void initState() {
    super.initState();
    _loadUpcomingGames();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUpcomingGames() async {
    setState(() {
      _isLoadingGames = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        final firestoreService = ref.read(firestoreServiceProvider);
        final games = await firestoreService.getUpcomingGamesForUser(user.id);
        setState(() {
          _upcomingGames = games;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки предстоящих игр: $e');
    } finally {
      setState(() {
        _isLoadingGames = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Ошибка: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(currentUserProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (user) => user == null
            ? const Center(child: Text('Пользователь не найден'))
            : RefreshIndicator(
                onRefresh: () async => ref.refresh(currentUserProvider),
                child: SingleChildScrollView(
                  padding: AppSizes.screenPadding,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Основная карточка профиля
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Аватар и базовая информация
                              Row(
                                children: [
                      CircleAvatar(
                                    radius: 40,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                _getInitials(user.name),
                                style: const TextStyle(
                                              fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                                            fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                                          user.email.length > 20 
                                              ? '${user.email.substring(0, 20)}...' 
                                              : user.email,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 12,
                                              color: _getStatusColor(user.status),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              user.statusDisplayName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _getStatusColor(user.status),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Описание игрока
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _isEditingBio
                                          ? TextField(
                                              controller: _bioController,
                                              maxLength: 64,
                                              decoration: const InputDecoration(
                                                hintText: 'Расскажите о себе...',
                                                border: InputBorder.none,
                                                isDense: true,
                                              ),
                                              style: const TextStyle(fontSize: 14),
                                            )
                                          : Text(
                                              user.bio.isEmpty ? 'Расскажите о себе...' : user.bio,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: user.bio.isEmpty 
                                                    ? AppColors.textSecondary 
                                                    : AppColors.text,
                                              ),
                                            ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isEditingBio ? Icons.check : Icons.edit,
                                        size: 16,
                                      ),
                                      onPressed: () => _toggleBioEdit(user),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Основная статистика в компактном виде
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCompactStat(
                                    user.gamesPlayed.toString(),
                                    'Игр',
                                    Icons.sports_volleyball,
                                  ),
                                  _buildCompactStat(
                                    user.wins.toString(),
                                    'Побед',
                                    Icons.emoji_events,
                                  ),
                                  _buildCompactStat(
                                    user.losses.toString(),
                                    'Поражений',
                                    Icons.close,
                                  ),
                                  _buildCompactStat(
                                    '${user.winRate.toStringAsFixed(0)}%',
                                    'Винрейт',
                                    Icons.trending_up,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Рейтинг и баллы
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.star, color: AppColors.warning),
                                          const SizedBox(width: 8),
                                          Text(
                                            user.rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.score, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            user.totalScore.toString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Предстоящие игры
                      if (_upcomingGames.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: AppSizes.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Предстоящие игры',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._upcomingGames.map((game) => _buildGameItem(game, true)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Последние игры
                      if (user.recentGames.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: AppSizes.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Последние игры',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...user.recentGames.take(3).map((game) => _buildGameItem(game, false)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Достижения
                      if (user.achievements.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: AppSizes.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Достижения',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: user.achievements.map((achievement) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getAchievementIcon(achievement),
                                          size: 14,
                                          color: AppColors.warning,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          achievement.length > 15 
                                              ? '${achievement.substring(0, 15)}...' 
                                              : achievement,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Лучшие партнеры
                      if (user.bestTeammates.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: AppSizes.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Лучшие партнеры',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...user.bestTeammates.take(3).toList().asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final partner = entry.value;
                                  return _buildPartnerItem(partner, index + 1);
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Друзья (показываем всегда)
                      Card(
                        child: Padding(
                          padding: AppSizes.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Друзья',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${user.friends.length}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (user.friends.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 48,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'У вас пока нет друзей',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Играйте в командах и добавляйте игроков в друзья!',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                FutureBuilder<List<UserModel?>>(
                                  future: _loadFriends(user.friends),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    
                                    if (snapshot.hasError) {
                                      return Text('Ошибка загрузки друзей: ${snapshot.error}');
                                    }
                                    
                                    final friends = snapshot.data ?? [];
                                    if (friends.isEmpty) {
                                      return const Text('Нет друзей для отображения');
                                    }
                                    
                                    return Column(
                                      children: friends.take(5).map((friend) => 
                                        friend != null ? _buildFriendItem(friend) : Container()
                                      ).toList(),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Временные кнопки для изменения роли (только для разработки)
                      if (user.role == UserRole.user)
                        ElevatedButton.icon(
                          onPressed: () => _changeToOrganizer(context, ref, user),
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Стать организатором'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.organizerRole,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      
                      if (user.role == UserRole.organizer)
                        ElevatedButton.icon(
                          onPressed: () => _changeToUser(context, ref, user),
                          icon: const Icon(Icons.person),
                          label: const Text('Стать пользователем'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.userRole,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выхода: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleBioEdit(UserModel user) {
    if (_isEditingBio) {
      _saveBio(user);
    } else {
      _bioController.text = user.bio;
      setState(() {
        _isEditingBio = true;
      });
    }
  }

  void _saveBio(UserModel user) async {
    if (_bioController.text.length > 64) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Описание не должно превышать 64 символа'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({
        'bio': _bioController.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      ref.invalidate(currentUserProvider);
      
      setState(() {
        _isEditingBio = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Описание обновлено'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color _getStatusColor(PlayerStatus status) {
    switch (status) {
      case PlayerStatus.lookingForGame:
        return AppColors.success;
      case PlayerStatus.freeTonight:
        return AppColors.warning;
      case PlayerStatus.unavailable:
        return AppColors.error;
    }
  }

  IconData _getAchievementIcon(String achievement) {
    if (achievement.contains('Первая игра') || achievement.contains('игр')) {
      return Icons.sports_volleyball;
    } else if (achievement.contains('победа') || achievement.contains('Победитель')) {
      return Icons.emoji_events;
    } else if (achievement.contains('Мастер') || achievement.contains('Легенда')) {
      return Icons.star;
    } else if (achievement.contains('баллов')) {
      return Icons.score;
    }
    return Icons.emoji_events;
  }

  Widget _buildCompactStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          fontWeight: FontWeight.bold,
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

  Widget _buildGameItem(GameRef game, bool isUpcoming) {
    final color = isUpcoming 
        ? AppColors.primary 
        : (game.result == 'win' ? AppColors.success : AppColors.error);
    final icon = isUpcoming 
        ? Icons.schedule 
        : (game.result == 'win' ? Icons.emoji_events : Icons.close);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: isUpcoming ? () => _navigateToRoom(game.id) : null,
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title.length > 20 ? '${game.title.substring(0, 20)}...' : game.title,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  Text(
                    '${game.location} • ${game.date.day}.${game.date.month}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isUpcoming)
              TextButton(
                onPressed: () => _leaveUpcomingGame(game),
                child: const Text('Выйти', style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  void _leaveUpcomingGame(GameRef game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из игры'),
        content: Text('Вы действительно хотите выйти из игры "${game.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performLeaveGame(game);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLeaveGame(GameRef game) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;

      final firestoreService = ref.read(firestoreServiceProvider);
      
      // Получаем команду пользователя в этой игре
      final userTeam = await firestoreService.getUserTeamInRoom(user.id, game.id);
      if (userTeam == null) {
        throw Exception('Команда не найдена');
      }

      // Выходим из команды
      await firestoreService.leaveTeam(userTeam.id, user.id);
      
      // Обновляем список предстоящих игр
      await _loadUpcomingGames();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Вы вышли из игры "${game.title}"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выхода из игры: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToRoom(String roomId) {
    context.push('${AppRoutes.room}/$roomId');
  }

  Widget _buildPartnerItem(PlayerRef partner, int rank) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary,
            child: Text(
              rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
            ),
          ),
          Text(
                  '${partner.gamesPlayedTogether} игр • ${partner.winRateTogether.toStringAsFixed(0)}%',
            style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.star,
            color: AppColors.warning,
            size: 16,
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

  void _changeToOrganizer(BuildContext context, WidgetRef ref, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить роль'),
        content: const Text('Стать организатором?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _updateUserRole(context, ref, user.id, UserRole.organizer);
            },
            child: const Text('Да'),
          ),
        ],
      ),
    );
  }

  void _changeToUser(BuildContext context, WidgetRef ref, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить роль'),
        content: const Text('Стать пользователем?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _updateUserRole(context, ref, user.id, UserRole.user);
            },
            child: const Text('Да'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserRole(BuildContext context, WidgetRef ref, String userId, UserRole newRole) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'role': newRole.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });

      ref.invalidate(currentUserProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Роль изменена на ${newRole.toString().split('.').last}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
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

  Future<List<UserModel?>> _loadFriends(List<String> friendIds) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final friends = <UserModel?>[];
    
    for (final friendId in friendIds) {
      try {
        final friend = await firestoreService.getUserById(friendId);
        friends.add(friend);
      } catch (e) {
        debugPrint('Ошибка загрузки друга $friendId: $e');
        friends.add(null);
      }
    }
    
    return friends;
  }

  Widget _buildFriendItem(UserModel friend) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showFriendProfile(friend),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: friend.photoUrl != null 
                  ? NetworkImage(friend.photoUrl!) 
                  : null,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: friend.photoUrl == null 
                  ? Text(
                      _getInitials(friend.name),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Рейтинг: ${friend.rating.toStringAsFixed(1)} • ${friend.gamesPlayed} игр',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
          ],
        ),
      ),
    );
  }

  void _showFriendProfile(UserModel friend) async {
    // Загружаем предстоящие игры друга
    final firestoreService = ref.read(firestoreServiceProvider);
    final upcomingGames = await firestoreService.getUpcomingGamesForUser(friend.id);
    
    // Проверяем статус дружбы
    final currentUser = ref.read(currentUserProvider).value;
    bool isFriend = false;
    if (currentUser != null) {
      isFriend = await firestoreService.isFriend(currentUser.id, friend.id);
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(friend.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Аватар
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: friend.photoUrl != null 
                      ? NetworkImage(friend.photoUrl!) 
                      : null,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: friend.photoUrl == null 
                      ? Text(
                          _getInitials(friend.name),
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
              
              // Основная информация (без email для приватности)
              _buildProfileRowInDialog('Рейтинг', friend.rating.toString()),
              _buildProfileRowInDialog('Всего очков', friend.totalScore.toString()),
              _buildProfileRowInDialog('Игр сыграно', friend.gamesPlayed.toString()),
              _buildProfileRowInDialog('Процент побед', '${friend.winRate.toStringAsFixed(1)}%'),
              
              if (friend.bio.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'О себе:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(friend.bio),
              ],
              
              // Предстоящие игры
              if (upcomingGames.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Предстоящие игры:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...upcomingGames.take(3).map((game) => _buildUpcomingGameItemInDialog(game)),
              ],
            ],
          ),
        ),
        actions: [
          // Кнопка добавления/удаления друзей
          if (currentUser != null && currentUser.id != friend.id) ...[
            TextButton.icon(
              onPressed: () => _handleFriendActionInProfile(currentUser!, friend, isFriend),
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

  Widget _buildProfileRowInDialog(String label, String value) {
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

  Widget _buildUpcomingGameItemInDialog(GameRef game) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(); // Закрываем диалог профиля друга
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

  void _handleFriendActionInProfile(UserModel currentUser, UserModel friend, bool isFriend) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      if (isFriend) {
        // Удаляем из друзей
        await firestoreService.removeFriend(currentUser.id, friend.id);
        if (mounted) {
          Navigator.of(context).pop(); // Закрываем диалог
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${friend.name} удален из друзей'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } else {
        // Добавляем в друзья
        await firestoreService.addFriend(currentUser.id, friend.id);
        if (mounted) {
          Navigator.of(context).pop(); // Закрываем диалог
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${friend.name} добавлен в друзья'),
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