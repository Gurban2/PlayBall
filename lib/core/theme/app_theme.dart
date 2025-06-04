import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/constants.dart';

/// Конфигурация темы приложения с Material Design 3
class AppTheme {
  // Основные цвета - более мягкие и сбалансированные
  static const Color _primaryColor = Color(0xFF6366F1); // Индиго
  static const Color _secondaryColor = Color(0xFF8B5CF6); // Фиолетовый
  static const Color _tertiaryColor = Color(0xFF06B6D4); // Голубой
  static const Color _errorColor = Color(0xFFEF4444); // Красный
  static const Color _successColor = Color(0xFF10B981); // Зеленый
  static const Color _warningColor = Color(0xFFF59E0B); // Желтый
  
  /// Светлая тема
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      primary: _primaryColor,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE0E2FE),
      onPrimaryContainer: const Color(0xFF1E1B4B),
      secondary: _secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF3F0FF),
      onSecondaryContainer: const Color(0xFF2D1B69),
      tertiary: _tertiaryColor,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFE6FFFA),
      onTertiaryContainer: const Color(0xFF0F172A),
      error: _errorColor,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEECEB),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: const Color(0xFFFCFCFD),
      onSurface: const Color(0xFF1F2937),
      surfaceVariant: const Color(0xFFF8FAFC),
      onSurfaceVariant: const Color(0xFF6B7280),
      outline: const Color(0xFFD1D5DB),
      outlineVariant: const Color(0xFFE5E7EB),
      shadow: Colors.black.withOpacity(0.05),
      scrim: Colors.black.withOpacity(0.15),
      inverseSurface: const Color(0xFF374151),
      onInverseSurface: const Color(0xFFF9FAFB),
      inversePrimary: const Color(0xFFA5B4FC),
      background: const Color(0xFFFEFEFE),
      onBackground: const Color(0xFF1F2937),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      
      // === ТЕКСТОВАЯ ТЕМА ===
      textTheme: _buildTextTheme(colorScheme),
      
      // === КОМПОНЕНТЫ ===
      appBarTheme: _buildAppBarTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      floatingActionButtonTheme: _buildFABTheme(colorScheme),
      inputDecorationTheme: _buildInputTheme(colorScheme),
      bottomNavigationBarTheme: _buildBottomNavTheme(colorScheme),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      dividerTheme: _buildDividerTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
      
      // === АНИМАЦИИ ===
      pageTransitionsTheme: _buildPageTransitionsTheme(),
      
      // === ДРУГИЕ НАСТРОЙКИ ===
      splashColor: colorScheme.primary.withOpacity(0.08),
      highlightColor: colorScheme.primary.withOpacity(0.04),
      focusColor: colorScheme.primary.withOpacity(0.10),
      hoverColor: colorScheme.primary.withOpacity(0.06),
    );
  }

  /// Темная тема
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
      primary: const Color(0xFFA5B4FC), // Светлый индиго
      onPrimary: const Color(0xFF1E1B4B),
      primaryContainer: const Color(0xFF3730A3),
      onPrimaryContainer: const Color(0xFFE0E2FE),
      secondary: const Color(0xFFC4B5FD), // Светлый фиолетовый
      onSecondary: const Color(0xFF2D1B69),
      secondaryContainer: const Color(0xFF6D28D9),
      onSecondaryContainer: const Color(0xFFF3F0FF),
      tertiary: const Color(0xFF67E8F9), // Светлый голубой
      onTertiary: const Color(0xFF0F172A),
      tertiaryContainer: const Color(0xFF0E7490),
      onTertiaryContainer: const Color(0xFFE6FFFA),
      error: const Color(0xFFFCA5A5), // Светлый красный
      onError: const Color(0xFF7F1D1D),
      errorContainer: const Color(0xFFDC2626),
      onErrorContainer: const Color(0xFFFEECEB),
      surface: const Color(0xFF1F2937), // Темно-серый
      onSurface: const Color(0xFFF9FAFB), // Светлый текст
      surfaceVariant: const Color(0xFF374151),
      onSurfaceVariant: const Color(0xFFD1D5DB),
      outline: const Color(0xFF6B7280),
      outlineVariant: const Color(0xFF4B5563),
      shadow: Colors.black.withOpacity(0.3),
      scrim: Colors.black.withOpacity(0.5),
      inverseSurface: const Color(0xFFF9FAFB),
      onInverseSurface: const Color(0xFF374151),
      inversePrimary: _primaryColor,
      background: const Color(0xFF111827), // Очень темный фон
      onBackground: const Color(0xFFF9FAFB), // Светлый текст на фоне
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: _buildAppBarTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      floatingActionButtonTheme: _buildFABTheme(colorScheme),
      inputDecorationTheme: _buildInputTheme(colorScheme),
      bottomNavigationBarTheme: _buildBottomNavTheme(colorScheme),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      dividerTheme: _buildDividerTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
      
      pageTransitionsTheme: _buildPageTransitionsTheme(),
      
      splashColor: colorScheme.primary.withOpacity(0.08),
      highlightColor: colorScheme.primary.withOpacity(0.04),
      focusColor: colorScheme.primary.withOpacity(0.10),
      hoverColor: colorScheme.primary.withOpacity(0.06),
    );
  }

  // === СТРОИТЕЛЬНЫЕ МЕТОДЫ ===

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Дисплейные стили (большие заголовки)
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      
      // Заголовки
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      
      // Заголовки среднего размера
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      
      // Лейблы
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      
      // Тело текста
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurface.withOpacity(0.7),
        height: 1.3,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 4,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      centerTitle: false,
      systemOverlayStyle: colorScheme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    );
  }

  static CardTheme _buildCardTheme(ColorScheme colorScheme) {
    return CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shadowColor: colorScheme.shadow,
      margin: const EdgeInsets.all(4),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        surfaceTintColor: colorScheme.surfaceTint,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(64, 40),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        surfaceTintColor: colorScheme.surfaceTint,
        side: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFABTheme(ColorScheme colorScheme) {
    return FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 3,
      focusElevation: 4,
      hoverElevation: 4,
      highlightElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static InputDecorationTheme _buildInputTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 16,
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        fontSize: 16,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme(ColorScheme colorScheme) {
    return BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme(ColorScheme colorScheme) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      indicatorColor: colorScheme.secondaryContainer,
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return IconThemeData(color: colorScheme.onSecondaryContainer);
        }
        return IconThemeData(color: colorScheme.onSurface.withOpacity(0.6));
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return TextStyle(
            color: colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        );
      }),
      elevation: 3,
      height: 80,
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceVariant,
      deleteIconColor: colorScheme.onSurfaceVariant,
      disabledColor: colorScheme.onSurface.withOpacity(0.12),
      selectedColor: colorScheme.secondaryContainer,
      secondarySelectedColor: colorScheme.secondaryContainer,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: colorScheme.surfaceTint,
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: TextStyle(
        color: colorScheme.onSecondaryContainer,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(color: colorScheme.outline),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 18,
      ),
    );
  }

  static DividerThemeData _buildDividerTheme(ColorScheme colorScheme) {
    return DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: colorScheme.onInverseSurface,
        fontSize: 14,
      ),
      actionTextColor: colorScheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 3,
    );
  }

  static DialogTheme _buildDialogTheme(ColorScheme colorScheme) {
    return DialogTheme(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 16,
        height: 1.5,
      ),
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: colorScheme.onSurfaceVariant.withOpacity(0.4),
      dragHandleSize: const Size(32, 4),
    );
  }

  static PageTransitionsTheme _buildPageTransitionsTheme() {
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    );
  }

  // === ДОПОЛНИТЕЛЬНЫЕ ЦВЕТА ===

  /// Цвета состояний - более мягкие
  static const MaterialColor successColor = MaterialColor(0xFF10B981, {
    50: Color(0xFFECFDF5),
    100: Color(0xFFD1FAE5),
    200: Color(0xFFA7F3D0),
    300: Color(0xFF6EE7B7),
    400: Color(0xFF34D399),
    500: Color(0xFF10B981),
    600: Color(0xFF059669),
    700: Color(0xFF047857),
    800: Color(0xFF065F46),
    900: Color(0xFF064E3B),
  });

  static const MaterialColor warningColor = MaterialColor(0xFFF59E0B, {
    50: Color(0xFFFEFBEA),
    100: Color(0xFFFEF3C7),
    200: Color(0xFFFDE68A),
    300: Color(0xFFFCD34D),
    400: Color(0xFFFBBF24),
    500: Color(0xFFF59E0B),
    600: Color(0xFFD97706),
    700: Color(0xFFB45309),
    800: Color(0xFF92400E),
    900: Color(0xFF78350F),
  });

  /// Применить системную тему на статус-бар
  static void setSystemUIOverlayStyle(ColorScheme colorScheme) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: colorScheme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: colorScheme.brightness,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness: colorScheme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }
} 