import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../../core/providers.dart';
import '../../../features/auth/domain/entities/user_model.dart';
import '../dialogs/player_profile_dialog.dart';

class TeamMemberCard extends ConsumerStatefulWidget {
  final UserModel member;
  final bool showFriendButton;
  final bool isCompact;

  const TeamMemberCard({
    super.key,
    required this.member,
    this.showFriendButton = true,
    this.isCompact = false,
  });

  @override
  ConsumerState<TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends ConsumerState<TeamMemberCard> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(currentUserProvider).value;
    final isOwnProfile = currentUser?.id == widget.member.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: widget.isCompact ? 18 : 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: widget.member.photoUrl != null 
              ? NetworkImage(widget.member.photoUrl!) 
              : null,
          child: widget.member.photoUrl == null 
              ? Text(
                  _getInitials(widget.member.name), 
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: widget.isCompact ? 12 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          widget.member.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: widget.isCompact ? 14 : 16,
          ),
        ),
        subtitle: widget.isCompact 
            ? null 
            : Text('${widget.member.gamesPlayed} игр'),
        onTap: () => PlayerProfileDialog.show(
          context, 
          ref, 
          widget.member.id, 
          playerName: widget.member.name,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка добавления в друзья (только если это не свой профиль)
            if (widget.showFriendButton && !isOwnProfile && currentUser != null) ...[
              FutureBuilder<String>(
                future: ref.read(userServiceProvider).getFriendshipStatus(
                  currentUser!.id, 
                  widget.member.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      width: widget.isCompact ? 12 : 16,
                      height: widget.isCompact ? 12 : 16,
                      child: CircularProgressIndicator(
                        strokeWidth: widget.isCompact ? 1.5 : 2,
                      ),
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
                    onPressed: () => _handleFriendAction(friendshipStatus),
                    icon: Icon(
                      icon, 
                      size: widget.isCompact ? 16 : 18,
                    ),
                    color: color,
                    tooltip: tooltip,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: widget.isCompact ? 28 : 32,
                      minHeight: widget.isCompact ? 28 : 32,
                    ),
                  );
                },
              ),
              SizedBox(width: widget.isCompact ? 2 : 4),
            ],
            Icon(
              Icons.arrow_forward_ios,
              size: widget.isCompact ? 12 : 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _handleFriendAction(String friendshipStatus) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final userService = ref.read(userServiceProvider);

      switch (friendshipStatus) {
        case 'friends':
          await userService.removeFriend(currentUser.id, widget.member.id);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.member.name} удален из друзей'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          break;

        case 'none':
          await userService.sendFriendRequest(currentUser.id, widget.member.id);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Запрос дружбы отправлен ${widget.member.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          break;

        case 'request_sent':
          await userService.cancelFriendRequest(currentUser.id, widget.member.id);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Запрос дружбы ${widget.member.name} отменен'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          break;

        case 'request_received':
          _showFriendRequestDialog();
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

  void _showFriendRequestDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Запрос дружбы от ${widget.member.name}'),
        content: Text('${widget.member.name} хочет добавить вас в друзья'),
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
        
        final requests = await userService.getIncomingFriendRequests(currentUser.id);
        final request = requests.firstWhere(
          (r) => r.fromUserId == widget.member.id,
          orElse: () => throw Exception('Запрос не найден'),
        );

        if (result) {
          await userService.acceptFriendRequest(request.id);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.member.name} добавлен в друзья'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          await userService.declineFriendRequest(request.id);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Запрос дружбы ${widget.member.name} отклонен'),
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
} 