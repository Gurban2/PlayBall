import 'package:flutter/material.dart';

/// Утилиты для анимаций в приложении
class AnimationUtils {
  
  // Длительности анимаций
  static const Duration fastDuration = Duration(milliseconds: 150);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Кривые анимации
  static const Curve fastOut = Curves.fastOutSlowIn;
  static const Curve elastic = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve smooth = Curves.easeInOut;
  static const Curve gentle = Curves.easeOut;

  /// Анимация появления снизу
  static Widget slideUpAnimation({
    required Widget child,
    required AnimationController controller,
    Duration delay = Duration.zero,
    double begin = 50.0,
  }) {
    final animation = Tween<Offset>(
      begin: Offset(0, begin / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMilliseconds / controller.duration!.inMilliseconds,
        1.0,
        curve: fastOut,
      ),
    ));

    return SlideTransition(
      position: animation,
      child: child,
    );
  }

  /// Анимация появления слева
  static Widget slideLeftAnimation({
    required Widget child,
    required AnimationController controller,
    Duration delay = Duration.zero,
    double begin = 50.0,
  }) {
    final animation = Tween<Offset>(
      begin: Offset(-begin / 100, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMilliseconds / controller.duration!.inMilliseconds,
        1.0,
        curve: fastOut,
      ),
    ));

    return SlideTransition(
      position: animation,
      child: child,
    );
  }

  /// Анимация исчезновения с плавностью
  static Widget fadeAnimation({
    required Widget child,
    required AnimationController controller,
    Duration delay = Duration.zero,
    double begin = 0.0,
    double end = 1.0,
  }) {
    final animation = Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMilliseconds / controller.duration!.inMilliseconds,
        1.0,
        curve: gentle,
      ),
    ));

    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Анимация масштабирования
  static Widget scaleAnimation({
    required Widget child,
    required AnimationController controller,
    Duration delay = Duration.zero,
    double begin = 0.8,
    double end = 1.0,
    Curve curve = smooth,
  }) {
    final animation = Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMilliseconds / controller.duration!.inMilliseconds,
        1.0,
        curve: curve,
      ),
    ));

    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  /// Анимация вращения
  static Widget rotationAnimation({
    required Widget child,
    required AnimationController controller,
    Duration delay = Duration.zero,
    double begin = 0.0,
    double end = 1.0,
  }) {
    final animation = Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMilliseconds / controller.duration!.inMilliseconds,
        1.0,
        curve: smooth,
      ),
    ));

    return RotationTransition(
      turns: animation,
      child: child,
    );
  }

  /// Комбинированная анимация появления (fade + slide + scale)
  static Widget enhancedEntryAnimation({
    required Widget child,
    required AnimationController controller,
    Duration delay = Duration.zero,
    Offset slideOffset = const Offset(0, 0.3),
    double scaleBegin = 0.8,
  }) {
    final interval = Interval(
      delay.inMilliseconds / controller.duration!.inMilliseconds,
      1.0,
      curve: fastOut,
    );

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: interval));

    final slideAnimation = Tween<Offset>(
      begin: slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: interval));

    final scaleAnimation = Tween<double>(
      begin: scaleBegin,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: interval));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      ),
    );
  }

  /// Анимация типа "Hero" для переходов между экранами
  static Widget heroAnimation({
    required Widget child,
    required String tag,
    VoidCallback? onTap,
  }) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  /// Анимация для списков с последовательным появлением элементов
  static Widget staggeredListAnimation({
    required Widget child,
    required int index,
    required AnimationController controller,
    int maxStagger = 5,
  }) {
    final staggerDelay = Duration(
      milliseconds: (index * 100).clamp(0, maxStagger * 100),
    );

    return enhancedEntryAnimation(
      child: child,
      controller: controller,
      delay: staggerDelay,
    );
  }

  /// Пульсирующая анимация для привлечения внимания
  static Widget pulseAnimation({
    required Widget child,
    required AnimationController controller,
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    final animation = Tween<double>(
      begin: minScale,
      end: maxScale,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  /// Анимация покачивания (для ошибок)
  static Widget shakeAnimation({
    required Widget child,
    required AnimationController controller,
    double shakeOffset = 10.0,
  }) {
    final animation = Tween<double>(
      begin: -shakeOffset,
      end: shakeOffset,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticIn,
    ));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, animatedChild) {
        return Transform.translate(
          offset: Offset(animation.value, 0),
          child: child,
        );
      },
    );
  }

  /// Анимация для переключения содержимого
  static Widget switchAnimation({
    required Widget child,
    required AnimationController controller,
    Key? childKey,
  }) {
    return AnimatedSwitcher(
      duration: normalDuration,
      switchInCurve: fastOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: childKey ?? ValueKey(child.runtimeType),
        child: child,
      ),
    );
  }

  /// Создать контроллер анимации с автоматическим запуском
  static AnimationController createAutoStartController({
    required TickerProvider vsync,
    Duration duration = normalDuration,
    bool autoStart = true,
  }) {
    final controller = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    if (autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.forward();
      });
    }

    return controller;
  }

  /// Готовые preset анимации
  static const Map<String, Duration> presetDurations = {
    'instant': Duration(milliseconds: 50),
    'quick': Duration(milliseconds: 150),
    'normal': Duration(milliseconds: 300),
    'slow': Duration(milliseconds: 500),
    'dramatic': Duration(milliseconds: 800),
  };

  static const Map<String, Curve> presetCurves = {
    'linear': Curves.linear,
    'easeIn': Curves.easeIn,
    'easeOut': Curves.easeOut,
    'easeInOut': Curves.easeInOut,
    'fastOut': Curves.fastOutSlowIn,
    'bounce': Curves.bounceOut,
    'elastic': Curves.elasticOut,
    'overshoot': Curves.elasticInOut,
  };

  /// Получить preset анимацию
  static Duration getPresetDuration(String preset) {
    return presetDurations[preset] ?? normalDuration;
  }

  static Curve getPresetCurve(String preset) {
    return presetCurves[preset] ?? smooth;
  }

  /// Анимация для нотификаций/снэкбаров
  static Widget notificationSlideAnimation({
    required Widget child,
    required AnimationController controller,
    bool fromTop = true,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: fromTop ? const Offset(0, -1) : const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: elastic,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: child,
    );
  }

  /// Анимация для модальных окон
  static Widget modalAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    final scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: elastic,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: gentle,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }

  /// Анимация для загрузчиков
  static Widget loadingAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    controller.repeat();
    
    return RotationTransition(
      turns: controller,
      child: child,
    );
  }
} 