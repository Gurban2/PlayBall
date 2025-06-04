import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../widgets/player_friends_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;
  List<GameRef> _upcomingGames = [];
  bool _isLoadingGames = false;

  TabController? _tabController;
  UserRole? _lastUserRole;

  @override
  void initState() {
    super.initState();
    _loadUpcomingGames();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _updateTabController(UserRole? userRole) {
    final tabCount = 1; // Всегда только одна вкладка - профиль

    if (_tabController == null || _lastUserRole != userRole) {
      _tabController?.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
      _lastUserRole = userRole;
    }
  }

  Future<void> _loadUpcomingGames() async {
    setState(() {
      _isLoadingGames = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        // Пока оставляем пустой список, метод getUpcomingGamesForUser можно реализовать позже
        setState(() {
          _upcomingGames = [];
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

  Future<List<UserModel>> _loadFriends(String userId) async {
    try {
      final userService = ref.read(userServiceProvider);
      return await userService.getFriends(userId);
    } catch (e) {
      debugPrint('Ошибка загрузки друзей: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
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
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Пользователь не найден')),
          );
        }

        // Обновляем TabController для текущего пользователя
        _updateTabController(user.role);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: TabBarView(
            controller: _tabController!,
            children: [
              // Вкладка профиля
              _buildProfileTab(user),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(UserModel user) {
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(currentUserProvider),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Основная карточка профиля
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // Аватар и базовая информация
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(
                                  _getInitials(user.name),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      user.name,
                                      style: AppTextStyles.heading2,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.logout),
                                    color: AppColors.error,
                                    onPressed: () => _logout(context, ref),
                                    iconSize: 20,
                                  ),
                                ],
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
                              // Информация о команде
                              if (user.teamName != null) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _navigateToTeamMembers(user),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal:4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.secondary
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.groups,
                                          color: AppColors.secondary,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            user.teamName!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.secondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (user.isTeamCaptain) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.warning,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'К',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: AppColors.secondary,
                                          size: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Описание игрока
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
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
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : Text(
                                    user.bio.isEmpty
                                        ? 'Расскажите о себе...'
                                        : user.bio,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: user.bio.isEmpty
                                          ? AppColors.textSecondary
                                          : AppColors.text,
                                    ),
                                  ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isEditingBio ? Icons.check : Icons.edit,
                              size: 14,
                            ),
                            onPressed: () => _toggleBioEdit(user),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Основная статистика в компактном виде
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Flexible(
                          child: _buildCompactStat(
                            user.gamesPlayed.toString(),
                            'Игр',
                            Icons.sports_volleyball,
                          ),
                        ),
                        Flexible(
                          child: _buildCompactStat(
                            user.wins.toString(),
                            'Побед',
                            Icons.emoji_events,
                          ),
                        ),
                        Flexible(
                          child: _buildCompactStat(
                            user.losses.toString(),
                            'Поражений',
                            Icons.close,
                          ),
                        ),
                        Flexible(
                          child: _buildCompactStat(
                            user.totalScore.toString(),
                            'Очки',
                            Icons.star_rate,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Рейтинг и баллы
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star,
                                    color: AppColors.warning, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  user.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star_rate,
                                    color: AppColors.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  user.totalScore.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
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

            const SizedBox(height: 8),

            // Кнопка "Расписание игр" для всех пользователей
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => context.push(AppRoutes.schedule),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.schedule,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Расписание игр',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Просмотр всех игр и планирование времени',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textSecondary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Dashboard для организатора
            if (user.role == UserRole.organizer ||
                user.role == UserRole.admin) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => context.push(AppRoutes.organizerDashboard),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.dashboard,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.role == UserRole.admin
                                    ? 'Admin Dashboard'
                                    : 'Dashboard организатора',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.role == UserRole.admin
                                    ? 'Управление системой, пользователями'
                                    : 'Статистика игр, управление командами',
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
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.largeSpace),
            ],

            // Карточка друзей
            PlayerFriendsCard(
              player: user,
              loadFriends: () => _loadFriends(user.id),
            ),
          ],
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
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'bio': _bioController.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      ref.invalidate(currentUserProvider);

      if (mounted) {
        setState(() {
          _isEditingBio = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Описание обновлено'),
            backgroundColor: AppColors.success,
          ),
        );
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

  Widget _buildCompactStat(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
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

  void _navigateToTeamMembers(UserModel user) async {
    if (user.teamId == null || user.teamName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Информация о команде недоступна'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Проверяем роль пользователя
    if (user.role == UserRole.organizer || user.role == UserRole.admin) {
      // Организаторы и админы идут на управление командой
      context.push(
          '/team-members/${user.teamId}?teamName=${Uri.encodeComponent(user.teamName!)}');
    } else {
      // Обычные пользователи идут на просмотр команды
      context.push(
          '/team-view/${user.teamId}?teamName=${Uri.encodeComponent(user.teamName!)}');
    }
  }
}
