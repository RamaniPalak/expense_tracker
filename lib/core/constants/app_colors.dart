import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF429690);
  static const Color secondary = Color(0xFF2A7C76);
  static const Color primaryDark = Color(0xFF1B5E5A);

  static const Color background = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF707070);

  static const Color incomeGreen = Color(0xFF25A969);
  static const Color expenseRed = Color(0xFFF95B51);

  static const Color greyLight = Color(0xFFEEEEEE);
  static const Color tabBackground = Color(0xFFF4F6F6);
  static const Color white = Colors.white;

  // Premium Gradients
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [secondary, primary],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [incomeGreen, Color(0xFF32D74B)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [expenseRed, Color(0xFFFF453A)],
  );

  // Category Colors
  static const Color catNetflix = Color(0xFFFF4B4B);
  static const Color catUpwork = Color(0xFF14A800);
  static const Color catFood = Color(0xFFFF9F0A);
  static const Color catTransport = Color(0xFF5E5CE6);
  static const Color catSalary = Colors.blue;

  // Status/Utility
  static const Color error = Color(0xFFF95B51);
  static const Color success = Color(0xFF30D158);
  static const Color white70 = Colors.white70;
  static const Color white54 = Colors.white54;

  // Legacy/Utility Aliases (Fixing compilation errors)
  static const Color cardGradientStart = secondary;
  static const Color cardGradientEnd = primary;
  static const Color selectedAccountBackground = Color(0xFFF1F8F8);
  static const Color payButtonBackground = Color(0xFFE0F7F6);
  static const Color iconBackground = Color(0xFFF5F5F5);
  static const Color primaryLight = primary;
  static const String incomeGreenHex = '#219653';
  static const String expenseRedHex = '#FF6B6B';
}
