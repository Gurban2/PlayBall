import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../utils/permissions_manager.dart';

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
    final actions = currentUser != null 
        ? PermissionsManager.getRoomActions(currentUser!, room)
        : <String>[];

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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
} 