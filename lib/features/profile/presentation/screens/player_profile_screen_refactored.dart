import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/providers.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../widgets/player_profile_card.dart';
import '../widgets/player_statistics_card.dart';
import '../widgets/player_friends_card.dart';
import '../widgets/player_games_history_card.dart';

class PlayerProfileScreenRefactored extends ConsumerStatefulWidget {
  final String playerId;
  final String? playerName;

  const PlayerProfileScreenRefactored({
    super.key,
    required this.playerId,
    this.playerName,
  });

  @override
  ConsumerState<PlayerProfileScreenRefactored> createState() => 
      _PlayerProfileScreenRefactoredState();
}

class _PlayerProfileScreenRefactoredState 
    extends ConsumerState<PlayerProfileScreenRefactored> {
  
  UserModel? _player;
  String _friendshipStatus = 'none'; // 'none', 'friends', 'request_sent', 'request_received', 'self'
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isSelf = currentUser?.id == widget.playerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _player?.name ?? widget.playerName ?? 'Профиль игрока',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!isSelf && _player != null && currentUser != null)
            IconButton(
              onPressed: _handleFriendAction,
              icon: Icon(_getFriendButtonIcon()),
              tooltip: _getFriendButtonText(),
            ),
        ],
      ),
      body: _buildBody(isSelf),
    );
  }

  Widget _buildBody(bool isSelf) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_player == null) {
      return const Center(
        child: Text('Игрок не найден'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlayerData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Основная карточка профиля
            PlayerProfileCard(
              player: _player!,
              isSelf: isSelf,
              onTeamTap: () => _navigateToTeam(_player!),
            ),
            
            const SizedBox(height: 16),
            
            // Статистика игрока
            PlayerStatisticsCard(player: _player!),
            
            const SizedBox(height: 16),
            
            // История игр
            PlayerGamesHistoryCard(player: _player!),
            
            const SizedBox(height: 16),
            
            // Друзья
            PlayerFriendsCard(
              player: _player!,
              loadFriends: _loadPlayerFriends,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
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
    );
  }

  // Методы бизнес-логики
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

      final userService = ref.read(userServiceProvider);
      final player = await userService.getUserById(widget.playerId);
      
      if (player == null) {
        throw Exception('Игрок не найден');
      }

      // Проверяем статус дружбы
      final friendshipStatus = await userService.getFriendshipStatus(
        currentUser.id, 
        widget.playerId
      );

      if (mounted) {
        setState(() {
          _player = player;
          _friendshipStatus = friendshipStatus;
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
          
          _showSnackBar('${_player!.name} удален из друзей', AppColors.success);
          break;

        case 'none':
          // Отправляем запрос дружбы
          await userService.sendFriendRequest(currentUser.id, _player!.id);
          setState(() {
            _friendshipStatus = 'request_sent';
          });
          
          _showSnackBar('Запрос дружбы отправлен ${_player!.name}', AppColors.success);
          break;

        case 'request_sent':
          // Отменяем запрос дружбы
          await userService.cancelFriendRequest(currentUser.id, _player!.id);
          setState(() {
            _friendshipStatus = 'none';
          });
          
          _showSnackBar('Запрос дружбы отменен', AppColors.warning);
          break;

        case 'request_received':
          // Показываем диалог принятия/отклонения
          _showFriendRequestDialog();
          break;
      }
    } catch (e) {
      _showSnackBar('Ошибка: ${e.toString()}', AppColors.error);
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
          _showSnackBar('${_player!.name} добавлен в друзья', AppColors.success);
        } else {
          // Отклоняем запрос
          await userService.declineFriendRequest(request.id);
          setState(() {
            _friendshipStatus = 'none';
          });
          _showSnackBar('Запрос от ${_player!.name} отклонен', AppColors.warning);
        }
      } catch (e) {
        _showSnackBar('Ошибка: ${e.toString()}', AppColors.error);
      }
    }
  }

  void _navigateToTeam(UserModel player) {
    if (player.teamId == null || player.teamName == null) {
      _showSnackBar('Информация о команде недоступна', AppColors.error);
      return;
    }

    context.push('/team-view/${player.teamId}?teamName=${Uri.encodeComponent(player.teamName!)}');
  }

  // Вспомогательные методы UI
  IconData _getFriendButtonIcon() {
    switch (_friendshipStatus) {
      case 'friends':
        return Icons.person_remove;
      case 'request_sent':
        return Icons.hourglass_empty;
      case 'request_received':
        return Icons.person_add_alt_1;
      default:
        return Icons.person_add;
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
      default:
        return 'Добавить в друзья';
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }
} 