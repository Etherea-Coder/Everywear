import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app locale preferences and persistence
class LocaleManager {
  static const String _localeKey = 'app_locale';
  static const String _themeModeKey = 'theme_mode';

  /// Saves the selected locale to persistent storage
  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  /// Retrieves the saved locale from persistent storage
  static Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);

    if (languageCode != null) {
      return Locale(languageCode);
    }
    return null;
  }

  /// Save theme mode to SharedPreferences
  static Future<void> saveThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode.toLowerCase());
  }

  /// Get saved theme mode from SharedPreferences
  static Future<String> getSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'light';
  }

  /// Gets the display name for a language code
  static String getLanguageDisplayName(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      default:
        return 'English';
    }
  }

  /// Gets flag emoji for a language code
  static String getLanguageFlag(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return '🇬🇧';
      case 'fr':
        return '🇫🇷';
      case 'es':
        return '🇪🇸';
      default:
        return '🇬🇧';
    }
  }
}
