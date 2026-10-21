import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';

/// Summary card displaying total income or expenses for non-monthly filter periods
/// (Week, Quarter, Year, Custom).
class StatisticsPeriodSummaryCard extends StatelessWidget {
  final String period;
  final double totalAmount;
  final bool isIncomeMode;
  final int transactionCount;
  final int selectedYear;
  final int selectedMonth;
  final DateTimeRange? selectedCustomRange;

  const StatisticsPeriodSummaryCard({
    super.key,
    required this.period,
    required this.totalAmount,
    required this.isIncomeMode,
    required this.transactionCount,
    required this.selectedYear,
    required this.selectedMonth,
    this.selectedCustomRange,
  });

  String get _periodTitle {
    switch (period) {
      case "Week":
        return "Last 7 Days";
      case "Quarter":
        final q = ((selectedMonth - 1) ~/ 3) + 1;
        return "Quarter $q, $selectedYear";
      case "Year":
        return "Year $selectedYear";
      case "Custom":
        if (selectedCustomRange != null) {
          return "${DateFormat('MMM d, y').format(selectedCustomRange!.start)} - ${DateFormat('MMM d, y').format(selectedCustomRange!.end)}";
        }
        return "Custom Range";
      default:
        return period;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _periodTitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "₹ ${totalAmount.toStringAsFixed(2)}",
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "$transactionCount ${isIncomeMode ? 'income entries' : 'expenses'}",
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncomeMode
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
