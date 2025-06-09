import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../auth/data/datasources/user_service.dart';
import '../../../rooms/data/datasources/room_service.dart';
import '../../data/datasources/player_evaluation_service.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';

class GameEvaluationScreen extends ConsumerStatefulWidget {
  final String roomId;

  const GameEvaluationScreen({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<GameEvaluationScreen> createState() => _GameEvaluationScreenState();
}

class _GameEvaluationScreenState extends ConsumerState<GameEvaluationScreen> {
  final Set<String> _selectedPlayers = {};
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  RoomModel? _room;
  List<UserModel> _participants = [];
  UserModel? _currentUser;
  final PlayerEvaluationService _evaluationService = PlayerEvaluationService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final roomService = RoomService();
      final userService = UserService();
      
      // Загружаем данные о комнате
      _room = await roomService.getRoomById(widget.roomId);
      
      if (_room == null) {
        if (mounted) {
          ErrorHandler.notFound(context, 'Игра');
          Navigator.of(context).pop();
        }
        return;
      }

      // Получаем текущего пользователя
      _currentUser = ref.read(currentUserProvider).value;
      
      if (_currentUser == null) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      // Проверяем, не оценил ли уже этот организатор игру
      final hasEvaluated = await _evaluationService.hasOrganizerEvaluated(
        gameId: widget.roomId,
        organizerId: _currentUser!.id,
      );

      if (hasEvaluated) {
        if (mounted) {
          ErrorHandler.showWarning(context, 'Вы уже оценили эту игру');
          Navigator.of(context).pop();
        }
        return;
      }

      // Определяем список игроков для оценки в зависимости от режима игры
      List<String> playersToEvaluate = [];
      
      if (_room!.isTeamMode) {
        // В командном режиме: организатор оценивает только игроков своей команды
        playersToEvaluate = await _getMyTeamMembersInGame();
      } else {
        // В обычном режиме: организатор оценивает всех участников кроме себя
        playersToEvaluate = (_room!.finalParticipants ?? _room!.participants)
            .where((id) => id != _currentUser!.id)
            .toList();
      }

      // Загружаем данные участников
      _participants = await userService.getUsersByIds(playersToEvaluate);

    } catch (e) {
      debugPrint('Ошибка загрузки данных: $e');
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Получить участников команды текущего пользователя в данной игре
  Future<List<String>> _getMyTeamMembersInGame() async {
    try {
      if (_room == null || _currentUser == null) return [];
      
      final teamService = ref.read(teamServiceProvider);
      
      // Получаем все команды в данной игре
      final teams = await teamService.getTeamsForRoom(_room!.id);
      
      // Ищем команду, в которой состоит текущий пользователь
      for (final team in teams) {
        if (team.members.contains(_currentUser!.id)) {
          // Возвращаем всех участников команды кроме себя
          return team.members.where((id) => id != _currentUser!.id).toList();
        }
      }
      
      // Если команда не найдена, возвращаем пустой список
      return [];
    } catch (e) {
      debugPrint('❌ Ошибка получения участников команды: $e');
      return [];
    }
  }

  Future<void> _submitEvaluation() async {
    if (_selectedPlayers.isEmpty) {
      ErrorHandler.validation(context, 'Выберите хотя бы одного игрока для оценки');
      return;
    }

    final maxSelections = _getMaxSelections();
    if (_selectedPlayers.length > maxSelections) {
      ErrorHandler.validation(context, 'Можно выбрать максимум $maxSelections игроков');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Сохраняем оценки
      await _evaluationService.savePlayerEvaluations(
        gameId: widget.roomId,
        organizerId: _currentUser!.id,
        selectedPlayerIds: _selectedPlayers.toList(),
        comment: _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
      );

      if (mounted) {
        ErrorHandler.saved(context, 'Оценки');

        // Возвращаемся на страницу расписания
        context.go(AppRoutes.schedule);
      }
    } catch (e) {
      debugPrint('Ошибка сохранения оценок: $e');
      if (mounted) {
        ErrorHandler.showError(context, 'Ошибка сохранения оценок: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _getMaxSelections() {
    if (_room?.isTeamMode == true) {
      // Для командного режима - максимум 2 сердечка
      return 2;
    } else {
      // Для обычного режима - максимум 4 сердечка
      return 4;
    }
  }

  String _getInstructionText() {
    if (_room == null) return '';
    
    if (_room!.isTeamMode) {
      return 'Выберите до 2 игроков своей команды, которые особенно отличились в этой игре. '
             'Каждый выбранный игрок получит +1 балл от капитана.';
    } else {
      return 'Выберите до 4 игроков, которые особенно отличились в этой игре. '
             'Каждый выбранный игрок получит +1 балл от организатора.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_room?.isTeamMode == true 
            ? 'Оценка команды' 
            : 'Оценка игроков'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _selectedPlayers.isNotEmpty)
            TextButton(
              onPressed: _submitEvaluation,
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_room == null) {
      return const Center(
        child: Text('Игра не найдена'),
      );
    }

    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация об игре
          _buildGameInfo(),
          
          const SizedBox(height: AppSizes.mediumSpace),

          // Инструкция
          _buildInstruction(),

          const SizedBox(height: AppSizes.mediumSpace),

          // Счетчик выбранных игроков
          _buildSelectionCounter(),

          const SizedBox(height: AppSizes.mediumSpace),

          // Список игроков
          _buildPlayersList(),

          const SizedBox(height: AppSizes.mediumSpace),

          // Комментарий (опционально)
          _buildCommentSection(),

          const SizedBox(height: AppSizes.largeSpace),

          // Кнопка сохранения
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    return Card(
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _room!.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.smallSpace),
            Text(
              '${_room!.location} • ${_formatDate(_room!.startTime)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            if (_room!.isTeamMode) ...[
              const SizedBox(height: AppSizes.smallSpace),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Командный режим',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSizes.smallSpace),
                const Text(
                  'Инструкция',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.smallSpace),
            Text(
              _getInstructionText(),
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCounter() {
    // В командном режиме не показываем счетчик
    if (_room?.isTeamMode == true) {
      return const SizedBox.shrink();
    }
    
    final maxSelections = _getMaxSelections();
    return Text(
      'Выбрано игроков: ${_selectedPlayers.length}${maxSelections > 0 ? '/$maxSelections' : ''}',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _selectedPlayers.length > maxSelections 
            ? AppColors.error 
            : AppColors.text,
      ),
    );
  }

  Widget _buildPlayersList() {
    if (_participants.isEmpty) {
      return const Card(
        child: Padding(
          padding: AppSizes.cardPadding,
          child: Center(
            child: Text(
              'Нет игроков для оценки',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final isTeamMode = _room?.isTeamMode == true;
    final maxSelections = _getMaxSelections();
    
    // В командном режиме, если достигнуто максимальное количество лайков, показываем сообщение
    if (isTeamMode && _selectedPlayers.length >= maxSelections) {
      return Card(
        color: AppColors.success.withValues(alpha: 0.1),
        child: Padding(
          padding: AppSizes.cardPadding,
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
                const SizedBox(height: AppSizes.smallSpace),
                Text(
                  'Выбор завершен!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSizes.smallSpace),
                Text(
                  'Вы выбрали ${_selectedPlayers.length} игроков для награждения.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: _participants.map(_buildPlayerCard).toList(),
    );
  }

  Widget _buildPlayerCard(UserModel player) {
    final isSelected = _selectedPlayers.contains(player.id);
    final canSelect = !_isLoading;
    final maxSelections = _getMaxSelections();
    final isTeamMode = _room?.isTeamMode == true;
    
    // В командном режиме, если выбрано максимальное количество, скрываем все
    if (isTeamMode && _selectedPlayers.length >= maxSelections) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.smallSpace),
      child: InkWell(
        onTap: canSelect
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedPlayers.remove(player.id);
                  } else {
                    if (_selectedPlayers.length < maxSelections) {
                      _selectedPlayers.add(player.id);
                    }
                  }
                });
              }
            : null,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: AppSizes.cardPadding,
          child: Row(
            children: [
              // Иконка Like вместо чекбокса
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: canSelect
                      ? () {
                          setState(() {
                            if (isSelected) {
                              _selectedPlayers.remove(player.id);
                            } else {
                              if (_selectedPlayers.length < maxSelections) {
                                _selectedPlayers.add(player.id);
                              }
                            }
                          });
                        }
                      : null,
                  icon: Icon(
                    isSelected ? Icons.favorite : Icons.favorite_border,
                    color: isSelected ? AppColors.error : AppColors.textSecondary,
                    size: 28,
                  ),
                ),
              ),

              const SizedBox(width: AppSizes.smallSpace),

              // Аватар
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: player.photoUrl != null 
                    ? NetworkImage(player.photoUrl!) 
                    : null,
                child: player.photoUrl == null
                    ? Text(
                        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: AppSizes.mediumSpace),

              // Информация об игроке
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${player.gamesPlayed} игр',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Комментарий (опционально)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSizes.smallSpace),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Добавьте комментарий об игре или игроках...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedPlayers.isNotEmpty && !_isLoading
            ? _submitEvaluation
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Сохранить оценки',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
} 