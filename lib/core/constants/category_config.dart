import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';

/// Centralized category configuration for colors, pastel tints, icons, and emojis.
/// Consolidates all category styling across transactions, calendar, statistics, and expense entry.
class CategoryConfig {
  CategoryConfig._();

  /// Returns the emoji representing the given [category].
  static String getEmoji(String category) {
    switch (category) {
      case AppStrings.catAutomobile:
      case "Automobile":
        return "🚗";
      case AppStrings.catBills:
      case "Bills":
        return "🔌";
      case AppStrings.catCharges:
      case "Charges":
        return "🏛️";
      case AppStrings.catEducation:
        return "📚";
      case AppStrings.catEntertainment:
        return "🎭";
      case AppStrings.catFoodDining:
      case AppStrings.catFood:
        return "🍔";
      case AppStrings.catGifts:
      case "Gifts":
        return "🎁";
      case AppStrings.catHealth:
      case "Health":
      case "Health and Fitness":
        return "💪";
      case AppStrings.catBonus:
        return "🌈";
      case AppStrings.catCommission:
        return "🎉";
      case AppStrings.catInterest:
        return "🌱";
      case AppStrings.catInvestments:
        return "🚀";
      case AppStrings.catReceivedOthers:
      case "Received Others":
        return "📦";
      case AppStrings.catRentalIncome:
        return "🛏️";
      case AppStrings.catSalary:
        return "💼";
      case AppStrings.catSellingAssets:
        return "💰";
      case AppStrings.catOther:
        return "🧩";
      case AppStrings.catNetflix:
        return "🎬";
      case AppStrings.catTransport:
        return "🚗";
      case AppStrings.catShopping:
        return "🛍️";
      case AppStrings.catUpwork:
      case AppStrings.catFreelance:
        return "💻";
      default:
        return "🏷️";
    }
  }

  /// Returns the primary badge/tile color for the given [category].
  static Color getColor(String category, {bool isIncome = false}) {
    switch (category) {
      case AppStrings.catAutomobile:
      case "Automobile":
        return const Color(0xFFEF4444);
      case AppStrings.catBills:
      case "Bills":
        return const Color(0xFF06B6D4);
      case AppStrings.catCharges:
      case "Charges":
        return const Color(0xFF84CC16);
      case AppStrings.catEducation:
        return const Color(0xFFEC4899);
      case AppStrings.catEntertainment:
        return const Color(0xFF10B981);
      case AppStrings.catFoodDining:
      case AppStrings.catFood:
        return const Color(0xFFF59E0B);
      case AppStrings.catGifts:
      case "Gifts":
        return const Color(0xFF0EA5E9);
      case AppStrings.catHealth:
      case "Health":
      case "Health and Fitness":
        return const Color(0xFF8B5CF6);
      case AppStrings.catBonus:
        return const Color(0xFFF43F5E);
      case AppStrings.catCommission:
        return const Color(0xFF06B6D4);
      case AppStrings.catInterest:
        return const Color(0xFF22C55E);
      case AppStrings.catInvestments:
        return const Color(0xFFEAB308);
      case AppStrings.catReceivedOthers:
      case "Received Others":
        return const Color(0xFF6366F1);
      case AppStrings.catRentalIncome:
        return const Color(0xFFF97316);
      case AppStrings.catSalary:
        return const Color(0xFF22C55E);
      case AppStrings.catSellingAssets:
        return const Color(0xFF0EA5E9);
      case AppStrings.catOther:
        return const Color(0xFF64748B);
      case AppStrings.catNetflix:
        return const Color(0xFFFF4B4B);
      case AppStrings.catTransport:
        return const Color(0xFF5E5CE6);
      case AppStrings.catShopping:
        return const Color(0xFFFF69B4);
      case AppStrings.catUpwork:
        return const Color(0xFF14A800);
      case AppStrings.catFreelance:
        return Colors.teal;
      default:
        return isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    }
  }

