import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

/// Horizontal scrollable filter chip bar for the Transactions screen.
class TransactionFilterBar extends StatelessWidget {
  const TransactionFilterBar({
    super.key,
    required this.activeFilters,
    required this.onToggle,
    required this.onClearAll,
  });

  final Set<String> activeFilters;
  final void Function(String filter) onToggle;
  final VoidCallback onClearAll;

  static const String filterIncome = 'Income';
  static const String filterExpense = 'Expense';
  static const String filterSubscription = 'Subscription';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          _FilterChip(
            label: activeFilters.isEmpty
                ? 'All'
                : 'Clear (${activeFilters.length})',
            isSelected: activeFilters.isEmpty,
            selectedColor: Colors.black,
            onTap: onClearAll,
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: filterIncome,
            isSelected: activeFilters.contains(filterIncome),
            selectedColor: AppColors.incomeGreen,
            onTap: () => onToggle(filterIncome),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: filterExpense,
            isSelected: activeFilters.contains(filterExpense),
            selectedColor: AppColors.expenseRed,
            onTap: () => onToggle(filterExpense),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: filterSubscription,
            isSelected: activeFilters.contains(filterSubscription),
            selectedColor: AppColors.primary,
            onTap: () => onToggle(filterSubscription),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color textColor;
    if (isSelected) {
      if (selectedColor == Colors.black) {
        bg = isDark ? Colors.white : Colors.black;
        textColor = isDark ? Colors.black : Colors.white;
      } else {
        bg = selectedColor;
        textColor = Colors.white;
      }
    } else {
      bg = c.tabBg;
      textColor = c.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? bg : c.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: bg.withAlpha(60),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
