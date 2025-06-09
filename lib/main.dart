import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';

import 'core/services/background_scheduler_service.dart';
import 'core/constants/constants.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Загружаем .env файл для AWS ключей
  try {
    await dotenv.load(fileName: ".env");
    if (kDebugMode) {
      debugPrint('✅ .env файл загружен успешно');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Ошибка загрузки .env файла: $e');
    }
  }
  
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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Запускаем фоновый планировщик
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(backgroundSchedulerServiceProvider).start(ref);
        if (kDebugMode) {
          debugPrint('✅ Фоновый планировщик запущен');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Ошибка запуска фонового планировщика: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    ref.read(backgroundSchedulerServiceProvider).stop();
    super.dispose();
  }

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