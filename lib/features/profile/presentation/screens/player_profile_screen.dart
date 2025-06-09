import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../features/auth/domain/entities/user_model.dart';
import '../../../../core/providers.dart';
import '../../../../shared/widgets/dialogs/player_profile_dialog.dart';

class PlayerProfileScreen extends ConsumerStatefulWidget {
  final String playerId;
  final String? playerName;

  const PlayerProfileScreen({
    super.key,
    required this.playerId,
    this.playerName,
  });

  @override
  ConsumerState<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen> {
  UserModel? _player;

  String _friendshipStatus = 'none'; // 'none', 'friends', 'request_sent', 'request_received', 'self'
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('🔍 Загружаем данные игрока: ${widget.playerId}');
      
      final userService = ref.read(userServiceProvider);
      final player = await userService.getUserById(widget.playerId);
      
      if (player == null) {
        throw Exception('Игрок не найден');
      }

      debugPrint('👤 Игрок найден: ${player.name}');

      // Проверяем статус дружбы
      final friendshipStatus = await userService.getFriendshipStatus(currentUser.id, widget.playerId);

      debugPrint('👥 Статус дружбы: $friendshipStatus');

      if (mounted) {
        setState(() {
          _player = player;
          _friendshipStatus = friendshipStatus;

          _isLoading = false;
        });
        debugPrint('✅ Состояние обновлено, загрузка завершена');
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки: $e');
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFriendAction() async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null || _player == null) return;

      final userService = ref.read(userServiceProvider);

      switch (_friendshipStatus) {
        case 'friends':
          // Удаляем из друзей
          await userService.removeFriend(currentUser.id, _player!.id);
          setState(() {
            _friendshipStatus = 'none';

          });
          
          if (mounted) {
            ErrorHandler.friendRemoved(context, _player!.name);
          }
          break;

        case 'none':
          // Отправляем запрос дружбы
          await userService.sendFriendRequest(currentUser.id, _player!.id);
          setState(() {
            _friendshipStatus = 'request_sent';
          });
          
          if (mounted) {
            ErrorHandler.friendRequestSent(context, _player!.name);
          }
          break;

        case 'request_sent':
          // Отменяем запрос дружбы
          await userService.cancelFriendRequest(currentUser.id, _player!.id);
          setState(() {
            _friendshipStatus = 'none';
          });
          
          if (mounted) {
            ErrorHandler.friendRequestCancelled(context, _player!.name);
          }
          break;

        case 'request_received':
          // Показываем диалог принятия/отклонения
          _showFriendRequestDialog();
          break;
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  void _showFriendRequestDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Запрос дружбы от ${_player!.name}'),
        content: Text('${_player!.name} хочет добавить вас в друзья'),
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
        
        // Находим запрос дружбы
        final requests = await userService.getIncomingFriendRequests(
          ref.read(currentUserProvider).value!.id
        );
        final request = requests.firstWhere(
          (r) => r.fromUserId == _player!.id,
          orElse: () => throw Exception('Запрос не найден'),
        );

        if (result) {
          // Принимаем запрос
          await userService.acceptFriendRequest(request.id);
          setState(() {
            _friendshipStatus = 'friends';

          });
          
          if (mounted) {
            ErrorHandler.friendRequestAccepted(context, _player!.name);
          }
        } else {
          // Отклоняем запрос
          await userService.declineFriendRequest(request.id);
          setState(() {
            _friendshipStatus = 'none';
          });
          
          if (mounted) {
            ErrorHandler.friendRequestRejected(context, _player!.name);
          }
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }
  }

  String _getFriendButtonText() {
    switch (_friendshipStatus) {
      case 'friends':
        return 'Удалить из друзей';
      case 'request_sent':
        return 'Отменить запрос';
      case 'request_received':
        return 'Ответить на запрос';
      case 'none':
      default:
        return 'Добавить в друзья';
    }
  }

  IconData _getFriendButtonIcon() {
    switch (_friendshipStatus) {
      case 'friends':
        return Icons.person_remove;
      case 'request_sent':
        return Icons.cancel;
      case 'request_received':
        return Icons.person_add_alt;
      case 'none':
      default:
        return Icons.person_add;
    }
  }



  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(currentUserProvider).value;
    final isSelf = currentUser?.id == widget.playerId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.playerName ?? _player?.name ?? 'Профиль игрока',
          style: AppTextStyles.appBarTitle,
        ),
        backgroundColor: AppColors.darkGrey,
        foregroundColor: Colors.white,
        actions: [
          if (!isSelf && _player != null) 
            IconButton(
              icon: Icon(_getFriendButtonIcon()),
              onPressed: _handleFriendAction,
              tooltip: _getFriendButtonText(),
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
                        onPressed: _loadPlayerData,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlayerData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
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
                                      radius: 50,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      backgroundImage: _player!.photoUrl != null
                                          ? NetworkImage(_player!.photoUrl!)
                                          : null,
                                      child: _player!.photoUrl == null
                                          ? Text(
                                              _getInitials(_player!.name),
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _player!.name,
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (isSelf)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withValues(alpha: 0.1),
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
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          
                                          // Статус
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 12,
                                                color: _getStatusColor(_player!.status),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _player!.statusDisplayName,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: _getStatusColor(_player!.status),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          // Информация о команде
                                          if (_player!.teamName != null) ...[
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () => _navigateToTeam(_player!),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.secondary.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.groups,
                                                      color: AppColors.secondary,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        _player!.teamName!,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.secondary,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (_player!.isTeamCaptain) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.warning,
                                                          borderRadius: BorderRadius.circular(6),
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
                                                    const SizedBox(width: 6),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      color: AppColors.secondary,
                                                      size: 12,
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

                                const SizedBox(height: 20),

                                // Описание игрока
                                if (_player!.bio.isNotEmpty) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _player!.bio,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.text,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Основная статистика
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Flexible(
                                      child: _buildStatCard(
                                        _player!.gamesPlayed.toString(),
                                        'Игр',
                                        Icons.sports_volleyball,
                                        AppColors.primary,
                                      ),
                                    ),
                                    Flexible(
                                      child: _buildStatCard(
                                        _player!.wins.toString(),
                                        'Побед',
                                        Icons.emoji_events,
                                        AppColors.success,
                                      ),
                                    ),
                                    Flexible(
                                      child: _buildStatCard(
                                        _player!.losses.toString(),
                                        'Поражений',
                                        Icons.close,
                                        AppColors.error,
                                      ),
                                    ),
                                    Flexible(
                                      child: _buildStatCard(
                                        '${_player!.winRate.toStringAsFixed(0)}%',
                                        'Винрейт',
                                        Icons.trending_up,
                                        AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Только баллы
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.score, color: AppColors.primary, size: 28),
                                      const SizedBox(height: 8),
                                      Text(
                                        _player!.totalScore.toString(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Баллы',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Последние игры
                        if (_player!.recentGames.isNotEmpty) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.history, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Последние игры',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ..._player!.recentGames.take(3).map((game) => _buildGameItem(game)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Достижения
                        if (_player!.achievements.isNotEmpty) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.military_tech, color: AppColors.warning),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Достижения',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _player!.achievements.map((achievement) => 
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: AppColors.warning.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          achievement,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Секция друзей
                        FutureBuilder<List<UserModel>>(
                          future: _loadPlayerFriends(),
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
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
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
      ),
    );
  }

  Widget _buildGameItem(GameRef game) {
    final isWin = game.result == 'win';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isWin ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      game.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${game.date.day}.${game.date.month}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isWin ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isWin ? 'Победа' : 'Поражение',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  Future<List<UserModel>> _loadPlayerFriends() async {
    try {
      if (_player == null) return [];

      final userService = ref.read(userServiceProvider);
      return await userService.getFriends(_player!.id);
    } catch (e) {
      debugPrint('Ошибка загрузки друзей игрока: $e');
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
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Игр: ${friend.gamesPlayed}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Винрейт: ${friend.winRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
            Expanded(
              child: Text(
                'Друзья ${_player!.name} (${friends.length})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                                    Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Игр: ${friend.gamesPlayed}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Винрейт: ${friend.winRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                                ],
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

  void _navigateToTeam(UserModel player) {
    if (player.teamId == null || player.teamName == null) {
      ErrorHandler.showError(context, 'Информация о команде недоступна');
      return;
    }

    // Все пользователи идут на просмотр команды
    // Там уже есть логика для подачи заявок и выхода из команды
    context.push('/team-view/${player.teamId}?teamName=${Uri.encodeComponent(player.teamName!)}');
  }
} 