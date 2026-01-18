import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  system,
}

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  AppThemeMode _themeMode = AppThemeMode.dark;
  bool _isInitialized = false;

  AppThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  
  bool get isDarkMode {
    if (_themeMode == AppThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == AppThemeMode.dark;
  }

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    
    if (savedTheme != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == savedTheme,
        orElse: () => AppThemeMode.dark,
      );
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> toggleTheme() async {
    if (_themeMode == AppThemeMode.dark) {
      await setThemeMode(AppThemeMode.light);
    } else {
      await setThemeMode(AppThemeMode.dark);
    }
  }
}