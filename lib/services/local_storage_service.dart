import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting user preferences locally.
/// Handles language and theme selection storage.
class LocalStorageService {
  static const String _languageKey = 'selected_language';
  static const String _themeKey = 'selected_theme';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  /// Save the selected language code ('en' or 'id').
  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  /// Get the saved language code. Defaults to 'id' (Bahasa Indonesia).
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'id';
  }

  /// Save the selected theme mode ('light' or 'dark').
  static Future<void> saveTheme(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode);
  }

  /// Get the saved theme mode. Defaults to 'light'.
  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'light';
  }

  /// Mark onboarding as completed.
  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  /// Check if onboarding has been completed.
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Clear all saved preferences (useful for testing/reset).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
