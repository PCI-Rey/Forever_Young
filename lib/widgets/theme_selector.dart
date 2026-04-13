import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

/// A large, accessible theme selector widget (Light / Dark).
/// Designed for elderly users with clear visual feedback.
class ThemeSelector extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;
  final String lightLabel;
  final String darkLabel;

  const ThemeSelector({
    super.key,
    required this.isDarkMode,
    required this.onChanged,
    required this.lightLabel,
    required this.darkLabel,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    return Row(
      children: [
        Expanded(
          child: _buildOption(
            context,
            icon: Icons.light_mode_rounded,
            label: lightLabel,
            isSelected: !isDarkMode,
            onTap: () => onChanged(false),
            isLight: isLight,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildOption(
            context,
            icon: Icons.dark_mode_rounded,
            label: darkLabel,
            isSelected: isDarkMode,
            onTap: () => onChanged(true),
            isLight: isLight,
          ),
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLight,
  }) {
    final selectedBg =
        isLight ? AppColors.selectedLight : AppColors.selectedDark;
    final unselectedBg =
        isLight ? AppColors.unselectedLight : AppColors.unselectedDark;
    final borderColor =
        isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
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
            Icon(
              icon,
              size: 40,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(height: 10),
            Text(
              label,
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
