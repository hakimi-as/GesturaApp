import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============ DARK THEME COLORS ============
class AppColorsDark {
  // Teal scale
  static const Color tealLight    = Color(0xFF67E8F9);
  static const Color tealMid      = Color(0xFF2DD4BF);
  static const Color primary      = Color(0xFF14B8A6);
  static const Color primaryLight = Color(0xFF2DD4BF);
  static const Color primaryDark  = Color(0xFF0D9488);
  static const Color cyan         = Color(0xFF06B6D4);

  // Accent (streak / challenges only)
  static const Color secondary    = Color(0xFF06B6D4);
  static const Color accent       = Color(0xFFF59E0B);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF06B6D4);

  // Void backgrounds
  static const Color bgPrimary   = Color(0xFF060D0D);
  static const Color bgSecondary = Color(0xFF0A1515);
  static const Color bgCard      = Color(0xFF0D1A1A);
  static const Color bgElevated  = Color(0xFF112020);

  // Text
  static const Color textPrimary   = Color(0xFFF0FAFA);
  static const Color textSecondary = Color(0xFFB2D8D8);
  static const Color textMuted     = Color(0xFF4D7878);

  // Borders
  static const Color border  = Color(0xFF1A3030);
  static const Color divider = Color(0xFF1A3030);
}

// ============ LIGHT THEME COLORS ============
class AppColorsLight {
  // Teal scale (darker for light bg readability)
  static const Color tealLight    = Color(0xFF0D9488);
  static const Color tealMid      = Color(0xFF14B8A6);
  static const Color primary      = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark  = Color(0xFF0F766E);
  static const Color cyan         = Color(0xFF0891B2);

  // Accent
  static const Color secondary    = Color(0xFF0891B2);
  static const Color accent       = Color(0xFFD97706);

  // Semantic
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error   = Color(0xFFDC2626);
  static const Color info    = Color(0xFF0891B2);

  // Light backgrounds
  static const Color bgPrimary   = Color(0xFFF0FAFA);
  static const Color bgSecondary = Color(0xFFFFFFFF);
  static const Color bgCard      = Color(0xFFFFFFFF);
  static const Color bgElevated  = Color(0xFFE6F7F7);

  // Text
  static const Color textPrimary   = Color(0xFF042F2E);
  static const Color textSecondary = Color(0xFF134E4A);
  static const Color textMuted     = Color(0xFF5EEAD4);

  // Borders
  static const Color border  = Color(0xFFCCF0EE);
  static const Color divider = Color(0xFFCCF0EE);
}

// ============ DEFAULT COLORS (for backwards compatibility) ============
class AppColors {
  // Primary teal
  static const Color primary      = Color(0xFF14B8A6);
  static const Color primaryLight = Color(0xFF2DD4BF);
  static const Color primaryDark  = Color(0xFF0D9488);
  static const Color tealLight    = Color(0xFF67E8F9);
  static const Color tealMid      = Color(0xFF2DD4BF);
  static const Color cyan         = Color(0xFF06B6D4);

  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent    = Color(0xFFF59E0B);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF06B6D4);

  static const Color bgPrimary   = Color(0xFF060D0D);
  static const Color bgSecondary = Color(0xFF0A1515);
  static const Color bgCard      = Color(0xFF0D1A1A);
  static const Color bgElevated  = Color(0xFF112020);

  static const Color textPrimary   = Color(0xFFF0FAFA);
  static const Color textSecondary = Color(0xFFB2D8D8);
  static const Color textMuted     = Color(0xFF4D7878);

  static const Color border  = Color(0xFF1A3030);
  static const Color divider = Color(0xFF1A3030);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF67E8F9), Color(0xFF2DD4BF), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glass decoration helper
  static BoxDecoration glassCard({bool alternate = false}) => BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: alternate
        ? const BorderRadius.only(
            topLeft:     Radius.circular(4),
            topRight:    Radius.circular(16),
            bottomLeft:  Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft:     Radius.circular(20),
            topRight:    Radius.circular(6),
            bottomLeft:  Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
    border: Border.all(color: Colors.white.withOpacity(0.10)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF14B8A6).withOpacity(0.08),
        blurRadius: 24,
      ),
    ],
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
        backgroundColor: Colors.transparent,
        foregroundColor: AppColorsDark.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardThemeData(
        color: AppColorsDark.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(20),
            topRight:    Radius.circular(6),
            bottomLeft:  Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
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
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColorsDark.primary,
        unselectedItemColor: AppColorsDark.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColorsDark.divider,
        thickness: 1,
      ),

      textTheme: GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          headlineLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColorsDark.textPrimary),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColorsDark.textPrimary),
          headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColorsDark.textPrimary),
          titleLarge:     TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColorsDark.textPrimary),
          titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColorsDark.textPrimary),
          titleSmall:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColorsDark.textPrimary),
          bodyLarge:      TextStyle(fontSize: 16, color: AppColorsDark.textSecondary),
          bodyMedium:     TextStyle(fontSize: 14, color: AppColorsDark.textSecondary),
          bodySmall:      TextStyle(fontSize: 12, color: AppColorsDark.textMuted),
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
        backgroundColor: Colors.transparent,
        foregroundColor: AppColorsLight.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardThemeData(
        color: AppColorsLight.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(20),
            topRight:    Radius.circular(6),
            bottomLeft:  Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
          side: const BorderSide(color: AppColorsLight.border),
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
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColorsLight.primary,
        unselectedItemColor: AppColorsLight.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColorsLight.divider,
        thickness: 1,
      ),

      textTheme: GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          headlineLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColorsLight.textPrimary),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColorsLight.textPrimary),
          headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColorsLight.textPrimary),
          titleLarge:     TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColorsLight.textPrimary),
          titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColorsLight.textPrimary),
          titleSmall:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColorsLight.textPrimary),
          bodyLarge:      TextStyle(fontSize: 16, color: AppColorsLight.textSecondary),
          bodyMedium:     TextStyle(fontSize: 14, color: AppColorsLight.textSecondary),
          bodySmall:      TextStyle(fontSize: 12, color: AppColorsLight.textMuted),
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

  Color get bgPrimary   => isDarkMode ? AppColorsDark.bgPrimary   : AppColorsLight.bgPrimary;
  Color get bgSecondary => isDarkMode ? AppColorsDark.bgSecondary : AppColorsLight.bgSecondary;
  Color get bgCard      => isDarkMode ? AppColorsDark.bgCard      : AppColorsLight.bgCard;
  Color get bgElevated  => isDarkMode ? AppColorsDark.bgElevated  : AppColorsLight.bgElevated;

  Color get textPrimary   => isDarkMode ? AppColorsDark.textPrimary   : AppColorsLight.textPrimary;
  Color get textSecondary => isDarkMode ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
  Color get textMuted     => isDarkMode ? AppColorsDark.textMuted     : AppColorsLight.textMuted;

  Color get borderColor => isDarkMode ? AppColorsDark.border : AppColorsLight.border;

  Color get success => isDarkMode ? AppColorsDark.success : AppColorsLight.success;
  Color get warning => isDarkMode ? AppColorsDark.warning : AppColorsLight.warning;
  Color get info    => isDarkMode ? AppColorsDark.info    : AppColorsLight.info;
}
