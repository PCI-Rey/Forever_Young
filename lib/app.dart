import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'utils/responsive_helper.dart';

/// Root application widget.
/// Configures theming, routing, and state management.
class ForeverYoungApp extends StatelessWidget {
  const ForeverYoungApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Forever Young',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,

      // Routes
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,

      // Initialize responsive helper with real device dimensions
      builder: (context, child) {
        AppResponsive.init(context);
        return child!;
      },
    );
  }
}
