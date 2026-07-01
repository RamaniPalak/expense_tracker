import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';

class CalendarYearView extends StatelessWidget {
  final int currentYear;
  final int selectedMonthIndex;
  final List<TransactionModel> allExpenses;
  final Function(int monthIndex, DateTime cellDate) onMonthSelected;

  const CalendarYearView({
    super.key,
    required this.currentYear,
    required this.selectedMonthIndex,
    required this.allExpenses,
    required this.onMonthSelected,
  });

  static const List<String> _monthsList = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final monthIndex = index + 1; // 1 to 12
        final isSelected = selectedMonthIndex == monthIndex;
        
        // Count transactions in this month
        final txCount = allExpenses.where((e) =>
            e.date.year == currentYear &&
            e.date.month == monthIndex).length;

        return _buildMonthCell(
          context,
          monthAbbreviation: _monthsList[index],
          isSelected: isSelected,
          transactionCount: txCount,
          onTap: () {
            onMonthSelected(monthIndex, DateTime(currentYear, monthIndex, 1));
          },
        );
      },
    );
  }

  Widget _buildMonthCell(
    BuildContext context, {
    required String monthAbbreviation,
    required bool isSelected,
    required int transactionCount,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1F2235) : const Color(0xFFF5F7FA)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                monthAbbreviation,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
              if (transactionCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.25)
                        : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "$transactionCount",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
