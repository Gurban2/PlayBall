import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/constants/constants.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/screens/firebase_test_screen.dart';
import 'features/design_demo/design_demo_screen.dart';
import 'shared/widgets/enhanced_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Блокируем ориентацию экрана в вертикальном положении
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Firebase инициализирован успешно
  if (kDebugMode) {
    debugPrint('✅ Firebase инициализирован успешно');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      
      // === ПРИМЕНЯЕМ НОВУЮ ТЕМУ MATERIAL DESIGN 3 ===
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Автоматическое переключение темы
      
      // Настройки приложения
      debugShowCheckedModeBanner: false,
      
      routerConfig: AppRouter.router,
      
      // Применяем системные цвета на статус-бар
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        AppTheme.setSystemUIOverlayStyle(colorScheme);
        return child!;
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.sports_volleyball,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('PlayBall'),
          ],
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с анимацией
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _animationController.value)),
                  child: Opacity(
                    opacity: _animationController.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Добро пожаловать! 🏐',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Приложение для организации волейбольных игр с современным дизайном',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Статистические карточки
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 100 * (1 - _animationController.value)),
                  child: Opacity(
                    opacity: _animationController.value,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        StatsCard(
                          title: 'Активные игры',
                          value: '12',
                          icon: Icons.sports_volleyball,
                          color: Theme.of(context).colorScheme.primary,
                          subtitle: 'Сегодня',
                        ),
                        StatsCard(
                          title: 'Пользователи',
                          value: '2.4K',
                          icon: Icons.people,
                          color: AppTheme.successColor,
                          subtitle: 'Онлайн',
                        ),
                        StatsCard(
                          title: 'Команды',
                          value: '89',
                          icon: Icons.groups,
                          color: Theme.of(context).colorScheme.secondary,
                          subtitle: 'Созданы',
                        ),
                        StatsCard(
                          title: 'Турниры',
                          value: '24',
                          icon: Icons.emoji_events,
                          color: AppTheme.warningColor,
                          subtitle: 'В этом месяце',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Действия
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 150 * (1 - _animationController.value)),
                  child: Opacity(
                    opacity: _animationController.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Быстрые действия',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        EnhancedButton(
                          text: 'Войти в приложение',
                          icon: Icons.login,
                          isFullWidth: true,
                          onPressed: () {
                            // TODO: Добавить навигацию на экран авторизации
                            _showMessage('Переход на экран авторизации');
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        EnhancedButton(
                          text: 'Дизайн-система',
                          icon: Icons.palette,
                          type: ButtonType.secondary,
                          isFullWidth: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DesignDemoScreen(),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        EnhancedButton(
                          text: 'Тестировать Firebase',
                          icon: Icons.cloud,
                          type: ButtonType.tertiary,
                          customColor: Colors.orange,
                          isFullWidth: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FirebaseTestScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Информационная карточка
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final delay = const Duration(milliseconds: 400);
                final delayedAnimation = Tween<double>(
                  begin: 0,
                  end: 1,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    delay.inMilliseconds / _animationController.duration!.inMilliseconds,
                    1.0,
                    curve: Curves.easeOut,
                  ),
                ));
                
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - delayedAnimation.value)),
                  child: Opacity(
                    opacity: delayedAnimation.value,
                    child: EnhancedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Новый дизайн!',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Material Design 3',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Приложение обновлено с новой системой дизайна Material Design 3. '
                            'Наслаждайтесь улучшенным интерфейсом, современными анимациями и '
                            'адаптивными цветами.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 