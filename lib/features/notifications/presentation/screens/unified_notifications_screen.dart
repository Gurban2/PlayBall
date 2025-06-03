import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/unified_notification_model.dart';
import '../../data/datasources/unified_notification_service.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';

class UnifiedNotificationsScreen extends ConsumerStatefulWidget {
  const UnifiedNotificationsScreen({super.key});

  @override
  ConsumerState<UnifiedNotificationsScreen> createState() => _UnifiedNotificationsScreenState();
}

class _UnifiedNotificationsScreenState extends ConsumerState<UnifiedNotificationsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<UnifiedNotificationModel> _incomingNotifications = [];
  List<UnifiedNotificationModel> _outgoingNotifications = [];
  bool _isLoading = false;
  UserModel? _currentUser;
  late UnifiedNotificationService _unifiedNotificationService;

  @override
  void initState() {
    super.initState();
    _currentUser = ref.read(currentUserProvider).value;
    _unifiedNotificationService = UnifiedNotificationService(
      ref.read(userServiceProvider),
      ref.read(teamServiceProvider),
    );
    
    // Если пользователь обычный (UserRole.user), показываем только одну вкладку
    final tabCount = _currentUser?.role == UserRole.user ? 1 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
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
        
        debugPrint('🔍 Загружаем уведомления для пользователя: ${user.name} (ID: ${user.id}, роль: ${user.role})');
        
        final incomingFuture = _unifiedNotificationService.getIncomingNotifications(user.id);
        
        // Загружаем исходящие уведомления только для организаторов и админов
        if (user.role != UserRole.user) {
          debugPrint('📤 Загружаем исходящие уведомления для организатора/админа');
          
          final outgoingFuture = _unifiedNotificationService.getOutgoingNotifications(user.id);
          final results = await Future.wait([incomingFuture, outgoingFuture]);
          
          debugPrint('📥 Входящие уведомления: ${results[0].length}');
          debugPrint('📤 Исходящие уведомления: ${results[1].length}');
          
          setState(() {
            _incomingNotifications = results[0];
            _outgoingNotifications = results[1];
          });
        } else {
          debugPrint('👤 Обычный пользователь - загружаем только входящие');
          
          final incomingNotifications = await incomingFuture;
          debugPrint('📥 Входящие уведомления: ${incomingNotifications.length}');
          
          setState(() {
            _incomingNotifications = incomingNotifications;
            _outgoingNotifications = []; // Пустой список для обычных пользователей
          });
        }
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
    // Пересоздаем TabController при изменении пользователя
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser != null && currentUser != _currentUser) {
      _currentUser = currentUser;
      final newTabCount = currentUser.role == UserRole.user ? 1 : 2;
      if (_tabController.length != newTabCount) {
        _tabController.dispose();
        _tabController = TabController(length: newTabCount, vsync: this);
      }
    }
    
    final showOutgoingTab = _currentUser?.role != UserRole.user;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Уведомления'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go(AppRoutes.home),
            tooltip: 'На главную',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Входящие (${_incomingNotifications.length})',
              icon: const Icon(Icons.inbox),
            ),
            if (showOutgoingTab)
              Tab(
                text: 'Исходящие (${_outgoingNotifications.length})',
                icon: const Icon(Icons.outbox),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildIncomingTab(),
                if (showOutgoingTab) _buildOutgoingTab(),
              ],
            ),
    );
  }

  Widget _buildIncomingTab() {
    if (_incomingNotifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Нет входящих уведомлений',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _incomingNotifications.length,
        itemBuilder: (context, index) {
          return _buildIncomingNotificationCard(_incomingNotifications[index]);
        },
      ),
    );
  }

  Widget _buildOutgoingTab() {
    if (_outgoingNotifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.outbox_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Нет исходящих уведомлений',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _outgoingNotifications.length,
        itemBuilder: (context, index) {
          return _buildOutgoingNotificationCard(_outgoingNotifications[index]);
        },
      ),
    );
  }

  Widget _buildIncomingNotificationCard(UnifiedNotificationModel notification) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: notification.displayPhotoUrl.isNotEmpty
                      ? NetworkImage(notification.displayPhotoUrl)
                      : null,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: notification.displayPhotoUrl.isEmpty
                      ? Text(
                          _getInitials(notification.displayName),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getNotificationIcon(notification.type),
                            size: 16,
                            color: _getNotificationColor(notification.type),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Время уведомления
            Text(
              'Отправлено: ${_formatDateTime(notification.createdAt)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            
            if (notification.canRespond) ...[
              const SizedBox(height: 16),
              // Кнопки действий
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineNotification(notification),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Отклонить'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptNotification(notification),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        notification.type == UnifiedNotificationType.friendRequest 
                            ? 'Принять' 
                            : 'Присоединиться',
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (notification.type == UnifiedNotificationType.teamExclusion && !notification.isRead) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _markAsRead(notification),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Понятно'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingNotificationCard(UnifiedNotificationModel notification) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: notification.toUserPhotoUrl != null
                      ? NetworkImage(notification.toUserPhotoUrl!)
                      : null,
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  child: notification.toUserPhotoUrl == null
                      ? Text(
                          _getInitials(notification.toUserName ?? ''),
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getNotificationIcon(notification.type),
                            size: 16,
                            color: _getNotificationColor(notification.type),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Отправлено: ${notification.toUserName ?? 'Неизвестно'}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(notification.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusDisplayName(notification.status),
                    style: TextStyle(
                      color: _getStatusColor(notification.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Время уведомления
            Text(
              'Отправлено: ${_formatDateTime(notification.createdAt)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Кнопка отмены
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancelNotification(notification),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: Text(
                  notification.type == UnifiedNotificationType.friendRequest 
                      ? 'Отменить заявку' 
                      : 'Отменить приглашение',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(UnifiedNotificationType type) {
    switch (type) {
      case UnifiedNotificationType.friendRequest:
        return Icons.person_add;
      case UnifiedNotificationType.teamInvitation:
        return Icons.groups;
      case UnifiedNotificationType.teamExclusion:
        return Icons.exit_to_app;
    }
  }

  Color _getNotificationColor(UnifiedNotificationType type) {
    switch (type) {
      case UnifiedNotificationType.friendRequest:
        return AppColors.primary;
      case UnifiedNotificationType.teamInvitation:
        return AppColors.success;
      case UnifiedNotificationType.teamExclusion:
        return AppColors.warning;
    }
  }

  Color _getStatusColor(UnifiedNotificationStatus status) {
    switch (status) {
      case UnifiedNotificationStatus.pending:
        return AppColors.warning;
      case UnifiedNotificationStatus.accepted:
        return AppColors.success;
      case UnifiedNotificationStatus.declined:
        return AppColors.error;
      case UnifiedNotificationStatus.read:
        return AppColors.textSecondary;
    }
  }

  String _getStatusDisplayName(UnifiedNotificationStatus status) {
    switch (status) {
      case UnifiedNotificationStatus.pending:
        return 'Ожидает';
      case UnifiedNotificationStatus.accepted:
        return 'Принято';
      case UnifiedNotificationStatus.declined:
        return 'Отклонено';
      case UnifiedNotificationStatus.read:
        return 'Прочитано';
    }
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _acceptNotification(UnifiedNotificationModel notification) async {
    try {
      await _unifiedNotificationService.acceptNotification(notification);
      
      if (mounted) {
        String message;
        if (notification.type == UnifiedNotificationType.friendRequest) {
          message = '${notification.displayName} добавлен в друзья!';
        } else {
          message = 'Вы присоединились к команде "${notification.teamName}"!';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Обновляем список уведомлений
        await _loadNotifications();
        
        // Обновляем профиль пользователя
        ref.invalidate(currentUserProvider);
      }
    } catch (e) {
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

  Future<void> _declineNotification(UnifiedNotificationModel notification) async {
    try {
      await _unifiedNotificationService.declineNotification(notification);
      
      if (mounted) {
        String message;
        if (notification.type == UnifiedNotificationType.friendRequest) {
          message = 'Заявка в друзья отклонена';
        } else {
          message = 'Приглашение в команду отклонено';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Обновляем список уведомлений
        await _loadNotifications();
      }
    } catch (e) {
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

  Future<void> _cancelNotification(UnifiedNotificationModel notification) async {
    try {
      await _unifiedNotificationService.cancelOutgoingNotification(notification);
      
      if (mounted) {
        String message;
        if (notification.type == UnifiedNotificationType.friendRequest) {
          message = 'Заявка в друзья отменена';
        } else {
          message = 'Приглашение в команду отменено';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Обновляем список уведомлений
        await _loadNotifications();
      }
    } catch (e) {
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

  Future<void> _markAsRead(UnifiedNotificationModel notification) async {
    try {
      await _unifiedNotificationService.markNotificationAsRead(notification.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Уведомление отмечено как прочитанное'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Обновляем список уведомлений
        await _loadNotifications();
      }
    } catch (e) {
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
} 