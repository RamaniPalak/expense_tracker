import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';

class AppTheme {
  // ─── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          background: AppColors.background,
          surface: Colors.white,
          onBackground: AppColors.textPrimary,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        dividerTheme: const DividerThemeData(color: AppColors.greyLight),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : Colors.grey.shade400),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.grey.shade200),
        ),
        textTheme: GoogleFonts.interTextTheme(),
      );

  // ─── Dark Theme ────────────────────────────────────────────────────────────
  static const Color _darkBg = Color(0xFF0A0F24);
  static const Color _darkSurface = Color(0xFF121B35);
  static const Color _darkCard = Color(0xFF1A2649);
  static const Color _darkDivider = Color(0xFF253460);
  static const Color _darkText = Color(0xFFF0F2F5);
  static const Color _darkTextSecondary = Color(0xFFA3AED0);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          background: _darkBg,
          surface: _darkSurface,
          onBackground: _darkText,
          onSurface: _darkText,
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: _darkBg,
        appBarTheme: AppBarTheme(
          backgroundColor: _darkSurface,
          elevation: 0,
          iconTheme: const IconThemeData(color: _darkText),
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _darkText,
          ),
        ),
        cardTheme: CardThemeData(
          color: _darkCard,
          surfaceTintColor: _darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(color: _darkDivider),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : _darkTextSecondary),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.primary.withOpacity(0.35)
                  : _darkSurface),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _darkDivider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _darkDivider),
          ),
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: _darkCard,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: _darkCard,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _darkSurface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: _darkTextSecondary,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: _darkSurface,
        ),
      );

  // ─── Dark colour helpers (for manual use in widgets) ───────────────────────
  static const Color darkBackground = _darkBg;
  static const Color darkSurface = _darkSurface;
  static const Color darkCard = _darkCard;
  static const Color darkDivider = _darkDivider;
  static const Color darkText = _darkText;
  static const Color darkTextSecondary = _darkTextSecondary;
}
