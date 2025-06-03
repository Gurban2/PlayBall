import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class ActiveGamesTab extends StatelessWidget {
  final int activeGamesCount;
  final VoidCallback onRefresh;

  const ActiveGamesTab({
    super.key,
    required this.activeGamesCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (activeGamesCount == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Нет активных игр',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Активные игры будут отображаться здесь',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeGamesCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.play_arrow, color: AppColors.success),
              title: Text('Активная игра ${index + 1}'),
              subtitle: const Text('Статус: В процессе'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Навигация к деталям игры
              },
            ),
          ),
        );
      },
    );
  }
} 