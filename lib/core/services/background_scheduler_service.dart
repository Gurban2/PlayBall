import 'dart:async';
import '../providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class BackgroundSchedulerService {
  static BackgroundSchedulerService? _instance;
  static BackgroundSchedulerService get instance => _instance ??= BackgroundSchedulerService._();
  
  BackgroundSchedulerService._();
  
  Timer? _timer;
  WidgetRef? _ref;
  
  void start(WidgetRef ref) {
    _ref = ref;
    
    // Запускаем проверку каждые 5 минут
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateGameStatuses();
    });
    
    // Первый запуск сразу
    _updateGameStatuses();
    
    debugPrint('🕒 Фоновый планировщик запущен (проверка каждые 5 минут)');
  }
  
  void stop() {
    _timer?.cancel();
    _timer = null;
    _ref = null;
    debugPrint('🕒 Фоновый планировщик остановлен');
  }
  
  Future<void> _updateGameStatuses() async {
    if (_ref == null) return;
    
    try {
      final roomService = _ref!.read(roomServiceProvider);
      
      debugPrint('🔄 Автоматическая проверка статусов игр...');
      
      // Автоматически запускаем запланированные игры
      await roomService.autoStartScheduledGames();
      
      // Автоматически завершаем активные игры
      await roomService.autoCompleteExpiredGames();
      
      // Отменяем просроченные запланированные игры
      await roomService.autoCancelExpiredPlannedGames();
      
      debugPrint('✅ Автоматическая проверка статусов игр завершена');
    } catch (e) {
      debugPrint('❌ Ошибка автоматической проверки статусов игр: $e');
    }
  }


}

// Провайдер для фонового планировщика
final backgroundSchedulerServiceProvider = Provider<BackgroundSchedulerService>((ref) {
  return BackgroundSchedulerService.instance;
}); 