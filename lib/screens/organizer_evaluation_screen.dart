import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';

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

      final firestoreService = ref.read(firestoreServiceProvider);
      
      // Загружаем данные комнаты
      _room = await firestoreService.getRoomById(widget.roomId);
      
      if (_room != null) {
        // Загружаем данные участников
        final participantsFutures = _room!.participants
            .map((userId) => firestoreService.getUserById(userId))
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

      final firestoreService = ref.read(firestoreServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;

      if (currentUser == null || _room == null) {
        throw Exception('Данные пользователя или комнаты не найдены');
      }

      // Сохраняем оценки
      await firestoreService.saveOrganizerEvaluation(
        gameId: widget.roomId,
        organizerId: currentUser.id,
        playerIds: _selectedPlayers.toList(),
        comment: _commentController.text.trim().isNotEmpty 
            ? _commentController.text.trim() 
            : null,
      );

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
    final canSelect = _selectedPlayers.length < 3 || isSelected;

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
                backgroundColor: AppColors.primary,
                child: Text(
                  player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${player.experienceLevel} • ${player.gamesPlayed} игр • ${player.winRate.toStringAsFixed(1)}% побед',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Индикатор статистики
              Column(
                children: [
                  Text(
                    player.totalScore.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'баллов',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 