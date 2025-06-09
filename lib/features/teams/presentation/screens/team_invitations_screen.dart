import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';

import '../../domain/entities/team_invitation_model.dart';
import '../../../auth/domain/entities/user_model.dart';

class TeamInvitationsScreen extends ConsumerStatefulWidget {
  const TeamInvitationsScreen({super.key});

  @override
  ConsumerState<TeamInvitationsScreen> createState() => _TeamInvitationsScreenState();
}

class _TeamInvitationsScreenState extends ConsumerState<TeamInvitationsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<TeamInvitationModel> _incomingInvitations = [];
  List<TeamInvitationModel> _outgoingInvitations = [];
  bool _isLoading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = ref.read(currentUserProvider).value;
    // Если пользователь обычный (UserRole.user), показываем только одну вкладку
    final tabCount = _currentUser?.role == UserRole.user ? 1 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
    _loadInvitations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _currentUser = user;
        final teamService = ref.read(teamServiceProvider);
        
        debugPrint('🔍 Загружаем приглашения для пользователя: ${user.name} (ID: ${user.id}, роль: ${user.role})');
        
        final incomingFuture = teamService.getIncomingTeamInvitations(user.id);
        
        // Загружаем исходящие приглашения только для организаторов и админов
        if (user.role != UserRole.user) {
          debugPrint('📤 Загружаем исходящие приглашения для организатора/админа');
          
          final outgoingFuture = teamService.getOutgoingTeamInvitations(user.id);
          final results = await Future.wait([incomingFuture, outgoingFuture]);
          
          debugPrint('📥 Входящие приглашения: ${results[0].length}');
          debugPrint('📤 Исходящие приглашения: ${results[1].length}');
          
          setState(() {
            _incomingInvitations = results[0];
            _outgoingInvitations = results[1];
          });
        } else {
          debugPrint('👤 Обычный пользователь - загружаем только входящие');
          
          final incomingInvitations = await incomingFuture;
          debugPrint('📥 Входящие приглашения: ${incomingInvitations.length}');
          
          setState(() {
            _incomingInvitations = incomingInvitations;
            _outgoingInvitations = []; // Пустой список для обычных пользователей
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки приглашений: $e');
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
        title: const Text('Приглашения в команды'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvitations,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Входящие (${_incomingInvitations.length})',
              icon: const Icon(Icons.inbox),
            ),
            if (showOutgoingTab)
              Tab(
                text: 'Исходящие (${_outgoingInvitations.length})',
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
    if (_incomingInvitations.isEmpty) {
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
              'Нет входящих приглашений',
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
      onRefresh: _loadInvitations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _incomingInvitations.length,
        itemBuilder: (context, index) {
          return _buildIncomingInvitationCard(_incomingInvitations[index]);
        },
      ),
    );
  }

  Widget _buildOutgoingTab() {
    if (_outgoingInvitations.isEmpty) {
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
              'Нет исходящих приглашений',
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
      onRefresh: _loadInvitations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _outgoingInvitations.length,
        itemBuilder: (context, index) {
          return _buildOutgoingInvitationCard(_outgoingInvitations[index]);
        },
      ),
    );
  }

  Widget _buildIncomingInvitationCard(TeamInvitationModel invitation) {
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
                  backgroundImage: invitation.fromUserPhotoUrl != null
                      ? NetworkImage(invitation.fromUserPhotoUrl!)
                      : null,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: invitation.fromUserPhotoUrl == null
                      ? Text(
                          _getInitials(invitation.fromUserName),
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
                      Text(
                        invitation.fromUserName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'приглашает в команду "${invitation.teamName}"',
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
            
            // Информация о замене
            if (invitation.replacedUserId != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Вы заменяете игрока: ${invitation.replacedUserName ?? "Неизвестно"}',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Время приглашения
            Text(
              'Приглашение отправлено: ${_formatDateTime(invitation.createdAt)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineInvitation(invitation),
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
                    onPressed: () => _acceptInvitation(invitation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Принять'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingInvitationCard(TeamInvitationModel invitation) {
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
                  backgroundImage: invitation.toUserPhotoUrl != null
                      ? NetworkImage(invitation.toUserPhotoUrl!)
                      : null,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  child: invitation.toUserPhotoUrl == null
                      ? Text(
                          _getInitials(invitation.toUserName),
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
                      Text(
                        invitation.toUserName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'приглашен в команду "${invitation.teamName}"',
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
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    invitation.statusDisplayName,
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Информация о замене
            if (invitation.replacedUserId != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Заменяет игрока: ${invitation.replacedUserName ?? "Неизвестно"}',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Время приглашения
            Text(
              'Приглашение отправлено: ${_formatDateTime(invitation.createdAt)}',
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
                onPressed: () => _cancelInvitation(invitation),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Отменить приглашение'),
              ),
            ),
          ],
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
    return '';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _acceptInvitation(TeamInvitationModel invitation) async {
    try {
      final teamService = ref.read(teamServiceProvider);
      await teamService.acceptTeamInvitation(invitation.id);
      
      if (mounted) {
        ErrorHandler.teamJoined(context, invitation.teamName);
        
        // Обновляем список приглашений
        await _loadInvitations();
        
        // Обновляем профиль пользователя
        ref.invalidate(currentUserProvider);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _declineInvitation(TeamInvitationModel invitation) async {
    try {
      final teamService = ref.read(teamServiceProvider);
      await teamService.declineTeamInvitation(invitation.id);
      
      if (mounted) {
        ErrorHandler.rejected(context, 'Приглашение');
        
        // Обновляем список приглашений
        await _loadInvitations();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _cancelInvitation(TeamInvitationModel invitation) async {
    try {
      final teamService = ref.read(teamServiceProvider);
      await teamService.cancelTeamInvitation(invitation.teamId, invitation.toUserId);
      
      if (mounted) {
        ErrorHandler.cancelled(context, 'Приглашение');
        
        // Обновляем список приглашений
        await _loadInvitations();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }
} 