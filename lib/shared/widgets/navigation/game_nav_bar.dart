import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

enum GameNavTab { all, live, upcoming, finished }

class GameNavBar extends ConsumerStatefulWidget {
  final GameNavTab activeTab;
  final Function(GameNavTab) onTabChanged;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onSortPressed;
  final bool showSortOptions;

  const GameNavBar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.onNotificationsPressed,
    required this.onSearchPressed,
    required this.onSortPressed,
    this.showSortOptions = false,
  });

  @override
  ConsumerState<GameNavBar> createState() => _GameNavBarState();
}

class _GameNavBarState extends ConsumerState<GameNavBar> {
  
  Widget _buildNotificationIconWidget() {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) {
      return _buildActionIconWithBadge(Icons.notifications_outlined, widget.onNotificationsPressed, count: 0);
    }

    // Слушаем изменения в реальном времени
    final notificationCountAsync = ref.watch(totalUnreadNotificationsCountProvider(currentUser.id));
    
    return notificationCountAsync.when(
      data: (count) => _buildActionIconWithBadge(
        Icons.notifications_outlined,
        widget.onNotificationsPressed,
        count: count,
      ),
      loading: () => _buildActionIconWithBadge(
        Icons.notifications_outlined,
        widget.onNotificationsPressed,
        count: 0,
      ),
      error: (_, __) => _buildActionIconWithBadge(
        Icons.notifications_outlined,
        widget.onNotificationsPressed,
        count: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // Tabs container - гибкий размер
          Expanded(
            child: Container(
              height: 24,
              constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab(GameNavTab.all, 'All'),
                  _buildTab(GameNavTab.live, 'Live'),
                  _buildTab(GameNavTab.upcoming, 'Up'),
                  _buildTab(GameNavTab.finished, 'End'),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Action icons - убрали дублирующую иконку сортировки
          _buildNotificationIconWidget(),
          const SizedBox(width: 8),
          _buildActionIcon(Icons.search, widget.onSearchPressed),
          const SizedBox(width: 8),
          _buildActionIcon(
            widget.showSortOptions ? Icons.sort : Icons.sort_outlined,
            widget.onSortPressed,
            isActive: widget.showSortOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(GameNavTab tab, String text) {
    final isActive = widget.activeTab == tab;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabChanged(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withValues(alpha: 0.9) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.black87 : Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildActionIconWithBadge(IconData icon, VoidCallback onPressed, {int count = 0, bool isActive = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onPressed, {bool isActive = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }
} 