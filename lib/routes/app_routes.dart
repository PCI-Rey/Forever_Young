import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/language_theme_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/scan_screen.dart';

/// Centralized route management for the Forever Young app.
class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String languageTheme = '/language-theme';
  static const String onboarding = '/onboarding';
  static const String scan = '/scan';

  /// Route map for MaterialApp.
  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        languageTheme: (_) => const LanguageThemeScreen(),
        onboarding: (_) => const OnboardingScreen(),
        scan: (_) => const ScanScreen(),
      };

  /// Navigate with a forward slide transition (no back gesture).
  static void navigateReplace(BuildContext context, String routeName) {
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  /// Navigate and remove all previous routes from the stack.
  static void navigateAndClearStack(BuildContext context, String routeName) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  /// Custom cross-fade transition for premium splash screen handoff.
  static void fadeReplace(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  /// Standard push navigation to allow going back.
  static void navigate(BuildContext context, String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }
}
