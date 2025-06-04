import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/game_notification_model.dart';
import '../../domain/entities/unified_notification_model.dart';
import '../../data/datasources/game_notification_service.dart';
import '../../data/datasources/unified_notification_service.dart';
import '../widgets/game_notification_card.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';

class EnhancedNotificationsScreen extends ConsumerStatefulWidget {
  const EnhancedNotificationsScreen({super.key});

  @override
  ConsumerState<EnhancedNotificationsScreen> createState() => _EnhancedNotificationsScreenState();
}

class _EnhancedNotificationsScreenState extends ConsumerState<EnhancedNotificationsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<GameNotificationModel> _gameNotifications = [];
  List<UnifiedNotificationModel> _socialNotifications = [];
  bool _isLoading = false;
  UserModel? _currentUser;
  late GameNotificationService _gameNotificationService;
  late UnifiedNotificationService _unifiedNotificationService;

  @override
  void initState() {
    super.initState();
    _currentUser = ref.read(currentUserProvider).value;
    _gameNotificationService = GameNotificationService();
    _unifiedNotificationService = UnifiedNotificationService(
      ref.read(userServiceProvider),
      ref.read(teamServiceProvider),
    );
    
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _currentUser = user;
        
        debugPrint('🔔 Загружаем все уведомления для пользователя: ${user.name}');
        
        // Загружаем уведомления параллельно
        final futures = await Future.wait([
          _gameNotificationService.getGameNotifications(user.id),
          _unifiedNotificationService.getIncomingNotifications(user.id),
        ]);
        
        setState(() {
          _gameNotifications = futures[0] as List<GameNotificationModel>;
          _socialNotifications = futures[1] as List<UnifiedNotificationModel>;
        });
        
        debugPrint('✅ Загружено: ${_gameNotifications.length} игровых, ${_socialNotifications.length} социальных');
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки уведомлений: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadGameCount = _gameNotifications.where((n) => !n.isRead).length;
    final unreadSocialCount = _socialNotifications.where((n) => !n.isRead).length;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Уведомления'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Кнопка "Отметить все как прочитанные"
          if ((unreadGameCount + unreadSocialCount) > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Отметить все как прочитанные',
            ),
          
          // Кнопка обновления
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Обновить',
          ),
          
          // Кнопка домой
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
            tooltip: 'На главную',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports_volleyball, size: 18),
                  const SizedBox(width: 8),
                  Text('Игры'),
                  if (unreadGameCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadGameCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 18),
                  const SizedBox(width: 8),
                  Text('Социальные'),
                  if (unreadSocialCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadSocialCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGameNotificationsTab(),
                _buildSocialNotificationsTab(),
              ],
            ),
    );
  }

  /// Таб с уведомлениями о играх
  Widget _buildGameNotificationsTab() {
    if (_gameNotifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sports_volleyball_outlined,
        title: 'Нет уведомлений об играх',
        subtitle: 'Здесь будут появляться уведомления\nо новых играх и событиях',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _gameNotifications.length,
        itemBuilder: (context, index) {
          final notification = _gameNotifications[index];
          return GameNotificationCard(
            notification: notification,
            onMarkAsRead: () => _markGameNotificationAsRead(notification.id),
            onDelete: () => _deleteGameNotification(notification.id),
          );
        },
      ),
    );
  }

  /// Таб с социальными уведомлениями
  Widget _buildSocialNotificationsTab() {
    if (_socialNotifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outlined,
        title: 'Нет социальных уведомлений',
        subtitle: 'Здесь будут появляться заявки в друзья\nи приглашения в команды',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _socialNotifications.length,
        itemBuilder: (context, index) {
          final notification = _socialNotifications[index];
          return _buildSocialNotificationCard(notification);
        },
      ),
    );
  }

  /// Карточка социального уведомления
  Widget _buildSocialNotificationCard(UnifiedNotificationModel notification) {
    return Card(
      elevation: notification.isRead ? 1 : 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead ? Colors.transparent : AppColors.primary,
          width: notification.isRead ? 0 : 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: notification.isRead 
              ? null 
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    AppColors.primary.withOpacity(0.02),
                  ],
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Иконка типа
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSocialNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSocialNotificationIcon(notification.type),
                    color: _getSocialNotificationColor(notification.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Заголовок
                Expanded(
                  child: Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
                
                // Индикатор непрочитанного
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Сообщение
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Кнопки действий для заявок
            if (notification.status == UnifiedNotificationStatus.pending) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _handleSocialNotificationAction(notification, false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Отклонить'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleSocialNotificationAction(notification, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Принять'),
                  ),
                ],
              ),
            ] else ...[
              // Статус для обработанных уведомлений
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(notification.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(notification.status),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(notification.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Состояние загрузки
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Загружаем уведомления...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Пустое состояние
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Методы для работы с уведомлениями

  Future<void> _markGameNotificationAsRead(String notificationId) async {
    try {
      await _gameNotificationService.markAsRead(notificationId);
      setState(() {
        final index = _gameNotifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _gameNotifications[index] = _gameNotifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      debugPrint('❌ Ошибка отметки игрового уведомления: $e');
    }
  }

  Future<void> _deleteGameNotification(String notificationId) async {
    try {
      await _gameNotificationService.deleteNotification(notificationId);
      setState(() {
        _gameNotifications.removeWhere((n) => n.id == notificationId);
      });
    } catch (e) {
      debugPrint('❌ Ошибка удаления игрового уведомления: $e');
    }
  }

  Future<void> _handleSocialNotificationAction(UnifiedNotificationModel notification, bool accept) async {
    try {
      // TODO: Реализовать обработку социальных уведомлений
      final user = _currentUser;
      if (user == null) return;

      if (notification.type == UnifiedNotificationType.friendRequest) {
        if (accept) {
          // Принять заявку в друзья
          await ref.read(userServiceProvider).acceptFriendRequest(notification.id);
        } else {
          // Отклонить заявку в друзья
          await ref.read(userServiceProvider).declineFriendRequest(notification.id);
        }
      } else if (notification.type == UnifiedNotificationType.teamInvitation) {
        if (accept) {
          // Принять приглашение в команду
          await ref.read(teamServiceProvider).acceptTeamInvitation(notification.id);
        } else {
          // Отклонить приглашение в команду
          await ref.read(teamServiceProvider).declineTeamInvitation(notification.id);
        }
      }

      // Обновляем список
      await _loadNotifications();
      
    } catch (e) {
      debugPrint('❌ Ошибка обработки социального уведомления: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final user = _currentUser;
      if (user == null) return;

      await Future.wait([
        _gameNotificationService.markAllAsRead(user.id),
        // TODO: Добавить markAllAsRead для социальных уведомлений
      ]);

      await _loadNotifications();
      
    } catch (e) {
      debugPrint('❌ Ошибка отметки всех уведомлений: $e');
    }
  }

  // Вспомогательные методы

  IconData _getSocialNotificationIcon(UnifiedNotificationType type) {
    switch (type) {
      case UnifiedNotificationType.friendRequest:
        return Icons.person_add;
      case UnifiedNotificationType.teamInvitation:
        return Icons.group_add;
      case UnifiedNotificationType.teamExclusion:
        return Icons.group_remove;
    }
  }

  Color _getSocialNotificationColor(UnifiedNotificationType type) {
    switch (type) {
      case UnifiedNotificationType.friendRequest:
        return AppColors.success;
      case UnifiedNotificationType.teamInvitation:
        return AppColors.primary;
      case UnifiedNotificationType.teamExclusion:
        return AppColors.error;
    }
  }

  Color _getStatusColor(UnifiedNotificationStatus status) {
    switch (status) {
      case UnifiedNotificationStatus.accepted:
        return AppColors.success;
      case UnifiedNotificationStatus.declined:
        return AppColors.error;
      case UnifiedNotificationStatus.pending:
        return AppColors.warning;
      case UnifiedNotificationStatus.read:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(UnifiedNotificationStatus status) {
    switch (status) {
      case UnifiedNotificationStatus.accepted:
        return 'Принято';
      case UnifiedNotificationStatus.declined:
        return 'Отклонено';
      case UnifiedNotificationStatus.pending:
        return 'Ожидает';
      case UnifiedNotificationStatus.read:
        return 'Прочитано';
    }
  }
} 