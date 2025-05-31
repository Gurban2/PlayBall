import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';

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
  bool _isFriend = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    try {
      print('🔄 Начинаем загрузку данных игрока: ${widget.playerId}');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userService = ref.read(userServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;

      if (currentUser == null) {
        print('❌ Текущий пользователь не найден');
        setState(() {
          _error = 'Пользователь не найден';
          _isLoading = false;
        });
        return;
      }

      print('✅ Текущий пользователь: ${currentUser.name}');

      // Получаем данные игрока
      final player = await userService.getUserById(widget.playerId);
      if (player == null) {
        print('❌ Игрок с ID ${widget.playerId} не найден');
        setState(() {
          _error = 'Игрок не найден';
          _isLoading = false;
        });
        return;
      }

      print('✅ Данные игрока загружены: ${player.name}');

      // Проверяем, является ли игрок другом
      final friends = await userService.getFriends(currentUser.id);
      final isFriend = friends.any((friend) => friend.id == widget.playerId);

      print('👥 Статус дружбы: $isFriend');

      if (mounted) {
        setState(() {
          _player = player;
          _isFriend = isFriend;
          _isLoading = false;
        });
        print('✅ Состояние обновлено, загрузка завершена');
      }
    } catch (e) {
      print('❌ Ошибка загрузки: $e');
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFriend() async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null || _player == null) return;

      final userService = ref.read(userServiceProvider);

      if (_isFriend) {
        await userService.removeFriend(currentUser.id, _player!.id);
        setState(() {
          _isFriend = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_player!.name} удален из друзей'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await userService.addFriend(currentUser.id, _player!.id);
        setState(() {
          _isFriend = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_player!.name} добавлен в друзья'),
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
    final currentUser = ref.read(currentUserProvider).value;
    final isSelf = currentUser?.id == widget.playerId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.playerName ?? _player?.name ?? 'Профиль игрока'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!isSelf && _player != null) 
            IconButton(
              icon: Icon(_isFriend ? Icons.person_remove : Icons.person_add),
              onPressed: _toggleFriend,
              tooltip: _isFriend ? 'Удалить из друзей' : 'Добавить в друзья',
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
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
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
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.secondary.withOpacity(0.3),
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
                                                ],
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

                                // Рейтинг и баллы
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(Icons.star, color: AppColors.warning, size: 28),
                                            const SizedBox(height: 8),
                                            Text(
                                              _player!.rating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              'Рейтинг',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
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
                                    ),
                                  ],
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
                                          color: AppColors.warning.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: AppColors.warning.withOpacity(0.3),
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
                        ],
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
        color: color.withOpacity(0.1),
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
    return '';
  }
} 