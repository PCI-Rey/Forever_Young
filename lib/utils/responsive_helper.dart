import 'dart:math';
import 'package:flutter/material.dart';

/// Responsive helper for Forever Young app.
///
/// Gold Standard device: Infinix Hot 50 Pro
///   → Logical resolution: 412 × 917 dp (portrait)
///
/// This utility computes proportional scale factors so that all hardcoded
/// sizes (fonts, padding, icons, SizedBox heights) look identical on the
/// gold standard and scale naturally on any other Android device.
///
/// Usage:
///   AppResponsive.init(context);  ← call once at app start (in app.dart builder)
///
/// Extension shortcuts on num:
///   16.sp   → scaled font / icon size
///   20.w    → scaled width / horizontal dimension
///   24.h    → scaled height / vertical dimension
///   12.r    → scaled radius / symmetric dimension (uses min of w and h scale)
class AppResponsive {
  AppResponsive._();

  // ── Gold Standard: Infinix Hot 50 Pro (portrait) ──
  static const double _baseWidth = 412.0;
  static const double _baseHeight = 917.0;

  // Actual device metrics (set once in init)
  static double _deviceWidth = _baseWidth;
  static double _deviceHeight = _baseHeight;

  // Clamp ratios so the UI doesn't blow up on tablets
  static const double _maxScaleFactor = 1.35;
  static const double _minScaleFactor = 0.75;

  /// Initialize with the current [BuildContext].
  /// Call this inside [MaterialApp.builder] so it runs before any widget builds.
  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _deviceWidth = size.width;
    _deviceHeight = size.height;
  }

  /// Width scale factor (horizontal dimension).
  static double get scaleW =>
      (_deviceWidth / _baseWidth).clamp(_minScaleFactor, _maxScaleFactor);

  /// Height scale factor (vertical dimension).
  static double get scaleH =>
      (_deviceHeight / _baseHeight).clamp(_minScaleFactor, _maxScaleFactor);

  /// Font / icon scale factor — uses the smaller of the two axes so text
  /// never overflows on narrow or short screens.
  static double get scaleFont => min(scaleW, scaleH);

  /// Scale a width/horizontal value.
  static double w(num value) => value * scaleW;

  /// Scale a height/vertical value.
  static double h(num value) => value * scaleH;

  /// Scale a font or icon size.
  static double sp(num value) => value * scaleFont;

  /// Scale a symmetric / radius value (uses minimum axis).
  static double r(num value) => value * scaleFont;
}

/// Extension on [num] for ergonomic responsive sizing.
extension ResponsiveNum on num {
  /// Scaled font / icon size (uses the minimum of width/height scale).
  double get sp => AppResponsive.sp(this);

  /// Scaled width or horizontal dimension.
  double get rw => AppResponsive.w(this);

  /// Scaled height or vertical dimension.
  double get rh => AppResponsive.h(this);

  /// Scaled radius or symmetric dimension.
  double get r => AppResponsive.r(this);
}
