import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../domain/entities/room_model.dart';
import '../../../teams/domain/entities/team_model.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../widgets/room_info_card.dart';
import '../widgets/room_teams_card.dart';
import '../widgets/room_action_buttons.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';

class RoomScreenRefactored extends ConsumerStatefulWidget {
  final String roomId;
  
  const RoomScreenRefactored({super.key, required this.roomId});

  @override
  ConsumerState<RoomScreenRefactored> createState() => _RoomScreenRefactoredState();
}

class _RoomScreenRefactoredState extends ConsumerState<RoomScreenRefactored> {
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    // Таймер убран - обновления происходят только при изменении данных
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          roomAsync.value?.title ?? 'Комната',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.darkGrey,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateBack(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorView(error),
        data: (RoomModel? room) => room == null
            ? _buildRoomNotFoundView(context)
            : userAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildUserErrorView(error),
                data: (UserModel? user) => _buildRoomContent(room, user),
              ),
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Ошибка загрузки комнаты: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(roomProvider(widget.roomId)),
            child: const Text('Повторить'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _navigateBack(context),
            child: const Text('Назад'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomNotFoundView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('Комната не найдена'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _navigateBack(context),
            child: const Text('Назад'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Ошибка загрузки пользователя: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(currentUserProvider),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomContent(RoomModel room, UserModel? user) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: AppSizes.screenPadding,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о комнате
            RoomInfoCard(
              room: room,
              teamService: ref.read(teamServiceProvider),
            ),
            
            // Команды
            RoomTeamsCard(
              room: room,
              roomId: widget.roomId,
              teamService: ref.read(teamServiceProvider),
            ),
            
            // Кнопки действий
            if (user != null) ...[
              const SizedBox(height: AppSizes.mediumSpace),
              RoomActionButtons(
                user: user,
                room: room,
                teamService: ref.read(teamServiceProvider),
                isJoining: _isJoining,
                roomId: widget.roomId,
                onSelectTeam: _selectTeam,
                onLeaveTeam: _leaveTeam,
                onUpdateRoomStatus: _updateRoomStatus,
                onStartGameWithConfirmation: _startGameWithConfirmation,
                onEndGameWithConfirmation: _endGameWithConfirmation,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Методы бизнес-логики
  Future<void> _selectTeam() async {
    final user = ref.read(currentUserProvider).value;
    final room = ref.read(roomProvider(widget.roomId)).value;
    
    // Проверяем авторизацию
    if (user == null) {
      _showSnackBar('Необходимо войти в систему', AppColors.warning);
      return;
    }
    
    // Для командных игр и организаторов - вызываем специальную функцию
    if (room != null && room.isTeamMode && user.role == UserRole.organizer) {
      await _joinTeamGameAsOrganizer(user, room);
      return;
    }
    
    // Проверяем роль для командных игр
    if (room != null && room.isTeamMode && user.role == UserRole.user) {
      final isParticipant = room.participants.contains(user.id);
      
      if (!isParticipant) {
        _showSnackBar(
          'Вы можете участвовать в командных играх только через организатора вашей команды',
          AppColors.warning,
        );
        return;
      }
    }
    
    // Переходим к экрану выбора команды (для обычного режима)
    context.push('/team-selection/${widget.roomId}');
  }

  Future<void> _joinTeamGameAsOrganizer(UserModel user, RoomModel room) async {
    setState(() {
      _isJoining = true;
    });

    try {
      // Пока временная заглушка, метод можно реализовать позже
      _showSnackBar('Функция в разработке', AppColors.warning);
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _leaveTeam(String teamId, UserModel user) async {
    setState(() {
      _isJoining = true;
    });

    try {
      final teamService = ref.read(teamServiceProvider);
      await teamService.leaveTeam(teamId, user.id);
      
      if (mounted) {
        _showSnackBar('Вы покинули команду', AppColors.warning);
        _invalidateProviders();
        
        // Ждем немного для синхронизации Firebase
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Ошибка выхода из команды: ${e.toString()}', AppColors.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _updateRoomStatus(RoomStatus newStatus) async {
    try {
      final roomService = ref.read(roomServiceProvider);
      await roomService.updateRoom(roomId: widget.roomId, status: newStatus);
      
      if (mounted) {
        _showSnackBar('Статус игры обновлен', AppColors.success);
        ref.invalidate(roomProvider(widget.roomId));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Ошибка обновления статуса: ${e.toString()}', AppColors.error);
      }
    }
  }

  // Новый метод для начала игры с проверками
  Future<void> _startGameWithConfirmation() async {
    final roomAsync = ref.read(roomProvider(widget.roomId));
    final room = roomAsync.value;
    
    if (room == null) return;
    
    final now = DateTime.now();
    final isEarly = now.isBefore(room.startTime);
    
    // Если игра начинается раньше времени, показываем подтверждение
    if (isEarly) {
      final confirmed = await ConfirmationDialog.showStartEarly(context);
      if (confirmed != true) return;
      
      // Проверяем конфликты локации
      final roomService = ref.read(roomServiceProvider);
      final hasConflict = await roomService.checkLocationConflict(
        location: room.location,
        startTime: now,
        endTime: room.endTime,
        excludeRoomId: room.id,
      );
      
      if (hasConflict) {
        ConfirmationDialog.showLocationConflict(
          context,
          plannedStartTime: room.startTime,
        );
        return;
      }
    }
    
    await _updateRoomStatus(RoomStatus.active);
  }

  Future<void> _endGameWithConfirmation() async {
    final confirmed = await ConfirmationDialog.showEndEarly(context);
    if (confirmed == true) {
      await _updateRoomStatus(RoomStatus.completed);
    }
  }

  // Вспомогательные методы
  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _refreshData() async {
    ref.invalidate(roomProvider(widget.roomId));
    ref.refresh(currentUserProvider);
  }

  void _invalidateProviders() {
    ref.invalidate(roomProvider(widget.roomId));
    ref.invalidate(teamsProvider(widget.roomId));
    ref.invalidate(currentUserProvider);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  bool _isUserParticipant(UserModel user, RoomModel room) {
    return room.participants.contains(user.id);
  }

  bool _isUserOrganizer(UserModel user, RoomModel room) {
    return user.id == room.organizerId;
  }
} 