  /// Returns the subtle pastel background color for category chips/cards.
  static Color getPastelColor(String category, {bool isIncome = false}) {
    switch (category) {
      case AppStrings.catAutomobile:
      case "Automobile":
        return const Color(0xFFFFEAEA);
      case AppStrings.catBills:
      case "Bills":
        return const Color(0xFFE2FAFC);
      case AppStrings.catCharges:
      case "Charges":
        return const Color(0xFFF2FCD0);
      case AppStrings.catEducation:
        return const Color(0xFFFFE8EC);
      case AppStrings.catEntertainment:
        return const Color(0xFFE2FBE9);
      case AppStrings.catFoodDining:
      case AppStrings.catFood:
        return const Color(0xFFFFF1D6);
      case AppStrings.catGifts:
      case "Gifts":
        return const Color(0xFFE0F2FE);
      case AppStrings.catHealth:
      case "Health":
      case "Health and Fitness":
        return const Color(0xFFF3E8FF);
      case AppStrings.catBonus:
        return const Color(0xFFFFEAEF);
      case AppStrings.catCommission:
        return const Color(0xFFE0F9FF);
      case AppStrings.catInterest:
        return const Color(0xFFE2FBE9);
      case AppStrings.catInvestments:
        return const Color(0xFFFFF7E0);
      case AppStrings.catReceivedOthers:
      case "Received Others":
        return const Color(0xFFE0E7FF);
      case AppStrings.catRentalIncome:
        return const Color(0xFFFFEDD5);
      case AppStrings.catSalary:
        return const Color(0xFFDCFCE7);
      case AppStrings.catSellingAssets:
        return const Color(0xFFE0F2FE);
      case AppStrings.catOther:
        return const Color(0xFFF1F5F9);
      case AppStrings.catNetflix:
        return const Color(0xFFFFEAEA);
      case AppStrings.catTransport:
        return const Color(0xFFE8E8FF);
      case AppStrings.catShopping:
        return const Color(0xFFFFEAEF);
      case AppStrings.catUpwork:
        return const Color(0xFFE2FBE9);
      case AppStrings.catFreelance:
        return const Color(0xFFE0F2FE);
      default:
        return isIncome ? const Color(0xFFDCFCE7) : const Color(0xFFFFEAEA);
    }
  }

  /// Returns the category icon for the given [category].
  static IconData getIcon(String category, {bool isIncome = false}) {
    switch (category) {
      case AppStrings.catAutomobile:
      case "Automobile":
        return Icons.directions_car_filled_rounded;
      case AppStrings.catBills:
      case "Bills":
        return Icons.electrical_services_rounded;
      case AppStrings.catCharges:
      case "Charges":
        return Icons.account_balance_rounded;
      case AppStrings.catEducation:
        return Icons.school_rounded;
      case AppStrings.catEntertainment:
        return Icons.theater_comedy_rounded;
      case AppStrings.catFoodDining:
      case AppStrings.catFood:
        return Icons.fastfood_rounded;
      case AppStrings.catGifts:
      case "Gifts":
        return Icons.card_giftcard_rounded;
      case AppStrings.catHealth:
      case "Health":
      case "Health and Fitness":
        return Icons.fitness_center_rounded;
      case AppStrings.catBonus:
        return Icons.celebration_rounded;
      case AppStrings.catCommission:
        return Icons.percent_rounded;
      case AppStrings.catInterest:
        return Icons.trending_up_rounded;
      case AppStrings.catInvestments:
        return Icons.rocket_launch_rounded;
      case AppStrings.catReceivedOthers:
      case "Received Others":
        return Icons.inventory_2_rounded;
      case AppStrings.catRentalIncome:
        return Icons.home_rounded;
      case AppStrings.catSalary:
        return Icons.work_rounded;
      case AppStrings.catSellingAssets:
        return Icons.monetization_on_rounded;
      case AppStrings.catNetflix:
        return Icons.movie_outlined;
      case AppStrings.catTransport:
        return Icons.directions_car_outlined;
      case AppStrings.catShopping:
        return Icons.shopping_bag_outlined;
      case AppStrings.catUpwork:
        return Icons.work_outline;
      case AppStrings.catFreelance:
        return Icons.computer_outlined;
      case AppStrings.catOther:
        return Icons.more_horiz;
      default:
        return isIncome
            ? Icons.add_circle_outline
            : Icons.shopping_cart_outlined;
    }
  }
}
