import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/providers.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../widgets/player_profile_dialog.dart';

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
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            toolbarHeight: 42.0,
            actions: [
              // Иконка запросов дружбы
              FutureBuilder<int>(
                future: _getIncomingRequestsCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        iconSize: 24.0,
                        onPressed: () => context.push('/friend-requests'),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              
              // Иконка приглашений в команды
              FutureBuilder<int>(
                future: _getIncomingTeamInvitationsCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.groups),
                        iconSize: 24.0,
                        onPressed: () => context.push('/team-invitations'),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // Иконка заявок в команды (только для владельцев команд)
              Consumer(
                builder: (context, ref, child) {
                  final user = ref.watch(currentUserProvider).value;
                  if (user?.teamId != null && user?.isTeamCaptain == true) {
                    return FutureBuilder<int>(
                      future: _getIncomingTeamApplicationsCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.assignment),
                              iconSize: 24.0,
                              onPressed: () => context.push('/team-applications'),
                            ),
                            if (count > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              IconButton(
                icon: const Icon(Icons.logout),
                iconSize: 24.0,
                onPressed: () => _logout(context, ref),
              ),
            ],
            bottom: TabBar(
              controller: _tabController!,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorWeight: 3.0,
              tabs: const [
                Tab(
                  height: 48.0,
                  icon: Icon(Icons.person, size: 24),
                ),
              ],
            ),
          ),
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
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
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
                              // Информация о команде
                              if (user.teamName != null) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _navigateToTeamMembers(user),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
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
                                    user.bio.isEmpty
                                        ? 'Расскажите о себе...'
                                        : user.bio,
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
                            '${user.winRate.toStringAsFixed(0)}%',
                            'Винрейт',
                            Icons.trending_up,
                          ),
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

            const SizedBox(height: AppSizes.largeSpace),

            // Dashboard для организатора
            if (user.role == UserRole.organizer || user.role == UserRole.admin) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => context.push(AppRoutes.organizerDashboard),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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

            // Секция друзей
            FutureBuilder<List<UserModel>>(
              future: _loadFriends(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }

                final friends = snapshot.data ?? [];

                if (friends.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Друзья (${friends.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...friends
                            .take(5)
                            .map((friend) => _buildFriendItem(friend)),
                        if (friends.length > 5) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () => _showAllFriends(friends),
                              child: Text(
                                'Показать всех друзей (${friends.length})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ] else if (friends.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () => _showAllFriends(friends),
                              child: const Text(
                                'Управление друзьями',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSizes.largeSpace),
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

  Widget _buildCompactStat(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
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

  Future<List<UserModel>> _loadFriends() async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return [];

      final userService = ref.read(userServiceProvider);
      return await userService.getFriends(user.id);
    } catch (e) {
      debugPrint('Ошибка загрузки друзей: $e');
      return [];
    }
  }

  Widget _buildFriendItem(UserModel friend) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          PlayerProfileDialog.show(context, ref, friend.id, playerName: friend.name);
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  friend.photoUrl != null ? NetworkImage(friend.photoUrl!) : null,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: friend.photoUrl == null
                  ? Text(
                      _getInitials(friend.name),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                  if (friend.teamName != null)
                    Text(
                      friend.teamName!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${friend.gamesPlayed}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllFriends(List<UserModel> friends) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Друзья (${friends.length})'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: friends.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Пока нет друзей',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Добавьте друзей, чтобы играть вместе!',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          PlayerProfileDialog.show(context, ref, friend.id, playerName: friend.name);
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: friend.photoUrl != null
                                  ? NetworkImage(friend.photoUrl!)
                                  : null,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
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
                                  Row(
                                    children: [
                                      if (friend.teamName != null) ...[
                                        Icon(
                                          Icons.groups,
                                          size: 12,
                                          color: AppColors.secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          friend.teamName!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        '${friend.gamesPlayed} игр',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'remove') {
                                  _removeFriend(friend);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_remove, size: 16),
                                      SizedBox(width: 8),
                                      Text('Удалить из друзей'),
                                    ],
                                  ),
                                ),
                              ],
                              child: const Icon(
                                Icons.more_vert,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  void _removeFriend(UserModel friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить из друзей'),
        content: Text('Удалить ${friend.name} из списка друзей?'),
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
        final user = ref.read(currentUserProvider).value;
        if (user == null) return;

        final userService = ref.read(userServiceProvider);
        await userService.removeFriend(user.id, friend.id);

        if (mounted) {
          Navigator.of(context).pop(); // Закрываем диалог друзей
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${friend.name} удален из друзей'),
              backgroundColor: AppColors.success,
            ),
          );

          // Обновляем профиль
          setState(() {});
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
      context.push('/team-members/${user.teamId}?teamName=${Uri.encodeComponent(user.teamName!)}');
    } else {
      // Обычные пользователи идут на просмотр команды
      context.push('/team-view/${user.teamId}?teamName=${Uri.encodeComponent(user.teamName!)}');
    }
  }

  Future<int> _getIncomingRequestsCount() async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return 0;

      final userService = ref.read(userServiceProvider);
      return await userService.getIncomingRequestsCount(user.id);
    } catch (e) {
      debugPrint('Ошибка загрузки количества входящих запросов: $e');
      return 0;
    }
  }

  Future<int> _getIncomingTeamInvitationsCount() async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return 0;

      final teamService = ref.read(teamServiceProvider);
      return await teamService.getIncomingTeamInvitationsCount(user.id);
    } catch (e) {
      debugPrint('Ошибка загрузки количества входящих приглашений в команды: $e');
      return 0;
    }
  }

  Future<int> _getIncomingTeamApplicationsCount() async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return 0;

      final teamService = ref.read(teamServiceProvider);
      return await teamService.getIncomingTeamApplicationsCount(user.id);
    } catch (e) {
      debugPrint('Ошибка загрузки количества входящих заявок в команды: $e');
      return 0;
    }
  }
}
