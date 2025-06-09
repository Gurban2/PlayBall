import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/providers.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../shared/widgets/universal_card.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../widgets/player_friends_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF1A1B2E),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Color(0xFF1A1B2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: $error', style: const TextStyle(color: Colors.white)),
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
          return const Scaffold(
            backgroundColor: Color(0xFF1A1B2E),
            body: Center(child: Text('Пользователь не найден', style: TextStyle(color: Colors.white))),
          );
        }



        return Scaffold(
          backgroundColor: const Color(0xFF1A1B2E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1B2E),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF00C7), Color(0xFF7B2CBF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.notifications, color: Colors.white, size: 20),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Профиль заголовок с аватаром
                _buildProfileHeader(user),
                const SizedBox(height: 24),
                
                // Кнопки Deposit и Withdraw
                _buildActionButtons(),
                const SizedBox(height: 24),
                
                // Статистические показатели
                _buildStatsRow(user),
                const SizedBox(height: 32),
                
                // Меню опций
                _buildMenuOptions(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        // Аватар
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: user.photoUrl != null
                ? Image.network(
                    user.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(user),
                  )
                : _buildDefaultAvatar(user),
          ),
        ),
        const SizedBox(height: 16),
        
        // Имя
        Text(
          user.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Баланс (заглушка)
        Text(
          '\$123,456.00',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF00C7), Color(0xFF7B2CBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(38),
      ),
      child: Center(
        child: Text(
          _getInitials(user.name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text(
                'Deposit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text(
                'Withdraw',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Prediction', '3.45', const Color(0xFFFF00C7)),
        _buildStatItem('Wins', user.wins.toString(), const Color(0xFFFF00C7)),
        _buildStatItem('Winrate', '${user.winRate.toStringAsFixed(0)}%', const Color(0xFFFF00C7)),
        _buildStatItem('Profit', '\$789', const Color(0xFFFF00C7)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOptions() {
    final menuItems = [
      {'icon': Icons.emoji_events, 'title': 'Рейтинг'},
      {'icon': Icons.people, 'title': 'Друзья'},
      {'icon': Icons.edit, 'title': 'Редактировать профиль'},
      {'icon': Icons.groups, 'title': 'Команда'},
      {'icon': Icons.sports_volleyball, 'title': 'Мои игры'},
      {'icon': Icons.settings, 'title': 'Настройки'},
    ];

    return Column(
      children: menuItems.map((item) => _buildMenuItem(
        item['icon'] as IconData,
        item['title'] as String,
      )).toList(),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withOpacity(0.5),
          size: 16,
        ),
        onTap: () => _handleMenuItemTap(title),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  void _handleMenuItemTap(String title) {
    switch (title) {
      case 'Рейтинг':
        context.push(AppRoutes.leaderboard);
        break;
      case 'Друзья':
        context.push('/friends');
        break;
      case 'Команда':
        context.push(AppRoutes.myTeam);
        break;
      case 'Мои игры':
        context.push(AppRoutes.schedule);
        break;
      case 'Редактировать профиль':
        context.push(AppRoutes.editProfile);
        break;
      case 'Настройки':
        // Заглушка для пунктов меню которых еще нет
        ErrorHandler.showInfo(context, '$title - скоро будет доступно');
        break;
    }
  }


}
