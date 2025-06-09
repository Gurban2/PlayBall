import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/providers.dart';
import '../../../features/auth/domain/entities/user_model.dart';

class HamburgerMenu extends ConsumerWidget {
  const HamburgerMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.menu,
        size: 24,
        color: Colors.white,
      ),
      color: AppColors.darkGrey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 45),
      itemBuilder: (context) {
        final user = ref.read(currentUserProvider).value;
        
        return [
          // Профиль игрока
          PopupMenuItem<String>(
            value: 'profile',
            child: ListTile(
              leading: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
              title: const Text(
                'Профиль игрока',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          
          // Dashboard (только для организаторов)
          if (user?.role == UserRole.organizer || user?.role == UserRole.admin)
            PopupMenuItem<String>(
              value: 'dashboard',
              child: ListTile(
                leading: const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 20,
                ),
                title: const Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          
          // Разделитель
          PopupMenuItem<String>(
            enabled: false,
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          
          // Выход
          PopupMenuItem<String>(
            value: 'logout',
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: AppColors.error,
                size: 20,
              ),
              title: const Text(
                'Выход',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ];
      },
      onSelected: (value) => _handleMenuAction(context, ref, value),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'profile':
        context.push('/profile');
        break;
      case 'dashboard':
        context.push('/organizer-dashboard');
        break;
      case 'logout':
        _showLogoutDialog(context, ref);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Выйти'),
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
        context.go(AppRoutes.welcome);
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, 'Ошибка выхода: ${e.toString()}');
      }
    }
  }
} 