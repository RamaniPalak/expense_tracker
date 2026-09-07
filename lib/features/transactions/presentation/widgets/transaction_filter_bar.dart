import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:intl/intl.dart';

/// Horizontal scrollable filter chip bar for the Transactions screen.
class TransactionFilterBar extends StatelessWidget {
  const TransactionFilterBar({
    super.key,
    required this.activeFilters,
    required this.onToggle,
    required this.onClearAll,
    this.dateFrom,
    this.dateTo,
    this.onDateRangeTap,
    this.onClearDateRange,
  });

  final Set<String> activeFilters;
  final void Function(String filter) onToggle;
  final VoidCallback onClearAll;

  // Optional date-range state — null means no date filter active
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final VoidCallback? onDateRangeTap;
  final VoidCallback? onClearDateRange;

  static const String filterIncome = 'Income';
  static const String filterExpense = 'Expense';
  static const String filterSubscription = 'Subscription';

  bool get _hasDateFilter => dateFrom != null || dateTo != null;

  String get _dateLabel {
    final fmt = DateFormat('MMM d');
    if (dateFrom != null && dateTo != null) {
      return '${fmt.format(dateFrom!)} – ${fmt.format(dateTo!)}';
    } else if (dateFrom != null) {
      return 'From ${fmt.format(dateFrom!)}';
    } else if (dateTo != null) {
      return 'Until ${fmt.format(dateTo!)}';
    }
    return 'Date Range';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          _FilterChip(
            label: (activeFilters.isEmpty && !_hasDateFilter)
                ? 'All'
                : 'Clear (${activeFilters.length + (_hasDateFilter ? 1 : 0)})',
            isSelected: activeFilters.isEmpty && !_hasDateFilter,
            selectedColor: Colors.black,
            onTap: () {
              onClearAll();
              onClearDateRange?.call();
            },
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
          if (onDateRangeTap != null) ...[
            const SizedBox(width: 10),
            _DateRangeChip(
              label: _dateLabel,
              isActive: _hasDateFilter,
              onTap: onDateRangeTap!,
              onClear: _hasDateFilter ? onClearDateRange : null,
            ),
          ],
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

/// A special chip for the date range filter — shows a calendar icon,
/// the active range label, and an ✕ clear button when active.
class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bg = isActive ? AppColors.primary : c.tabBg;
    final textColor = isActive ? Colors.white : c.textSecondary;
    final borderColor = isActive ? AppColors.primary : c.border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(
          left: 12,
          right: onClear != null ? 4 : 12,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range_rounded, size: 14, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded, size: 14, color: textColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
