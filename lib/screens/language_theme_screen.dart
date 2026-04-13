import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_text.dart';
import '../providers/settings_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/custom_button.dart';
import '../widgets/language_selector.dart';
import '../widgets/theme_selector.dart';

/// Language & Theme Selection Screen.
/// Allows the user to choose language and appearance before proceeding.
/// Large UI elements optimized for elderly users.
class LanguageThemeScreen extends StatelessWidget {
  const LanguageThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.languageCode;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const SizedBox(height: 16),

              // Professional Icon header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.settings_suggest_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  settings.tr('Welcome!', 'Selamat Datang!'),
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  settings.tr(
                    'Set up your preferences below',
                    'Atur preferensi Anda di bawah ini',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // ─── Language Selection ───
              Text(
                settings.tr(
                  AppText.selectLanguageEn,
                  AppText.selectLanguageId,
                ),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 16),
              LanguageSelector(
                selectedLanguage: lang,
                onChanged: (code) => settings.setLanguage(code),
              ),

              const SizedBox(height: 36),

              // ─── Theme Selection ───
              Text(
                settings.tr(
                  AppText.selectThemeEn,
                  AppText.selectThemeId,
                ),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 16),
              ThemeSelector(
                isDarkMode: settings.isDarkMode,
                onChanged: (isDark) {
                  settings.setThemeMode(
                    isDark ? ThemeMode.dark : ThemeMode.light,
                  );
                },
                lightLabel: settings.tr(
                  AppText.lightModeEn,
                  AppText.lightModeId,
                ),
                darkLabel: settings.tr(
                  AppText.darkModeEn,
                  AppText.darkModeId,
                ),
              ),

              const SizedBox(height: 48),

              // ─── Continue Button ───
              CustomButton(
                text: settings.tr(
                  AppText.continueButtonEn,
                  AppText.continueButtonId,
                ),
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  AppRoutes.navigateReplace(context, AppRoutes.onboarding);
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
    ),
    );
  }
}
