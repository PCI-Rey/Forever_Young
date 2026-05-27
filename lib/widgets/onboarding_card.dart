import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../utils/responsive_helper.dart';

/// A single onboarding slide card with icon, title, and description.
/// Large text and generous spacing for elderly users.
class OnboardingCard extends StatelessWidget {
  final OnboardingModel data;
  final String languageCode;

  const OnboardingCard({
    super.key,
    required this.data,
    required this.languageCode,
  });

  /// Maps icon name strings to Material Icons.
  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'calendar_today':
        return Icons.calendar_today_rounded;
      case 'touch_app':
        return Icons.touch_app_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.0.rw, vertical: 20.rh),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container with responsive size
            Container(
              width: MediaQuery.of(context).size.height * 0.15,
              height: MediaQuery.of(context).size.height * 0.15,
              constraints: const BoxConstraints(
                minWidth: 100,
                minHeight: 100,
                maxWidth: 160,
                maxHeight: 160,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(data.iconCodePoint),
                size: MediaQuery.of(context).size.height * 0.08,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 40.rh),

            // Title
            Text(
              data.getTitle(languageCode),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20.rh),

            // Description
            Text(
              data.getDescription(languageCode),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 18.sp,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
