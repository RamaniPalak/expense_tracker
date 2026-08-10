import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';

class CalendarMonthView extends StatelessWidget {
  final DateTime currentMonthYear;
  final DateTime selectedDate;
  final List<TransactionModel> allExpenses;
  final Function(DateTime) onDateSelected;

  const CalendarMonthView({
    super.key,
    required this.currentMonthYear,
    required this.selectedDate,
    required this.allExpenses,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWeekdaysHeader(context),
        const SizedBox(height: 12),
        _buildMonthGrid(context),
      ],
    );
  }

  Widget _buildWeekdaysHeader(BuildContext context) {
    final weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    final c = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: c.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthGrid(BuildContext context) {
    final firstDay = DateTime(currentMonthYear.year, currentMonthYear.month, 1);
    final startOffset = firstDay.weekday % 7; // Sunday starts at 0
    final daysInMonth = DateTime(currentMonthYear.year, currentMonthYear.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.15,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < startOffset) {
          return const SizedBox.shrink();
        }
        final dayNumber = index - startOffset + 1;
        final cellDate = DateTime(currentMonthYear.year, currentMonthYear.month, dayNumber);
        final isSelected = selectedDate.year == cellDate.year &&
            selectedDate.month == cellDate.month &&
            selectedDate.day == cellDate.day;

        // Count transactions for this day
        final txCount = allExpenses.where((e) =>
            e.date.year == cellDate.year &&
            e.date.month == cellDate.month &&
            e.date.day == cellDate.day).length;

        return _buildDayCell(
          context,
          dayNumber: dayNumber,
          isSelected: isSelected,
          transactionCount: txCount,
          onTap: () => onDateSelected(cellDate),
        );
      },
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required int dayNumber,
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$dayNumber",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.textPrimary),
                  ),
                ),
                if (transactionCount > 0) ...[
                  const SizedBox(height: 1),
                  Text(
                    "$transactionCount",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white70
                          : AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
