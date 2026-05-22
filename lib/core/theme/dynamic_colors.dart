import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';

/// A set of semantic colors that automatically switches between
/// light and dark values based on the current [ThemeData.brightness].
///
/// Usage:  `final c = context.appColors;`
///         `Container(color: c.surface)`
class DynamicColors {
  final bool isDark;

  const DynamicColors(this.isDark);

  // ── Backgrounds ──────────────────────────────────────────────────────────

  /// Main scaffold / page background
  Color get background =>
      isDark ? const Color(0xFF0A0F24) : AppColors.background;

  /// Card / container surface
  Color get surface => isDark ? const Color(0xFF121B35) : Colors.white;

  /// Elevated card (slightly lighter than surface in dark)
  Color get card => isDark ? const Color(0xFF1A2649) : Colors.white;

  /// Tab switcher / chip background
  Color get tabBg => isDark ? const Color(0xFF121B35) : AppColors.tabBackground;

  // ── Text ─────────────────────────────────────────────────────────────────

  /// Primary readable text
  Color get textPrimary =>
      isDark ? const Color(0xFFF0F2F5) : AppColors.textPrimary;

  /// Secondary / hint text
  Color get textSecondary =>
      isDark ? const Color(0xFFA3AED0) : AppColors.textSecondary;

  // ── Borders / Dividers ───────────────────────────────────────────────────

  Color get divider =>
      isDark ? const Color(0xFF253460) : AppColors.greyLight;

  Color get border =>
      isDark ? const Color(0xFF253460) : AppColors.greyLight;

  // ── Shadows ──────────────────────────────────────────────────────────────

  Color get shadow =>
      isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.06);

  // ── Input / Fields ───────────────────────────────────────────────────────

  Color get inputFill => isDark ? const Color(0xFF121B35) : Colors.white;

  // ── Fixed accent colours (same in both modes) ────────────────────────────
  Color get primary => AppColors.primary;
  Color get secondary => AppColors.secondary;
  Color get incomeGreen => AppColors.incomeGreen;
  Color get expenseRed => AppColors.expenseRed;
}

/// Convenience extension so any widget can write `context.appColors`.
extension AppColorsExtension on BuildContext {
  DynamicColors get appColors {
    final brightness = Theme.of(this).brightness;
    return DynamicColors(brightness == Brightness.dark);
  }
}
