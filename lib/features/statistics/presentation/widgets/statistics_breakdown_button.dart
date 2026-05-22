import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';

class StatisticsBreakdownButton extends StatelessWidget {
  const StatisticsBreakdownButton({
    super.key,
    required this.isIncomeMode,
    required this.onTap,
  });

  final bool isIncomeMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: isIncomeMode
                ? AppColors.incomeGradient
                : AppColors.mainGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  "View ${isIncomeMode ? 'Income' : 'Expense'} Category Breakdown",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
