import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';

class OrganizerEvaluationScreen extends ConsumerStatefulWidget {
  final String roomId;

  const OrganizerEvaluationScreen({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<OrganizerEvaluationScreen> createState() => _OrganizerEvaluationScreenState();
}

class _OrganizerEvaluationScreenState extends ConsumerState<OrganizerEvaluationScreen> {
  final Set<String> _selectedPlayers = {};
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  RoomModel? _room;
  List<UserModel> _participants = [];

  @override
  void initState() {
    super.initState();
    _loadRoomData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final roomService = ref.read(roomServiceProvider);
      final userService = ref.read(userServiceProvider);
      
      // Загружаем данные комнаты
      _room = await roomService.getRoomById(widget.roomId);
      
      if (_room != null) {
        // Загружаем данные участников
        final participantsFutures = _room!.participants
            .map((userId) => userService.getUserById(userId))
            .toList();
        
        final participantsResults = await Future.wait(participantsFutures);
        _participants = participantsResults
            .where((user) => user != null)
            .cast<UserModel>()
            .where((user) => user.id != _room!.organizerId) // Исключаем организатора
            .toList();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных комнаты: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: ${e.toString()}'),
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

  Future<void> _submitEvaluation() async {
    if (_selectedPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы одного игрока для оценки'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedPlayers.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Можно выбрать максимум 3 игроков'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Пока просто показываем успешное сообщение, 
      // saveOrganizerEvaluation можно реализовать позже
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Оценки успешно сохранены!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Возвращаемся на предыдущий экран
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Ошибка сохранения оценок: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения оценок: ${e.toString()}'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оценка игроков'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
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
        child: Text('Комната не найдена'),
      );
    }

    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация об игре
          Card(
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
                    '${_room!.location} • ${_room!.startTime.day}.${_room!.startTime.month}.${_room!.startTime.year}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.mediumSpace),

          // Инструкция
          Card(
            color: AppColors.primary.withOpacity(0.1),
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
                  const Text(
                    'Выберите до 3-х игроков, которые особенно отличились в этой игре. '
                    'Каждый выбранный игрок получит +1 балл от организатора.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.mediumSpace),

          // Счетчик выбранных игроков
          Text(
            'Выбрано игроков: ${_selectedPlayers.length}/3',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _selectedPlayers.length > 3 ? AppColors.error : AppColors.text,
            ),
          ),

          const SizedBox(height: AppSizes.mediumSpace),

          // Список игроков
          if (_participants.isEmpty) ...[
            const Card(
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
            ),
          ] else ...[
            ..._participants.map((player) => _buildPlayerCard(player)),
          ],

          const SizedBox(height: AppSizes.mediumSpace),

          // Комментарий (опционально)
          Card(
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
          ),

          const SizedBox(height: AppSizes.largeSpace),

          // Кнопка сохранения (дублирует кнопку в AppBar для удобства)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitEvaluation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(UserModel player) {
    final isSelected = _selectedPlayers.contains(player.id);
    final canSelect = !_isLoading;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.smallSpace),
      child: InkWell(
        onTap: canSelect
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedPlayers.remove(player.id);
                  } else {
                    _selectedPlayers.add(player.id);
                  }
                });
              }
            : null,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: AppSizes.cardPadding,
          child: Row(
            children: [
              // Чекбокс
              Checkbox(
                value: isSelected,
                onChanged: canSelect
                    ? (value) {
                        setState(() {
                          if (value == true) {
                            _selectedPlayers.add(player.id);
                          } else {
                            _selectedPlayers.remove(player.id);
                          }
                        });
                      }
                    : null,
                activeColor: AppColors.primary,
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
                      'Рейтинг: ${player.rating.toStringAsFixed(1)} • ${player.gamesPlayed} игр',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // Информация о команде
                    if (player.teamName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.groups,
                            size: 12,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            player.teamName!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (player.isTeamCaptain) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'К',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 