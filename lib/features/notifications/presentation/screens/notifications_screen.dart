import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/router/app_router.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Уведомления'),
          backgroundColor: AppColors.darkGrey,
          foregroundColor: Colors.white,
        ),
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
          return Scaffold(
            appBar: AppBar(
              title: const Text('Уведомления'),
            ),
            body: const Center(child: Text('Пользователь не найден')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Уведомления'),
            backgroundColor: AppColors.darkGrey,
            foregroundColor: Colors.white,
          ),
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            padding: AppSizes.screenPadding,
            child: Column(
              children: [
                // Заявки в друзья
                FutureBuilder<int>(
                  future: _getIncomingRequestsCount(ref, user.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildNotificationCard(
                      context,
                      title: 'Заявки в друзья',
                      subtitle: count > 0 
                          ? '$count новых заявок' 
                          : 'Нет новых заявок',
                      icon: Icons.person_add,
                      count: count,
                      onTap: () => context.push('/friend-requests'),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Приглашения в команды
                FutureBuilder<int>(
                  future: _getIncomingTeamInvitationsCount(ref, user.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildNotificationCard(
                      context,
                      title: 'Приглашения в команды',
                      subtitle: count > 0 
                          ? '$count новых приглашений' 
                          : 'Нет новых приглашений',
                      icon: Icons.groups,
                      count: count,
                      onTap: () => context.push('/team-invitations'),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: count > 0 ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: count > 0 ? FontWeight.w600 : FontWeight.normal,
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
    );
  }

  Future<int> _getIncomingRequestsCount(WidgetRef ref, String userId) async {
    try {
      final userService = ref.read(userServiceProvider);
      return await userService.getIncomingRequestsCount(userId);
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getIncomingTeamInvitationsCount(WidgetRef ref, String userId) async {
    try {
      final teamService = ref.read(teamServiceProvider);
      return await teamService.getIncomingTeamInvitationsCount(userId);
    } catch (e) {
      return 0;
    }
  }
} 