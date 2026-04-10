import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  /// Human-readable name for the current locale.
  String get displayName {
    switch (_locale.languageCode) {
      case 'ms':
        return 'Bahasa Malaysia';
      default:
        return 'English';
    }
  }

  static const _prefKey = 'app_locale';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey) ?? 'en';
    _locale = _localeFromCode(code);
    // no notifyListeners — called before runApp
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .contains(locale.languageCode)) return;

    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> setLocaleByCode(String code) => setLocale(_localeFromCode(code));

  static Locale _localeFromCode(String code) {
    switch (code) {
      case 'ms':
        return const Locale('ms');
      default:
        return const Locale('en');
    }
  }

  /// All supported languages as {code, name} for display in settings.
  static const supportedLanguages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'ms', 'name': 'Bahasa Malaysia', 'native': 'Bahasa Malaysia'},
  ];
}
