import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/animation_utils.dart';
import '../../shared/widgets/enhanced_widgets.dart';
import '../../features/notifications/data/datasources/notification_demo_service.dart';
import '../../features/notifications/data/datasources/game_notification_service.dart';
import '../../features/auth/domain/entities/user_model.dart';

/// Демонстрационный экран дизайн-системы Material Design 3
class DesignDemoScreen extends StatefulWidget {
  const DesignDemoScreen({super.key});

  @override
  State<DesignDemoScreen> createState() => _DesignDemoScreenState();
}

class _DesignDemoScreenState extends State<DesignDemoScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  
  bool _isDarkMode = false;
  bool _isLoading = false;
  String _selectedTab = 'buttons';
  
  final List<String> _tabs = [
    'buttons',
    'cards',
    'inputs',
    'animations',
    'notifications',
  ];

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 Material Design 3'),
        actions: [
          // Переключатель темы
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
              // TODO: Здесь можно добавить переключение темы в приложении
            },
            tooltip: 'Переключить тему',
          ),
          
          // Кнопка обновления
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _mainController.reset();
              _mainController.forward();
            },
            tooltip: 'Обновить анимации',
          ),
        ],
      ),
      
      body: Column(
        children: [
          // Табы
          _buildTabBar(),
          
          // Содержимое
          Expanded(
            child: AnimationUtils.fadeAnimation(
              child: _buildTabContent(),
              controller: _mainController,
            ),
          ),
        ],
      ),
      
      floatingActionButton: AnimationUtils.scaleAnimation(
        controller: _mainController,
        delay: const Duration(milliseconds: 600),
        child: FloatingActionButton.extended(
          onPressed: _showSuccessMessage,
          icon: const Icon(Icons.star),
          label: const Text('Круто!'),
        ),
      ),
    );
  }

  /// Строка табов
  Widget _buildTabBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = tab == _selectedTab;
          
          return AnimationUtils.slideLeftAnimation(
            controller: _mainController,
            delay: Duration(milliseconds: index * 100),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getTabTitle(tab)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedTab = tab;
                    });
                  }
                },
                avatar: Icon(_getTabIcon(tab), size: 16),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Содержимое вкладки
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'buttons':
        return _buildButtonsDemo();
      case 'cards':
        return _buildCardsDemo();
      case 'inputs':
        return _buildInputsDemo();
      case 'animations':
        return _buildAnimationsDemo();
      case 'notifications':
        return _buildNotificationsDemo();
      default:
        return const Center(child: Text('Неизвестная вкладка'));
    }
  }

  /// Демо кнопок
  Widget _buildButtonsDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Кнопки разных типов'),
          const SizedBox(height: 16),
          
          // Основные кнопки
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              EnhancedButton(
                text: 'Главная',
                icon: Icons.home,
                onPressed: () => _showMessage('Главная кнопка'),
              ),
              EnhancedButton(
                text: 'Создать',
                icon: Icons.add,
                type: ButtonType.secondary,
                onPressed: () => _showMessage('Создать'),
              ),
              EnhancedButton(
                text: 'Удалить',
                icon: Icons.delete,
                type: ButtonType.tertiary,
                customColor: Theme.of(context).colorScheme.error,
                onPressed: () => _showMessage('Удалить'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Кнопки разных размеров
          _buildSectionHeader('Размеры кнопок'),
          const SizedBox(height: 16),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EnhancedButton(
                text: 'Маленькая',
                icon: Icons.star,
                size: ButtonSize.small,
                onPressed: () => _showMessage('Маленькая'),
              ),
              const SizedBox(height: 8),
              EnhancedButton(
                text: 'Средняя',
                icon: Icons.star,
                size: ButtonSize.medium,
                onPressed: () => _showMessage('Средняя'),
              ),
              const SizedBox(height: 8),
              EnhancedButton(
                text: 'Большая',
                icon: Icons.star,
                size: ButtonSize.large,
                onPressed: () => _showMessage('Большая'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Кнопка с загрузкой
          _buildSectionHeader('Состояния кнопок'),
          const SizedBox(height: 16),
          
          EnhancedButton(
            text: 'Загрузка...',
            icon: Icons.download,
            isLoading: _isLoading,
            isFullWidth: true,
            onPressed: _simulateLoading,
          ),
        ],
      ),
    );
  }

  /// Демо карточек
  Widget _buildCardsDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Статистические карточки'),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              StatsCard(
                title: 'Игры сыграны',
                value: '42',
                icon: Icons.sports_volleyball,
                color: Theme.of(context).colorScheme.primary,
                subtitle: '+5 за неделю',
                onTap: () => _showMessage('Статистика игр'),
              ),
              StatsCard(
                title: 'Побед',
                value: '28',
                icon: Icons.emoji_events,
                color: AppTheme.successColor,
                subtitle: '66% побед',
                onTap: () => _showMessage('Статистика побед'),
              ),
              StatsCard(
                title: 'Друзья',
                value: '15',
                icon: Icons.people,
                color: Theme.of(context).colorScheme.secondary,
                subtitle: '3 новых',
                onTap: () => _showMessage('Список друзей'),
              ),
              StatsCard(
                title: 'Рейтинг',
                value: '1250',
                icon: Icons.trending_up,
                color: AppTheme.warningColor,
                subtitle: '+50 очков',
                onTap: () => _showMessage('Рейтинг'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('Интерактивные карточки'),
          const SizedBox(height: 16),
          
          EnhancedCard(
            onTap: () => _showMessage('Карточка нажата'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notification_important,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Уведомления',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Настройте уведомления для получения актуальной информации о ваших играх.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Демо полей ввода
  Widget _buildInputsDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Поля ввода'),
          const SizedBox(height: 16),
          
          const EnhancedTextField(
            label: 'Имя пользователя',
            hint: 'Введите ваше имя',
            prefixIcon: Icons.person,
            isRequired: true,
          ),
          
          const SizedBox(height: 16),
          
          const EnhancedTextField(
            label: 'Email',
            hint: 'example@mail.com',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            helperText: 'Мы не будем спамить',
          ),
          
          const SizedBox(height: 16),
          
          const EnhancedTextField(
            label: 'Пароль',
            hint: 'Введите пароль',
            prefixIcon: Icons.lock,
            suffixIcon: Icons.visibility_off,
            obscureText: true,
            isRequired: true,
          ),
          
          const SizedBox(height: 16),
          
          const EnhancedTextField(
            label: 'Описание',
            hint: 'Расскажите о себе...',
            prefixIcon: Icons.description,
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          const EnhancedTextField(
            label: 'С ошибкой',
            hint: 'Это поле с ошибкой',
            prefixIcon: Icons.error,
            errorText: 'Это сообщение об ошибке',
          ),
        ],
      ),
    );
  }

  /// Демо анимаций
  Widget _buildAnimationsDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Анимации'),
          const SizedBox(height: 16),
          
          // Пульсирующая анимация
          Center(
            child: AnimationUtils.pulseAnimation(
              controller: _pulseController,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Вращающаяся анимация
          Center(
            child: AnimationUtils.rotationAnimation(
              controller: _rotationController,
              child: Icon(
                Icons.sports_volleyball,
                size: 60,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Разные типы загрузки
          _buildSectionHeader('Индикаторы загрузки'),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const EnhancedLoadingIndicator(
                    style: LoadingStyle.circular,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Круговой',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Column(
                children: [
                  const EnhancedLoadingIndicator(
                    style: LoadingStyle.pulse,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Пульс',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Column(
                children: [
                  const EnhancedLoadingIndicator(
                    style: LoadingStyle.dots,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Точки',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Кнопка для демонстрации shake анимации
          Center(
            child: EnhancedButton(
              text: 'Тряска!',
              icon: Icons.vibration,
              onPressed: _triggerShakeAnimation,
            ),
          ),
        ],
      ),
    );
  }

  /// Демо уведомлений
  Widget _buildNotificationsDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Тестирование уведомлений'),
          const SizedBox(height: 16),
          
          Text(
            'Здесь вы можете создать тестовые уведомления для проверки системы.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          const SizedBox(height: 24),
          
          EnhancedButton(
            text: 'Создать базовые уведомления',
            icon: Icons.notification_add,
            isFullWidth: true,
            onPressed: _createDemoNotifications,
          ),
          
          const SizedBox(height: 12),
          
          EnhancedButton(
            text: 'Создать разнообразные уведомления',
            icon: Icons.notifications_active,
            type: ButtonType.secondary,
            isFullWidth: true,
            onPressed: _createVarietyNotifications,
          ),
          
          const SizedBox(height: 12),
          
          EnhancedButton(
            text: 'Real-time симуляция',
            icon: Icons.stream,
            type: ButtonType.tertiary,
            isFullWidth: true,
            onPressed: _simulateRealTimeNotifications,
          ),
          
          const SizedBox(height: 24),
          
          const Divider(),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('Типы снэкбаров'),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              EnhancedButton(
                text: 'Успех',
                icon: Icons.check_circle,
                customColor: AppTheme.successColor,
                onPressed: () => _showSuccessMessage(),
              ),
              EnhancedButton(
                text: 'Ошибка',
                icon: Icons.error,
                customColor: Theme.of(context).colorScheme.error,
                onPressed: () => _showErrorMessage(),
              ),
              EnhancedButton(
                text: 'Предупреждение',
                icon: Icons.warning,
                customColor: AppTheme.warningColor,
                onPressed: () => _showWarningMessage(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Заголовок секции
  Widget _buildSectionHeader(String title) {
    return AnimationUtils.slideUpAnimation(
      controller: _mainController,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Вспомогательные методы

  String _getTabTitle(String tab) {
    switch (tab) {
      case 'buttons':
        return 'Кнопки';
      case 'cards':
        return 'Карточки';
      case 'inputs':
        return 'Поля';
      case 'animations':
        return 'Анимации';
      case 'notifications':
        return 'Уведомления';
      default:
        return tab;
    }
  }

  IconData _getTabIcon(String tab) {
    switch (tab) {
      case 'buttons':
        return Icons.smart_button;
      case 'cards':
        return Icons.view_agenda;
      case 'inputs':
        return Icons.input;
      case 'animations':
        return Icons.animation;
      case 'notifications':
        return Icons.notifications;
      default:
        return Icons.help;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Операция выполнена успешно!'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Text('Произошла ошибка!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWarningMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 12),
            Text('Внимание! Это предупреждение.'),
          ],
        ),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _simulateLoading() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    _showSuccessMessage();
  }

  void _triggerShakeAnimation() {
    // TODO: Реализовать shake анимацию
    _showMessage('Тряска! 🫨');
  }

  Future<void> _createDemoNotifications() async {
    try {
      // Создаем фиктивного пользователя для демо
      final demoUser = UserModel(
        id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'demo@playball.com',
        name: 'Демо Пользователь',
        role: UserRole.user,
        createdAt: DateTime.now(),
        gamesPlayed: 0,
        wins: 0,
        losses: 0,
      );

      final notificationService = GameNotificationService();
      final demoService = NotificationDemoService(notificationService);
      
      await demoService.createDemoNotifications(demoUser);
      
      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage();
    }
  }

  Future<void> _createVarietyNotifications() async {
    try {
      final demoUser = UserModel(
        id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'demo@playball.com',
        name: 'Демо Пользователь',
        role: UserRole.user,
        createdAt: DateTime.now(),
        gamesPlayed: 0,
        wins: 0,
        losses: 0,
      );

      final notificationService = GameNotificationService();
      final demoService = NotificationDemoService(notificationService);
      
      await demoService.createVarietyDemoNotifications(demoUser);
      
      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage();
    }
  }

  Future<void> _simulateRealTimeNotifications() async {
    try {
      final demoUser = UserModel(
        id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'demo@playball.com',
        name: 'Демо Пользователь',
        role: UserRole.user,
        createdAt: DateTime.now(),
        gamesPlayed: 0,
        wins: 0,
        losses: 0,
      );

      final notificationService = GameNotificationService();
      final demoService = NotificationDemoService(notificationService);
      
      _showMessage('Симуляция запущена...');
      await demoService.simulateRealTimeNotifications(demoUser);
      
      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage();
    }
  }
} 