import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class PlayerCard extends StatelessWidget {
  final UserModel player;
  final VoidCallback? onTap;
  final bool showTeamInfo;
  final bool compact;

  const PlayerCard({
    super.key,
    required this.player,
    this.onTap,
    this.showTeamInfo = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.smallSpace),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: compact 
              ? const EdgeInsets.all(12) 
              : AppSizes.cardPadding,
          child: Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: compact ? 20 : 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: player.photoUrl != null 
                    ? NetworkImage(player.photoUrl!) 
                    : null,
                child: player.photoUrl == null 
                    ? Text(
                        _getInitials(player.name),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: compact ? 14 : 16,
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(width: AppSizes.mediumSpace),
              
              // Информация об игроке
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Имя и роль
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: compact ? 14 : 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.role == UserRole.organizer)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.organizerRole,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Орг',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Статистика
                    if (!compact) ...[
                      Text(
                        'Рейтинг: ${player.rating.toStringAsFixed(1)} • ${player.gamesPlayed} игр',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      
                      // Информация о команде
                      if (showTeamInfo && player.teamName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.groups,
                              size: 12,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                player.teamName!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (player.isTeamCaptain)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(4),
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
                        ),
                      ],
                    ] else ...[
                      // Компактная версия
                      Row(
                        children: [
                          Text(
                            '${player.rating.toStringAsFixed(1)}★',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (showTeamInfo && player.teamName != null) ...[
                            Icon(
                              Icons.groups,
                              size: 10,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                player.teamName!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.secondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Статус
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(player.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _getStatusColor(player.status),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(player.status),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(player.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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

  String _getStatusText(PlayerStatus status) {
    switch (status) {
      case PlayerStatus.lookingForGame:
        return 'Ищу игру';
      case PlayerStatus.freeTonight:
        return 'Свободен';
      case PlayerStatus.unavailable:
        return 'Занят';
    }
  }
} 