import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class CalendarSummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double savings;

  const CalendarSummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.savings,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121B35) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryColumn(
            context,
            label: "Income",
            value: "₹${income.toStringAsFixed(2)}",
            valueColor: AppColors.incomeGreen,
          ),
          _buildSummaryDivider(context),
          _buildSummaryColumn(
            context,
            label: "Expense",
            value: "₹${expense.toStringAsFixed(2)}",
            valueColor: AppColors.expenseRed,
          ),
          _buildSummaryDivider(context),
          _buildSummaryColumn(
            context,
            label: "Savings",
            value: "${savings < 0 ? '-' : ''}₹${savings.abs().toStringAsFixed(2)}",
            valueColor: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
  }) {
    final c = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: c.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryDivider(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: 1,
      height: 30,
      color: c.divider.withValues(alpha: 0.5),
    );
  }
}
