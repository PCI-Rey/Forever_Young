import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting user preferences locally.
/// Handles language and theme selection storage.
class LocalStorageService {
  static const String _languageKey = 'selected_language';
  static const String _themeKey = 'selected_theme';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _setupCompleteKey = 'setup_complete';
  static const String _serverIpKey = 'server_ip';

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

  /// Mark the full first-launch setup (language + theme + onboarding) as done.
  static Future<void> setSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompleteKey, true);
  }

  /// Check if the first-launch setup has been completed.
  static Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupCompleteKey) ?? false;
  }

  /// Save the ML API Server IP address.
  static Future<void> saveServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverIpKey, ip);
  }

  /// Get the saved ML API Server IP. Defaults to empty string.
  static Future<String> getServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverIpKey) ?? '';
  }

  /// Clear all saved preferences (useful for testing/reset).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
