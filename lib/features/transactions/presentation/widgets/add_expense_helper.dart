import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class AddExpenseHelper {
  static final List<Map<String, dynamic>> expenseCategories = [
    {
      "name": AppStrings.catAutomobile,
      "emoji": "🚗",
      "color": const Color(0xFFFFEAEA),
      "iconColor": const Color(0xFFEF4444),
      "icon": Icons.directions_car_filled_rounded,
    },
    {
      "name": AppStrings.catBills,
      "emoji": "🔌",
      "color": const Color(0xFFE2FAFC),
      "iconColor": const Color(0xFF06B6D4),
      "icon": Icons.electrical_services_rounded,
    },
    {
      "name": AppStrings.catCharges,
      "emoji": "🏛️",
      "color": const Color(0xFFF2FCD0),
      "iconColor": const Color(0xFF84CC16),
      "icon": Icons.account_balance_rounded,
    },
    {
      "name": AppStrings.catEducation,
      "emoji": "📚",
      "color": const Color(0xFFFFE8EC),
      "iconColor": const Color(0xFFEC4899),
      "icon": Icons.school_rounded,
    },
    {
      "name": AppStrings.catEntertainment,
      "emoji": "🎭",
      "color": const Color(0xFFE2FBE9),
      "iconColor": const Color(0xFF10B981),
      "icon": Icons.theater_comedy_rounded,
    },
    {
      "name": AppStrings.catFoodDining,
      "emoji": "🍔",
      "color": const Color(0xFFFFF1D6),
      "iconColor": const Color(0xFFF59E0B),
      "icon": Icons.fastfood_rounded,
    },
    {
      "name": AppStrings.catGifts,
      "emoji": "🎁",
      "color": const Color(0xFFE0F2FE),
      "iconColor": const Color(0xFF0EA5E9),
      "icon": Icons.card_giftcard_rounded,
    },
    {
      "name": AppStrings.catHealth,
      "emoji": "💪",
      "color": const Color(0xFFF3E8FF),
      "iconColor": const Color(0xFF8B5CF6),
      "icon": Icons.fitness_center_rounded,
    },
    {
      "name": AppStrings.catOther,
      "emoji": "🧩",
      "color": const Color(0xFFF1F5F9),
      "iconColor": const Color(0xFF64748B),
      "icon": Icons.category_rounded,
    },
  ];

  static final List<Map<String, dynamic>> incomeCategories = [
    {
      "name": AppStrings.catBonus,
      "emoji": "🌈",
      "color": const Color(0xFFFFEAEF),
      "iconColor": const Color(0xFFF43F5E),
      "icon": Icons.celebration_rounded,
    },
    {
      "name": AppStrings.catCommission,
      "emoji": "🎉",
      "color": const Color(0xFFE0F9FF),
      "iconColor": const Color(0xFF06B6D4),
      "icon": Icons.percent_rounded,
    },
    {
      "name": AppStrings.catInterestNew,
      "emoji": "🌱",
      "color": const Color(0xFFE2FBE9),
      "iconColor": const Color(0xFF22C55E),
      "icon": Icons.trending_up_rounded,
    },
    {
      "name": AppStrings.catInvestments,
      "emoji": "🚀",
      "color": const Color(0xFFFFF7E0),
      "iconColor": const Color(0xFFEAB308),
      "icon": Icons.rocket_launch_rounded,
    },
    {
      "name": AppStrings.catReceivedOthers,
      "emoji": "📦",
      "color": const Color(0xFFE0E7FF),
      "iconColor": const Color(0xFF6366F1),
      "icon": Icons.inventory_2_rounded,
    },
    {
      "name": AppStrings.catRentalIncome,
      "emoji": "🛏️",
      "color": const Color(0xFFFFEDD5),
      "iconColor": const Color(0xFFF97316),
      "icon": Icons.home_rounded,
    },
    {
      "name": AppStrings.catSalaryNew,
      "emoji": "💼",
      "color": const Color(0xFFDCFCE7),
      "iconColor": const Color(0xFF22C55E),
      "icon": Icons.work_rounded,
    },
    {
      "name": AppStrings.catSellingAssets,
      "emoji": "💰",
      "color": const Color(0xFFE0F2FE),
      "iconColor": const Color(0xFF0EA5E9),
      "icon": Icons.monetization_on_rounded,
    },
    {
      "name": AppStrings.catOther,
      "emoji": "🧩",
      "color": const Color(0xFFF1F5F9),
      "iconColor": const Color(0xFF64748B),
      "icon": Icons.category_rounded,
    },
  ];

  static String getCategoryEmoji(String category) {
    switch (category) {
      case AppStrings.catAutomobile:
        return "🚗";
      case AppStrings.catBills:
        return "🔌";
      case AppStrings.catCharges:
        return "🏛️";
      case AppStrings.catEducation:
        return "📚";
      case AppStrings.catEntertainment:
        return "🎭";
      case AppStrings.catFoodDining:
        return "🍔";
      case AppStrings.catGifts:
        return "🎁";
      case AppStrings.catHealth:
        return "💪";
      case AppStrings.catBonus:
        return "🌈";
      case AppStrings.catCommission:
        return "🎉";
      case AppStrings.catInterestNew:
        return "🌱";
      case AppStrings.catInvestments:
        return "🚀";
      case AppStrings.catReceivedOthers:
        return "📦";
      case AppStrings.catRentalIncome:
        return "🛏️";
      case AppStrings.catSalaryNew:
        return "💼";
      case AppStrings.catSellingAssets:
        return "💰";
      case AppStrings.catOther:
        return "🧩";
      case "Netflix":
        return "🎬";
      case "Food":
        return "🍔";
      case "Transport":
        return "🚗";
      case "Shopping":
        return "🛍️";
      case "Upwork":
        return "💻";
      case "Freelance":
        return "💻";
      default:
        return "🏷️";
    }
  }

  static Color getCategoryColor(String category, {bool isIncome = false}) {
    switch (category) {
      case AppStrings.catAutomobile:
        return const Color(0xFFEF4444);
      case AppStrings.catBills:
        return const Color(0xFF06B6D4);
      case AppStrings.catCharges:
        return const Color(0xFF84CC16);
      case AppStrings.catEducation:
        return const Color(0xFFEC4899);
      case AppStrings.catEntertainment:
        return const Color(0xFF10B981);
      case AppStrings.catFoodDining:
        return const Color(0xFFF59E0B);
      case AppStrings.catGifts:
        return const Color(0xFF0EA5E9);
      case AppStrings.catHealth:
        return const Color(0xFF8B5CF6);
      case AppStrings.catBonus:
        return const Color(0xFFF43F5E);
      case AppStrings.catCommission:
        return const Color(0xFF06B6D4);
      case AppStrings.catInterestNew:
        return const Color(0xFF22C55E);
      case AppStrings.catInvestments:
        return const Color(0xFFEAB308);
      case AppStrings.catReceivedOthers:
        return const Color(0xFF6366F1);
      case AppStrings.catRentalIncome:
        return const Color(0xFFF97316);
      case AppStrings.catSalaryNew:
        return const Color(0xFF22C55E);
      case AppStrings.catSellingAssets:
        return const Color(0xFF0EA5E9);
      case AppStrings.catOther:
        return const Color(0xFF64748B);
      case "Netflix":
        return const Color(0xFFFF4B4B);
      case "Food":
        return const Color(0xFFFF9F0A);
      case "Transport":
        return const Color(0xFF5E5CE6);
      case "Shopping":
        return const Color(0xFFFF69B4);
      case "Upwork":
        return const Color(0xFF14A800);
      case "Freelance":
        return Colors.teal;
      default:
        return isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    }
  }

  static Color getCategoryPastelColor(String category, {bool isIncome = false}) {
    switch (category) {
      case AppStrings.catAutomobile:
        return const Color(0xFFFFEAEA);
      case AppStrings.catBills:
        return const Color(0xFFE2FAFC);
      case AppStrings.catCharges:
        return const Color(0xFFF2FCD0);
      case AppStrings.catEducation:
        return const Color(0xFFFFE8EC);
      case AppStrings.catEntertainment:
        return const Color(0xFFE2FBE9);
      case AppStrings.catFoodDining:
        return const Color(0xFFFFF1D6);
      case AppStrings.catGifts:
        return const Color(0xFFE0F2FE);
      case AppStrings.catHealth:
        return const Color(0xFFF3E8FF);
      case AppStrings.catBonus:
        return const Color(0xFFFFEAEF);
      case AppStrings.catCommission:
        return const Color(0xFFE0F9FF);
      case AppStrings.catInterestNew:
        return const Color(0xFFE2FBE9);
      case AppStrings.catInvestments:
        return const Color(0xFFFFF7E0);
      case AppStrings.catReceivedOthers:
        return const Color(0xFFE0E7FF);
      case AppStrings.catRentalIncome:
        return const Color(0xFFFFEDD5);
      case AppStrings.catSalaryNew:
        return const Color(0xFFDCFCE7);
      case AppStrings.catSellingAssets:
        return const Color(0xFFE0F2FE);
      case AppStrings.catOther:
        return const Color(0xFFF1F5F9);
      case "Netflix":
        return const Color(0xFFFFEAEA);
      case "Food":
        return const Color(0xFFFFF1D6);
      case "Transport":
        return const Color(0xFFE8E8FF);
      case "Shopping":
        return const Color(0xFFFFEAEF);
      case "Upwork":
        return const Color(0xFFE2FBE9);
      case "Freelance":
        return const Color(0xFFE0F2FE);
      default:
        return isIncome ? const Color(0xFFDCFCE7) : const Color(0xFFFFEAEA);
    }
  }

  static IconData getCategoryIcon(String category, {bool isIncome = false}) {
    switch (category) {
      case AppStrings.catAutomobile:
        return Icons.directions_car_filled_rounded;
      case AppStrings.catBills:
        return Icons.electrical_services_rounded;
      case AppStrings.catCharges:
        return Icons.account_balance_rounded;
      case AppStrings.catEducation:
        return Icons.school_rounded;
      case AppStrings.catEntertainment:
        return Icons.theater_comedy_rounded;
      case AppStrings.catFoodDining:
        return Icons.fastfood_rounded;
      case AppStrings.catGifts:
        return Icons.card_giftcard_rounded;
      case AppStrings.catHealth:
        return Icons.fitness_center_rounded;
      case AppStrings.catBonus:
        return Icons.celebration_rounded;
      case AppStrings.catCommission:
        return Icons.percent_rounded;
      case AppStrings.catInterestNew:
        return Icons.trending_up_rounded;
      case AppStrings.catInvestments:
        return Icons.rocket_launch_rounded;
      case AppStrings.catReceivedOthers:
        return Icons.inventory_2_rounded;
      case AppStrings.catRentalIncome:
        return Icons.home_rounded;
      case AppStrings.catSalaryNew:
        return Icons.work_rounded;
      case AppStrings.catSellingAssets:
        return Icons.monetization_on_rounded;
      case "Netflix":
        return Icons.movie_outlined;
      case "Food":
        return Icons.fastfood_outlined;
      case "Transport":
        return Icons.directions_car_outlined;
      case "Shopping":
        return Icons.shopping_bag_outlined;
      case "Upwork":
        return Icons.work_outline;
      case "Freelance":
        return Icons.computer_outlined;
      default:
        return isIncome ? Icons.add_circle_outline : Icons.shopping_cart_outlined;
    }
  }

  static Widget buildHeader({
    required BuildContext context,
    required bool isEdit,
    required bool isIncome,
    required VoidCallback onBack,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ClipPath(
          clipper: ExpenseHeaderClipper(),
          child: Container(
            height: 240,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -40,
                  left: -40,
                  child: CircleAvatar(
                    radius: 90,
                    backgroundColor: Colors.white.withAlpha(15),
                  ),
                ),
                Positioned(
                  right: -20,
                  top: 40,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white.withAlpha(15),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: onBack,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.arrow_back_ios,
                                    color: AppColors.white, size: 18),
                              ),
                            ),
                            Text(
                              isEdit
                                  ? (isIncome
                                      ? "Edit ${AppStrings.income}"
                                      : "Edit ${AppStrings.expenses}")
                                  : (isIncome
                                      ? "Add ${AppStrings.income}"
                                      : "Add ${AppStrings.expenses}"),
                              style: AppTextStyles.heading2.copyWith(
                                  color: AppColors.white, fontSize: 18),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildTabSwitcher({
    required BuildContext context,
    required bool isIncome,
    required Function(bool) onToggle,
  }) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.tabBg,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: !isIncome ? c.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: !isIncome
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 14,
                      color: !isIncome
                          ? AppColors.expenseRed
                          : c.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.expenses
                          .substring(0, AppStrings.expenses.length - 1),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: !isIncome ? AppColors.primary : c.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: isIncome ? c.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isIncome
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 14,
                      color: isIncome
                          ? AppColors.incomeGreen
                          : c.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.income,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isIncome ? AppColors.primary : c.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildScanReceiptCard({
    required BuildContext context,
    required bool isScanning,
    required VoidCallback onTap,
    String? scannedMerchant,
    double? confidence,
  }) {
    final c = context.appColors;
    final bool hasResult = scannedMerchant != null && !isScanning;
    final bool isLowConfidence = hasResult && (confidence ?? 1.0) < 0.75;

    // Border color reflects scan state
    final Color borderColor = isScanning
        ? AppColors.primary
        : hasResult
            ? (isLowConfidence ? Colors.orange.shade400 : Colors.green.shade400)
            : c.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isScanning ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon / state indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasResult
                        ? (isLowConfidence
                            ? Colors.orange.withOpacity(0.12)
                            : Colors.green.withOpacity(0.12))
                        : AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isScanning
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : Icon(
                          hasResult
                              ? (isLowConfidence
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline_rounded)
                              : Icons.document_scanner_rounded,
                          color: hasResult
                              ? (isLowConfidence
                                  ? Colors.orange.shade600
                                  : Colors.green.shade600)
                              : AppColors.primary,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            isScanning
                                ? "Analysing Receipt..."
                                : hasResult
                                    ? "Receipt Scanned"
                                    : "Scan Receipt",
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "AI",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isScanning
                            ? "Gemini is reading your receipt..."
                            : hasResult
                                ? "Tap to re-scan with a different photo"
                                : "Auto-fill amount, date & category with photo",
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isScanning)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.tabBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasResult
                          ? Icons.refresh_rounded
                          : Icons.camera_alt_rounded,
                      color: c.textSecondary,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // ── Detected result chip ─────────────────────────────────────────────
        if (hasResult) ...[
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: hasResult ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLowConfidence
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLowConfidence
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLowConfidence
                        ? Icons.info_outline_rounded
                        : Icons.auto_awesome_rounded,
                    size: 13,
                    color: isLowConfidence
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isLowConfidence
                          ? "Low confidence — please verify the fields above"
                          : "Detected: $scannedMerchant",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isLowConfidence
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }


  static Widget buildDropdownField({
    required BuildContext context,
    required String value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
  }) {
    final c = context.appColors;
    final selectedItem = items.firstWhere(
      (cat) => cat['name'] == value,
      orElse: () => items.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: c.card,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textSecondary),
          isExpanded: true,
          onChanged: onChanged,
          selectedItemBuilder: (context) {
            return items.map((category) {
              return Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: (selectedItem['color'] as Color).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(selectedItem['icon'],
                          color: selectedItem['color'], size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category['name'],
                    style: AppTextStyles.bodyLarge.copyWith(
                        color: c.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }).toList();
          },
          items: items.map((Map<String, dynamic> category) {
            return DropdownMenuItem<String>(
              value: category['name'],
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: (category['color'] as Color).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(category['icon'],
                          color: category['color'], size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category['name'],
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: c.textPrimary),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  static Widget buildAmountField({
    required BuildContext context,
    required TextEditingController controller,
    required VoidCallback onClear,
  }) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "₹ 0.00",
          hintStyle: AppTextStyles.heading2
              .copyWith(color: AppColors.primary.withOpacity(0.3), fontSize: 20),
          suffixIcon: GestureDetector(
            onTap: onClear,
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.tabBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Clear",
                style: AppTextStyles.bodySmall.copyWith(
                    color: c.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildDateField({
    required BuildContext context,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_outlined,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEE, dd MMM yyyy', 'en_US').format(date),
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: c.textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Icon(Icons.chevron_right_rounded, color: c.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  static Widget buildInvoiceUploader({
    required BuildContext context,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    final c = context.appColors;
    final bool hasFile = fileName != null;
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        color: hasFile ? AppColors.primary : c.border,
        strokeWidth: 1.5,
        dashPattern: const [7, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: hasFile ? AppColors.primary.withOpacity(0.05) : c.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasFile
                      ? AppColors.primary.withOpacity(0.15)
                      : c.tabBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasFile
                      ? Icons.check_circle_outline
                      : Icons.upload_file_rounded,
                  color: hasFile ? AppColors.primary : c.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hasFile ? fileName : "Attach Invoice",
                style: AppTextStyles.bodyMedium.copyWith(
                    color: hasFile ? AppColors.primary : c.textPrimary,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                hasFile ? "Tap to change file" : "PDF, PNG, JPG supported",
                style: AppTextStyles.bodySmall
                    .copyWith(color: c.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);

    var controlPoint = Offset(size.width / 2, size.height + 20);
    var endPoint = Offset(size.width, size.height - 50);

    path.quadraticBezierTo(
        controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
