import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _navigateToEditProfile(BuildContext context) {
    context.push(AppRoutes.editProfile);
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

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppStrings.adminRole;
      case UserRole.organizer:
        return AppStrings.organizerRole;
      case UserRole.user:
      default:
        return AppStrings.userRole;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.adminRole;
      case UserRole.organizer:
        return AppColors.organizerRole;
      case UserRole.user:
      default:
        return AppColors.userRole;
    }
  }

  double _calculateWinRate(UserModel? user) {
    if (user == null || user.gamesPlayed == 0) {
      return 0.0;
    }
    return (user.wins / user.gamesPlayed) * 100;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context, ref),
            tooltip: 'Выйти',
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
              Text('Ошибка загрузки профиля: $error'),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Аватар пользователя
                      CircleAvatar(
                        radius: AppSizes.largeAvatarSize / 2,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                _getInitials(user.name),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      
                      const SizedBox(height: AppSizes.mediumSpace),
                      
                      // Имя пользователя
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Email
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Роль пользователя
                      _buildRoleBadge(user.role),
                      
                      const SizedBox(height: AppSizes.largeSpace),
                      
                      // Кнопка редактирования профиля
                      ElevatedButton.icon(
                        onPressed: () => _navigateToEditProfile(context),
                        icon: const Icon(Icons.edit),
                        label: const Text(AppStrings.editProfile),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.mediumSpace,
                            vertical: 12,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppSizes.largeSpace),
                      
                      // Статистика
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppStrings.statistics,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppSizes.mediumSpace),
                      
                      // Карточка со статистикой
                      Card(
                        elevation: AppSizes.cardElevation,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                        ),
                        child: Padding(
                          padding: AppSizes.cardPadding,
                          child: Column(
                            children: [
                              // Рейтинг
                              _buildStatRow(
                                Icons.star,
                                AppStrings.rating,
                                user.rating.toString(),
                              ),
                              
                              const Divider(height: 24),
                              
                              // Сыграно игр
                              _buildStatRow(
                                Icons.sports_volleyball,
                                AppStrings.gamesPlayed,
                                user.gamesPlayed.toString(),
                              ),
                              
                              const Divider(height: 24),
                              
                              // Победы
                              _buildStatRow(
                                Icons.emoji_events,
                                AppStrings.wins,
                                user.wins.toString(),
                              ),
                              
                              const Divider(height: 24),
                              
                              // Поражения
                              _buildStatRow(
                                Icons.close,
                                AppStrings.losses,
                                user.losses.toString(),
                              ),
                              
                              const Divider(height: 24),
                              
                              // Процент побед
                              _buildStatRow(
                                Icons.percent,
                                AppStrings.winRate,
                                '${_calculateWinRate(user).toStringAsFixed(0)}%',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color color;
    String text;

    switch (role) {
      case UserRole.admin:
        color = AppColors.adminRole;
        text = AppStrings.adminRole;
        break;
      case UserRole.organizer:
        color = AppColors.organizerRole;
        text = AppStrings.organizerRole;
        break;
      case UserRole.user:
        color = AppColors.userRole;
        text = AppStrings.userRole;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
} 