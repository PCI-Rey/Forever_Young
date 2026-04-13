import 'package:flutter/material.dart';

/// Centralized color constants for the Forever Young app.
/// Uses a premium medical palette: Calming Teal paired with Warm Coral and Soft Peach.
class AppColors {
  AppColors._();

  // ─── Playful & Warm Accents ───
  static const Color warmCoral = Color(0xFFFF7A59);
  static const Color softPeach = Color(0xFFFFF9F0);

  // ─── Primary Palette (Calming Teal/Medical Green) ───
  static const Color primaryLight = Color(0xFF2E9E83);
  static const Color primaryDark = Color(0xFF5ECFB0);
  static const Color primaryVariant = Color(0xFF1B7A63);

  // ─── Background & Surface ───
  // backgroundLight synced with Splash Screen's softPeach
  static const Color backgroundLight = softPeach; 
  static const Color backgroundDark = Color(0xFF1A1D23);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF252830);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2C2F38);

  // ─── Text Colors ───
  static const Color textPrimaryLight = Color(0xFF2C332D); // Warmer dark text
  static const Color textPrimaryDark = Color(0xFFF0F2F5);
  static const Color textSecondaryLight = Color(0xFF6A706B);
  static const Color textSecondaryDark = Color(0xFFB0B8C8);

  // ─── Accent & Action Colors ───
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // ─── Button Colors ───
  // Making primary buttons use the friendly warmCoral
  static const Color buttonPrimaryLight = warmCoral;
  static const Color buttonPrimaryDark = warmCoral;
  static const Color buttonTextLight = Color(0xFFFFFFFF);
  static const Color buttonTextDark = Color(0xFFFFFFFF);

  // ─── Divider & Border ───
  static const Color dividerLight = Color(0xFFE0E4EA);
  static const Color dividerDark = Color(0xFF3A3D46);

  // ─── Splash Screen Gradient (Legacy / Specific uses) ───
  static const Color splashGradientStart = Color(0xFF2E9E83);
  static const Color splashGradientEnd = Color(0xFF1B7A63);
  static const Color ivoryBackground = Color(0xFFF9FBF9); 
  static const Color zenLogoGlow = Color(0x332E9E83);

  // ─── Scan Screen ───
  static const Color scanOverlay = Color(0x99000000);
  static const Color scanFrame = primaryLight; // Teal scan frame
  static const Color scanButtonRing = warmCoral; // Warm ring

  // ─── Selection Highlight ───
  static const Color selectedLight = Color(0xFFFFEAD9); // Soft coral tint
  static const Color selectedDark = Color(0xFF3E2723); // Warm dark tint
  static const Color unselectedLight = Color(0xFFF0F2F5);
  static const Color unselectedDark = Color(0xFF2C2F38);
}
