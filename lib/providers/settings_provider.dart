import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

/// Provider for managing app-wide settings: language and theme.
/// Uses ChangeNotifier for simple, effective state management.
class SettingsProvider extends ChangeNotifier {
  String _languageCode = 'id'; // Default: Bahasa Indonesia
  ThemeMode _themeMode = ThemeMode.light; // Default: Light mode
  bool _hasCompletedSetup = false; // First-launch setup flag
  String _serverIp = ''; // ML API Server IP address

  String get languageCode => _languageCode;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get hasCompletedSetup => _hasCompletedSetup;
  String get serverIp => _serverIp;

  /// Initialize settings from local storage.
  Future<void> loadSettings() async {
    final savedLanguage = await LocalStorageService.getLanguage();
    final savedTheme = await LocalStorageService.getTheme();
    final setupDone = await LocalStorageService.isSetupComplete();
    final savedIp = await LocalStorageService.getServerIp();

    _languageCode = savedLanguage;
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _hasCompletedSetup = setupDone;
    _serverIp = savedIp;
    notifyListeners();
  }

  /// Mark full first-launch setup as completed and persist it.
  Future<void> markSetupComplete() async {
    _hasCompletedSetup = true;
    await LocalStorageService.setSetupComplete();
    notifyListeners();
  }

  /// Update the selected language and persist it.
  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    await LocalStorageService.saveLanguage(code);
    notifyListeners();
  }

  /// Update the selected theme and persist it.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final themeString = mode == ThemeMode.dark ? 'dark' : 'light';
    await LocalStorageService.saveTheme(themeString);
    notifyListeners();
  }

  /// Toggle between light and dark mode.
  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Update the ML API Server IP and persist it.
  Future<void> setServerIp(String ip) async {
    _serverIp = ip;
    await LocalStorageService.saveServerIp(ip);
    notifyListeners();
  }

  /// Helper: get localized text.
  String tr(String en, String id) {
    return _languageCode == 'id' ? id : en;
  }
}
