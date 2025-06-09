import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../auth/domain/entities/user_model.dart';
import '../../../rooms/domain/entities/room_model.dart';
import '../../domain/entities/user_team_model.dart';

class TeamWinnerSelectorWidget extends ConsumerStatefulWidget {
  final RoomModel room;
  final UserModel organizer;
  final List<UserTeamModel> participatingTeams;
  final VoidCallback? onWinnerSelected;

  const TeamWinnerSelectorWidget({
    super.key,
    required this.room,
    required this.organizer,
    required this.participatingTeams,
    this.onWinnerSelected,
  });

  @override
  ConsumerState<TeamWinnerSelectorWidget> createState() => _TeamWinnerSelectorWidgetState();
}

class _TeamWinnerSelectorWidgetState extends ConsumerState<TeamWinnerSelectorWidget> {
  String? selectedTeamId;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Проверяем, была ли уже выбрана команда-победитель
    final gameWinnerAsync = ref.watch(gameWinnerProvider(widget.room.id));

    return gameWinnerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(),
      data: (existingWinner) {
        if (existingWinner != null) {
          return _buildWinnerAlreadySelectedWidget(existingWinner);
        }

        // Если команды нет или только одна команда - не показываем селектор
        if (widget.participatingTeams.length < 2) {
          return _buildNotEnoughTeamsWidget();
        }

        return _buildWinnerSelectorWidget();
      },
    );
  }

  Widget _buildWinnerSelectorWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Выберите команду-победителя',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Игра "${widget.room.title}" завершена',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Список команд для выбора
          ...widget.participatingTeams.map((team) => _buildTeamOption(team)),
          
          const SizedBox(height: 20),
          
          // Кнопка подтверждения
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedTeamId != null && !isLoading 
                  ? _selectWinner 
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Объявить победителя',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamOption(UserTeamModel team) {
    final isSelected = selectedTeamId == team.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () {
            setState(() {
              selectedTeamId = team.id;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? AppColors.primary
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Радио кнопка
                Radio<String>(
                  value: team.id,
                  groupValue: selectedTeamId,
                  onChanged: isLoading ? null : (value) {
                    setState(() {
                      selectedTeamId = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                
                const SizedBox(width: 12),
                
                // Информация о команде
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${team.members.length} игроков',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${team.teamScore} баллов',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Иконка выбора
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerAlreadySelectedWidget(dynamic winner) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Команда-победитель определена!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'Победила команда: ${winner.winnerTeamName ?? "Неизвестная команда"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotEnoughTeamsWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey[600],
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Недостаточно команд для выбора победителя',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Для выбора команды-победителя нужно минимум 2 команды',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ошибка загрузки данных',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Не удалось загрузить информацию о победителе',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _selectWinner() async {
    if (selectedTeamId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final victoryService = ref.read(teamVictoryServiceProvider);
      
      await victoryService.declareTeamWinner(
        gameId: widget.room.id,
        gameTitle: widget.room.title,
        gameDate: widget.room.startTime,
        winnerTeamId: selectedTeamId!,
        organizer: widget.organizer,
        pointsForWin: widget.room.isTeamMode ? 1 : 2, // 1 балл в командном режиме, 2 в обычном
      );

      if (mounted) {
        // Показываем уведомление об успехе
        ErrorHandler.showSuccess(context, '🏆 Команда-победитель успешно выбрана!');

        // Вызываем колбэк
        widget.onWinnerSelected?.call();

        // Обновляем провайдеры
        ref.invalidate(gameWinnerProvider(widget.room.id));
        ref.invalidate(topTeamsProvider);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, '❌ Ошибка: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
} 