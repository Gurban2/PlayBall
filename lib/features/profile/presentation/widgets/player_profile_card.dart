import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../auth/domain/entities/user_model.dart';

class PlayerProfileCard extends StatelessWidget {
  final UserModel player;
  final bool isSelf;
  final VoidCallback? onTeamTap;

  const PlayerProfileCard({
    super.key,
    required this.player,
    required this.isSelf,
    this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                _buildAvatar(),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildPlayerInfo(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Дополнительная информация
            _buildAdditionalInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      backgroundImage: player.photoUrl != null
          ? NetworkImage(player.photoUrl!)
          : null,
      child: player.photoUrl == null
          ? Text(
              _getInitials(player.name),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }

  Widget _buildPlayerInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Имя и статус "Это вы"
        Row(
          children: [
            Expanded(
              child: Text(
                player.name,
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
        
        // Статус активности
        _PlayerStatusWidget(player: player),
        
        // Информация о команде
        if (player.teamName != null) ...[
          const SizedBox(height: 8),
          _TeamInfoWidget(
            player: player,
            onTap: onTeamTap,
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoItem(
              icon: Icons.sports_volleyball,
              label: 'Роль',
              value: _getRoleDisplayName(player.role),
              color: AppColors.primary,
            ),
          ),
          if (player.email.isNotEmpty) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _InfoItem(
                icon: Icons.email,
                label: 'Email',
                value: player.email,
                color: AppColors.secondary,
              ),
            ),
          ],
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
    return '?';
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Игрок';
      case UserRole.organizer:
        return 'Организатор';
      case UserRole.admin:
        return 'Администратор';
    }
  }
}

// Виджет для отображения статуса игрока
class _PlayerStatusWidget extends StatelessWidget {
  final UserModel player;

  const _PlayerStatusWidget({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 12,
          color: _getStatusColor(player.status),
        ),
        const SizedBox(width: 4),
        Text(
          player.statusDisplayName,
          style: TextStyle(
            fontSize: 14,
            color: _getStatusColor(player.status),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
}

// Виджет для отображения информации о команде
class _TeamInfoWidget extends StatelessWidget {
  final UserModel player;
  final VoidCallback? onTap;

  const _TeamInfoWidget({
    required this.player,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                player.teamName!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (player.isTeamCaptain) ...[
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
    );
  }
}

// Виджет для отображения информационных элементов
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
} 