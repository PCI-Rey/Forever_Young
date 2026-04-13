import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Provides light and dark ThemeData for the Forever Young app.
/// All fonts and sizes are optimized for elderly users:
/// - Large base font sizes
/// - High contrast ratios
/// - Readable font family (Roboto, system default)
class AppTheme {
  AppTheme._();

  // ─── Shared Constants ───
  static const double _bodyFontSize = 18.0;
  static const double _titleFontSize = 26.0;
  static const double _headlineFontSize = 32.0;
  static const double _buttonFontSize = 20.0;
  static const double _borderRadius = 16.0;
  static const double _buttonHeight = 60.0;

  static double get borderRadius => _borderRadius;
  static double get buttonHeight => _buttonHeight;

  // ─── Light Theme ───
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.buttonTextLight,
        secondary: AppColors.primaryVariant,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: _titleFontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: _headlineFontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: _titleFontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: _bodyFontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimaryLight,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryLight,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: _buttonFontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.buttonTextLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimaryLight,
          foregroundColor: AppColors.buttonTextLight,
          minimumSize: const Size(double.infinity, _buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: _buttonFontSize,
            fontWeight: FontWeight.w600,
          ),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
      ),
    );
  }

  // ─── Dark Theme ───
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        onPrimary: AppColors.buttonTextDark,
        secondary: AppColors.primaryLight,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: _titleFontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: _headlineFontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: _titleFontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: _bodyFontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimaryDark,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryDark,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: _buttonFontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.buttonTextDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimaryDark,
          foregroundColor: AppColors.buttonTextDark,
          minimumSize: const Size(double.infinity, _buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: _buttonFontSize,
            fontWeight: FontWeight.w600,
          ),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
      ),
    );
  }
}
