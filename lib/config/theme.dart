import 'package:flutter/material.dart';

// ============ DARK THEME COLORS ============
class AppColorsDark {
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFEC4899);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  static const Color bgPrimary = Color(0xFF0F0F1A);
  static const Color bgSecondary = Color(0xFF1A1A2E);
  static const Color bgCard = Color(0xFF16162A);
  static const Color bgElevated = Color(0xFF1E1E35);
  
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF64748B);
  
  static const Color border = Color(0xFF2D2D4A);
  static const Color divider = Color(0xFF2D2D4A);
}

// ============ LIGHT THEME COLORS ============
class AppColorsLight {
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFEC4899);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  static const Color bgPrimary = Color(0xFFF8FAFC);
  static const Color bgSecondary = Color(0xFFFFFFFF);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgElevated = Color(0xFFF1F5F9);
  
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);
}

// ============ DEFAULT COLORS (for backwards compatibility) ============
class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFEC4899);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  static const Color bgPrimary = Color(0xFF0F0F1A);
  static const Color bgSecondary = Color(0xFF1A1A2E);
  static const Color bgCard = Color(0xFF16162A);
  static const Color bgElevated = Color(0xFF1E1E35);
  
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF64748B);
  
  static const Color border = Color(0xFF2D2D4A);
  static const Color divider = Color(0xFF2D2D4A);

  // Gradients (for backwards compatibility)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ============ THEME DATA ============
class AppTheme {
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColorsDark.primary,
      scaffoldBackgroundColor: AppColorsDark.bgPrimary,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.primary,
        secondary: AppColorsDark.secondary,
        surface: AppColorsDark.bgCard,
        error: AppColorsDark.error,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsDark.bgPrimary,
        foregroundColor: AppColorsDark.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      
      cardTheme: CardThemeData(
        color: AppColorsDark.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColorsDark.border),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          side: const BorderSide(color: AppColorsDark.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.error),
        ),
        hintStyle: const TextStyle(color: AppColorsDark.textMuted),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.bgCard,
        selectedItemColor: AppColorsDark.primary,
        unselectedItemColor: AppColorsDark.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.divider,
        thickness: 1,
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColorsDark.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColorsDark.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColorsDark.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColorsDark.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColorsDark.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColorsDark.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColorsDark.textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColorsDark.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColorsDark.textMuted,
        ),
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColorsLight.primary,
      scaffoldBackgroundColor: AppColorsLight.bgPrimary,
      
      colorScheme: const ColorScheme.light(
        primary: AppColorsLight.primary,
        secondary: AppColorsLight.secondary,
        surface: AppColorsLight.bgCard,
        error: AppColorsLight.error,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsLight.bgPrimary,
        foregroundColor: AppColorsLight.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      
      cardTheme: CardThemeData(
        color: AppColorsLight.bgCard,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLight.primary,
          side: const BorderSide(color: AppColorsLight.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLight.primary,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.bgElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.error),
        ),
        hintStyle: const TextStyle(color: AppColorsLight.textMuted),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsLight.bgCard,
        selectedItemColor: AppColorsLight.primary,
        unselectedItemColor: AppColorsLight.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColorsLight.divider,
        thickness: 1,
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColorsLight.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColorsLight.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColorsLight.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColorsLight.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColorsLight.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColorsLight.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColorsLight.textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColorsLight.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColorsLight.textMuted,
        ),
      ),
    );
  }
}

// ============ THEME EXTENSION FOR EASY ACCESS ============
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get errorColor => Theme.of(this).colorScheme.error;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  
  Color get bgPrimary => isDarkMode ? AppColorsDark.bgPrimary : AppColorsLight.bgPrimary;
  Color get bgSecondary => isDarkMode ? AppColorsDark.bgSecondary : AppColorsLight.bgSecondary;
  Color get bgCard => isDarkMode ? AppColorsDark.bgCard : AppColorsLight.bgCard;
  Color get bgElevated => isDarkMode ? AppColorsDark.bgElevated : AppColorsLight.bgElevated;
  
  Color get textPrimary => isDarkMode ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
  Color get textSecondary => isDarkMode ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
  Color get textMuted => isDarkMode ? AppColorsDark.textMuted : AppColorsLight.textMuted;
  
  Color get borderColor => isDarkMode ? AppColorsDark.border : AppColorsLight.border;
  
  Color get success => isDarkMode ? AppColorsDark.success : AppColorsLight.success;
  Color get warning => isDarkMode ? AppColorsDark.warning : AppColorsLight.warning;
  Color get info => isDarkMode ? AppColorsDark.info : AppColorsLight.info;
}