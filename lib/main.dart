import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/settings_provider.dart';

/// Application entry point.
/// Initializes providers and loads saved settings before rendering.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for elderly users (simpler experience)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize settings provider and load saved preferences
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: const ForeverYoungApp(),
    ),
  );
}
