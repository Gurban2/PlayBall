import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../features/auth/domain/entities/user_model.dart';
import '../../../features/rooms/domain/entities/room_model.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final UserModel? currentUser;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onEdit;

  const RoomCard({
    super.key,
    required this.room,
    this.currentUser,
    this.onTap,
    this.onJoin,
    this.onLeave,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = <String>[];
    final isToday = _isSameDay(room.startTime, DateTime.now());

    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Бейдж "Today" если игра сегодня
                  if (isToday) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _StatusChip(room.status),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Детали
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 4),
                  Expanded(child: Text(room.location)),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 4),
                  Text('${room.participants.length}/${room.maxParticipants}'),
                  const Spacer(),
                  if (room.pricePerPerson > 0)
                    Text('${room.pricePerPerson.toInt()} ₽'),
                ],
              ),
              
              // Кнопки действий
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: actions.map((action) {
                    switch (action) {
                      case 'join':
                        return ElevatedButton(
                          onPressed: onJoin,
                          child: const Text('Присоединиться'),
                        );
                      case 'leave':
                        return OutlinedButton(
                          onPressed: onLeave,
                          child: const Text('Выйти'),
                        );
                      case 'edit':
                        return IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit),
                        );
                      default:
                        return const SizedBox.shrink();
                    }
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Функция для проверки, является ли дата сегодняшней
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}

class _StatusChip extends StatelessWidget {
  final RoomStatus status;
  
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      RoomStatus.planned => ('Планируется', Colors.blue),
      RoomStatus.active => ('Активна', Colors.green),
      RoomStatus.completed => ('Завершена', Colors.grey),
      RoomStatus.cancelled => ('Отменена', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
} 