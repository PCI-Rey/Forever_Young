import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text.dart';
import '../theme/app_theme.dart';

/// A large, accessible language selector widget (Indonesian / English).
/// Designed for elderly users with clear flags and visual feedback.
class LanguageSelector extends StatelessWidget {
  final String selectedLanguage; // 'id' or 'en'
  final ValueChanged<String> onChanged;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Row(
      children: [
        Expanded(
          child: _buildOption(
            context,
            languageCode: 'id',
            flag: '🇮🇩',
            label: AppText.indonesianLabel,
            isSelected: selectedLanguage == 'id',
            isLight: isLight,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildOption(
            context,
            languageCode: 'en',
            flag: '🇬🇧',
            label: AppText.englishLabel,
            isSelected: selectedLanguage == 'en',
            isLight: isLight,
          ),
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String languageCode,
    required String flag,
    required String label,
    required bool isSelected,
    required bool isLight,
  }) {
    final selectedBg =
        isLight ? AppColors.selectedLight : AppColors.selectedDark;
    final unselectedBg =
        isLight ? AppColors.unselectedLight : AppColors.unselectedDark;
    final borderColor =
        isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent;

    return GestureDetector(
      onTap: () => onChanged(languageCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Icon(
                Icons.check_circle_rounded,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
