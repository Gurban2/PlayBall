import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/providers.dart';
import '../../domain/entities/user_model.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.appName,
          style: AppTextStyles.appBarTitle,
        ),
        backgroundColor: AppColors.darkGrey,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          userAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            error: (error, stack) => TextButton(
              onPressed: () => context.push(AppRoutes.login),
              child: const Text(
                'Войти',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            data: (user) {
              if (user == null) {
                return TextButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: const Text(
                    'Войти',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              } else {
                return PopupMenuButton<String>(
                  icon: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        context.push(AppRoutes.profile);
                        break;
                      case 'logout':
                        _logout(context, ref);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          const Icon(Icons.person),
                          const SizedBox(width: 8),
                          Text('Привет, ${user.name}!'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Выйти'),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/setka.jfif'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.secondary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.extraLargeSpace),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.sports_volleyball,
                        size: 120,
                        color: Colors.white,
                      ),
                      const SizedBox(height: AppSizes.mediumSpace),
                      const Text(
                        'Добро пожаловать в PlayBall!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.smallSpace),
                      const Text(
                        'Организуй и участвуй в волейбольных играх\nс друзьями и новыми знакомыми',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.largeSpace),
                      userAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (error, stack) => const SizedBox.shrink(),
                        data: (user) {
                          if (user == null) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => context.push(AppRoutes.login),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                                      ),
                                    ),
                                    child: const Text(
                                      'Войти',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.mediumSpace),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.push(AppRoutes.register),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                                      ),
                                    ),
                                    child: const Text(
                                      'Регистрация',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Cards Section
            Padding(
              padding: AppSizes.screenPadding,
              child: Column(
                children: [
                  const SizedBox(height: AppSizes.largeSpace),
                  const Text(
                    'Что ты хочешь сделать?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: AppSizes.largeSpace),
                  
                  // Action Cards
                  _buildActionCard(
                    context: context,
                    icon: Icons.list,
                    title: 'Посмотреть игры',
                    subtitle: 'Найди интересную игру и присоединись',
                    color: AppColors.primary,
                    onTap: () => context.push(AppRoutes.home),
                  ),
                  
                  const SizedBox(height: AppSizes.mediumSpace),
                  
                  userAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (error, stack) => const SizedBox.shrink(),
                    data: (user) {
                      if (user?.role == UserRole.organizer || user?.role == UserRole.admin) {
                        return Column(
                          children: [
                            _buildActionCard(
                              context: context,
                              icon: Icons.add_circle,
                              title: 'Создать игру',
                              subtitle: 'Организуй новую волейбольную игру',
                              color: AppColors.secondary,
                              onTap: () => context.push(AppRoutes.createRoom),
                            ),
                            const SizedBox(height: AppSizes.mediumSpace),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  _buildActionCard(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'О приложении',
                    subtitle: 'Узнай больше о PlayBall',
                    color: AppColors.accent,
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
            
            // Features Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: AppSizes.extraLargeSpace),
              padding: AppSizes.screenPadding,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Возможности PlayBall',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: AppSizes.largeSpace),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureItem(
                          icon: Icons.schedule,
                          title: 'Планирование',
                          description: 'Создавай и планируй игры заранее',
                        ),
                      ),
                      Expanded(
                        child: _buildFeatureItem(
                          icon: Icons.group,
                          title: 'Команды',
                          description: 'Формируй команды и играй с друзьями',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSizes.largeSpace),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureItem(
                          icon: Icons.location_on,
                          title: 'Локации',
                          description: 'Находи игры рядом с тобой',
                        ),
                      ),
                      Expanded(
                        child: _buildFeatureItem(
                          icon: Icons.notifications,
                          title: 'Уведомления',
                          description: 'Получай уведомления о играх',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSizes.extraLargeSpace),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: AppSizes.cardPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppSizes.largeIconSize,
                ),
              ),
              const SizedBox(width: AppSizes.mediumSpace),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.smallSpace),
              const Icon(
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

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: AppSizes.largeIconSize,
            ),
          ),
          const SizedBox(height: AppSizes.smallSpace),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (context.mounted) {
        context.go('/'); // Возвращаемся на welcome page
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('О приложении PlayBall'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PlayBall - это приложение для организации волейбольных игр.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Возможности:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Создание и планирование игр'),
            Text('• Поиск игр рядом с вами'),
            Text('• Формирование команд'),
            Text('• Уведомления о играх'),
            Text('• Статистика и рейтинги'),
          ],
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
} 