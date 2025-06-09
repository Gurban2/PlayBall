import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart'; 
import '../../../features/auth/domain/entities/user_model.dart';
import '../../../core/providers.dart';
import '../../../core/errors/error_handler.dart';

class PlayerProfileDialog {
  static Future<void> show(
    BuildContext context, 
    WidgetRef ref, 
    String playerId, {
    String? playerName,
  }) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final userService = ref.read(userServiceProvider);
      final player = await userService.getUserById(playerId);
      
      if (player == null) {
        if (context.mounted) {
          ErrorHandler.showError(context, 'Игрок не найден');
        }
        return;
      }

      // Проверяем статус дружбы
      String friendshipStatus = 'none';
      bool isOwnProfile = currentUser.id == player.id;
      
      if (!isOwnProfile) {
        friendshipStatus = await userService.getFriendshipStatus(currentUser.id, player.id);
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => _PlayerProfileDialogWidget(
            player: player,
            currentUser: currentUser,
            friendshipStatus: friendshipStatus,
            isOwnProfile: isOwnProfile,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }
}

class _PlayerProfileDialogWidget extends ConsumerStatefulWidget {
  final UserModel player;
  final UserModel currentUser;
  final String friendshipStatus;
  final bool isOwnProfile;

  const _PlayerProfileDialogWidget({
    required this.player,
    required this.currentUser,
    required this.friendshipStatus,
    required this.isOwnProfile,
  });

  @override
  ConsumerState<_PlayerProfileDialogWidget> createState() => _PlayerProfileDialogWidgetState();
}

class _PlayerProfileDialogWidgetState extends ConsumerState<_PlayerProfileDialogWidget> {
  late String _friendshipStatus;

  @override
  void initState() {
    super.initState();
    _friendshipStatus = widget.friendshipStatus;
  }

  Future<void> _handleFriendAction() async {
    try {
      final userService = ref.read(userServiceProvider);

      switch (_friendshipStatus) {
        case 'friends':
          // Удаляем из друзей
          await userService.removeFriend(widget.currentUser.id, widget.player.id);
          setState(() {
            _friendshipStatus = 'none';
          });
          
          if (mounted) {
            ErrorHandler.showSuccess(context, '${widget.player.name} удален из друзей');
          }
          break;

        case 'none':
          // Отправляем запрос дружбы
          await userService.sendFriendRequest(widget.currentUser.id, widget.player.id);
          setState(() {
            _friendshipStatus = 'request_sent';
          });
          
          if (mounted) {
            ErrorHandler.showSuccess(context, 'Запрос дружбы отправлен ${widget.player.name}');
          }
          break;

        case 'request_sent':
          // Отменяем запрос дружбы
          await userService.cancelFriendRequest(widget.currentUser.id, widget.player.id);
          setState(() {
            _friendshipStatus = 'none';
          });
          
          if (mounted) {
            ErrorHandler.showWarning(context, 'Запрос дружбы отменен');
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
        title: Text('Запрос дружбы от ${widget.player.name}'),
        content: Text('${widget.player.name} хочет добавить вас в друзья'),
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
        final requests = await userService.getIncomingFriendRequests(widget.currentUser.id);
        final request = requests.firstWhere(
          (r) => r.fromUserId == widget.player.id,
          orElse: () => throw Exception('Запрос не найден'),
        );

        if (result) {
          // Принимаем запрос
          await userService.acceptFriendRequest(request.id);
          setState(() {
            _friendshipStatus = 'friends';
          });
          
          if (mounted) {
            ErrorHandler.showSuccess(context, '${widget.player.name} добавлен в друзья');
          }
        } else {
          // Отклоняем запрос
          await userService.declineFriendRequest(request.id);
          setState(() {
            _friendshipStatus = 'none';
          });
          
          if (mounted) {
            ErrorHandler.showWarning(context, 'Запрос дружбы отклонен');
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

  Color _getFriendButtonColor() {
    switch (_friendshipStatus) {
      case 'friends':
        return AppColors.error;
      case 'request_sent':
        return AppColors.warning;
      case 'request_received':
        return AppColors.success;
      case 'none':
      default:
        return AppColors.primary;
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

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  void _navigateToTeam() {
    if (widget.player.teamId == null || widget.player.teamName == null) {
      ErrorHandler.showError(context, 'Информация о команде недоступна');
      return;
    }

    // Закрываем диалог
    Navigator.of(context).pop();

    // Все пользователи идут на просмотр команды
    // Там уже есть логика для подачи заявок и выхода из команды
    context.push('/team-view/${widget.player.teamId}?teamName=${Uri.encodeComponent(widget.player.teamName!)}');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок с аватаром
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: widget.player.photoUrl != null
                        ? NetworkImage(widget.player.photoUrl!)
                        : null,
                    child: widget.player.photoUrl == null
                        ? Text(
                            _getInitials(widget.player.name),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                          widget.player.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: _getStatusColor(widget.player.status),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.player.statusDisplayName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
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
            
            // Контент
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Статистика
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem('Игр', widget.player.gamesPlayed.toString()),
                      ),
                      Expanded(
                        child: _buildStatItem('Побед', widget.player.wins.toString()),
                      ),
                      Expanded(
                        child: _buildStatItem('Винрейт', '${widget.player.winRate.toStringAsFixed(0)}%'),
                      ),
                      Expanded(
                        child: _buildStatItem('Очки', widget.player.totalScore.toString()),
                      ),
                    ],
                  ),
                  
                  // Команда
                  if (widget.player.teamName != null) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _navigateToTeam,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.groups,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.player.teamName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            if (widget.player.isTeamCaptain)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(4),
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
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.secondary,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Описание
                  if (widget.player.bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'О себе:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.player.bio,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Кнопка добавления в друзья (только если это не свой профиль)
        if (!widget.isOwnProfile) ...[
          TextButton.icon(
            onPressed: _handleFriendAction,
            icon: Icon(
              _getFriendButtonIcon(),
              size: 18,
            ),
            label: Text(_getFriendButtonText()),
            style: TextButton.styleFrom(
              foregroundColor: _getFriendButtonColor(),
            ),
          ),
        ],
        
        // Кнопка "Полный профиль"
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/player/${widget.player.id}?playerName=${Uri.encodeComponent(widget.player.name)}');
          },
          child: const Text('Полный профиль'),
        ),
        
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
} 