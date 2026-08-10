import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onTap;
  final VoidCallback onDepositTap;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    required this.onDepositTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final color = Color(goal.colorValue);
    // ignore: non_const_argument_for_const_parameter
    final iconData = IconData(goal.iconCode, fontFamily: 'MaterialIcons');
    final percent = goal.progressPercent100;
    final isCompleted = goal.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted ? AppColors.incomeGreen.withAlpha(120) : c.border,
            width: isCompleted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon, Title, Category & Percentage Badge
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withAlpha(35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(iconData, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (goal.priority == 'High')
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.expenseRed.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('🚨 High', style: TextStyle(color: AppColors.expenseRed, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          else if (goal.priority == 'Low')
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.border,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('🎯 Low', style: TextStyle(color: c.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          if (goal.isPaused)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Paused ⏸️', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          Expanded(
                            child: Text(
                              '${goal.category} • Target: ${DateFormat('MMM dd, yyyy').format(goal.targetDate)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                                color: c.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.incomeGreen.withAlpha(35)
                        : color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'Done 🎉' : (goal.isPaused ? 'Paused' : '$percent%'),
                    style: TextStyle(
                      color: isCompleted ? AppColors.incomeGreen : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progressPercentage,
                minHeight: 8,
                backgroundColor: c.border.withAlpha(100),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppColors.incomeGreen : color,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Bottom Row: Amounts & Quick Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Saved ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(goal.currentAmount)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'of ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(goal.targetAmount)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onDepositTap,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Deposit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
