import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/game_notification_model.dart';
import '../../domain/entities/unified_notification_model.dart';
import '../../data/datasources/game_notification_service.dart';
import '../../data/datasources/unified_notification_service.dart';
import '../widgets/game_notification_card.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';

class EnhancedNotificationsScreen extends ConsumerStatefulWidget {
  const EnhancedNotificationsScreen({super.key});

  @override
  ConsumerState<EnhancedNotificationsScreen> createState() => _EnhancedNotificationsScreenState();
}

class _EnhancedNotificationsScreenState extends ConsumerState<EnhancedNotificationsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  
  late TabController _tabController;
  List<GameNotificationModel> _gameNotifications = [];
  List<UnifiedNotificationModel> _socialNotifications = [];
  bool _isLoading = false;
  UserModel? _currentUser;
  late GameNotificationService _gameNotificationService;
  late UnifiedNotificationService _unifiedNotificationService;
  
  // Счетчики для заявок
  int _friendRequestsCount = 0;
  int _teamInvitationsCount = 0;

  @override
  void initState() {
    super.initState();
    _currentUser = ref.read(currentUserProvider).value;
    _gameNotificationService = GameNotificationService();
    _unifiedNotificationService = UnifiedNotificationService(
      ref.read(userServiceProvider),
      ref.read(teamServiceProvider),
    );
    
    // Подписываемся на изменения состояния приложения
    WidgetsBinding.instance.addObserver(this);
    
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    // Отписываемся от изменений состояния приложения
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Обновляем уведомления при возвращении в приложение
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('🔄 Приложение возобновлено - обновляем уведомления');
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _currentUser = user;
        
        debugPrint('🔔 Загружаем все уведомления для пользователя: ${user.name}');
        
        // Загружаем уведомления параллельно
        final futures = await Future.wait([
          _gameNotificationService.getGameNotifications(user.id),
          _unifiedNotificationService.getIncomingNotifications(user.id),
          ref.read(userServiceProvider).getIncomingFriendRequests(user.id),
          ref.read(teamServiceProvider).getIncomingTeamInvitations(user.id),
        ]);
        
        if (mounted) {
          setState(() {
            _gameNotifications = futures[0] as List<GameNotificationModel>;
            _socialNotifications = futures[1] as List<UnifiedNotificationModel>;
            
            // Подсчитываем заявки в друзья и приглашения в команды
            final friendRequests = futures[2] as dynamic;
            final teamInvitations = futures[3] as dynamic;
            
            _friendRequestsCount = friendRequests?.length ?? 0;
            _teamInvitationsCount = teamInvitations?.length ?? 0;
          });
        }
        
        // Автоматически удаляем старые уведомления (старше 7 дней)
        _cleanupOldNotifications();
        
        debugPrint('✅ Загружено: ${_gameNotifications.length} игровых, ${_socialNotifications.length} социальных');
        debugPrint('✅ Заявок в друзья: $_friendRequestsCount, приглашений в команды: $_teamInvitationsCount');
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки уведомлений: $e');
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createTestNotification() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      // Просто отображаем диалог с информацией о том, как тестировать уведомления
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Тестирование уведомлений'),
          content: const Text(
            'Для тестирования уведомлений:\n\n'
            '1. Создайте игру\n'
            '2. Дождитесь времени окончания игры\n'
            '3. Система автоматически завершит игру и отправит уведомление\n'
            '4. Уведомление появится здесь в разделе "Игровые"'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ Ошибка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {

    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createTestNotification,
            tooltip: 'Тест уведомления',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Обновить',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.sports_volleyball),
              text: 'Игровые',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Социальные',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/schedule/schedule_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildGameNotificationsTab(),
                  _buildSocialNotificationsTab(),
                ],
              ),
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
        padding: const EdgeInsets.all(12),
        itemCount: _gameNotifications.length,
        itemBuilder: (context, index) {
          final notification = _gameNotifications[index];
          return GameNotificationCard(
            notification: notification,
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
        padding: const EdgeInsets.all(12),
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
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead ? Colors.transparent : AppColors.primary,
          width: notification.isRead ? 0 : 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Иконка типа
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getSocialNotificationColor(notification.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getSocialNotificationIcon(notification.type),
                    color: _getSocialNotificationColor(notification.type),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Заголовок
                Expanded(
                  child: Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
                
                // Индикатор непрочитанного
                if (!notification.isRead)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // Сообщение
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.text,
                height: 1.3,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Кнопки действий для заявок
            if (notification.status == UnifiedNotificationStatus.pending) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _handleSocialNotificationAction(notification, false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text('Отклонить', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => _handleSocialNotificationAction(notification, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text('Принять', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ] else ...[
              // Статус для обработанных уведомлений
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(notification.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(notification.status),
                      style: TextStyle(
                        fontSize: 10,
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

  Future<void> _deleteGameNotification(String notificationId) async {
    try {
      await _gameNotificationService.deleteNotification(notificationId);
      if (mounted) {
        setState(() {
          _gameNotifications.removeWhere((n) => n.id == notificationId);
        });
      }
      
      // Обновляем провайдеры счетчика уведомлений
      final user = _currentUser;
      if (user != null) {
        ref.invalidate(unreadGameNotificationsCountProvider(user.id));
        ref.invalidate(totalUnreadNotificationsCountProvider(user.id));
      }
    } catch (e) {
      debugPrint('❌ Ошибка удаления игрового уведомления: $e');
    }
  }

  Future<void> _cleanupOldNotifications() async {
    try {
      final user = _currentUser;
      if (user == null || !mounted) return;

      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 7));

      // Находим старые уведомления
      final oldNotifications = _gameNotifications
          .where((notification) => notification.createdAt.isBefore(cutoffDate))
          .toList();

      // Удаляем их
      for (final notification in oldNotifications) {
        if (!mounted) break; // Прерываем цикл если виджет больше не монтирован
        await _gameNotificationService.deleteNotification(notification.id);
      }

      // Обновляем состояние
      if (oldNotifications.isNotEmpty && mounted) {
        setState(() {
          _gameNotifications.removeWhere(
            (notification) => notification.createdAt.isBefore(cutoffDate),
          );
        });
        debugPrint('🧹 Удалено ${oldNotifications.length} старых уведомлений');
      }
    } catch (e) {
      debugPrint('❌ Ошибка очистки старых уведомлений: $e');
    }
  }

  Future<void> _handleSocialNotificationAction(UnifiedNotificationModel notification, bool accept) async {
    try {
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

      // Обновляем список и провайдеры
      if (mounted) {
        await _loadNotifications();
        
        // Обновляем провайдеры счетчика уведомлений
        ref.invalidate(unreadSocialNotificationsCountProvider(user.id));
        ref.invalidate(totalUnreadNotificationsCountProvider(user.id));
      }
      
    } catch (e) {
      debugPrint('❌ Ошибка обработки социального уведомления: $e');
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
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