import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/add_expense_helper.dart';

class StatisticsHelper {
  static Widget buildHeader({
    required BuildContext context,
    VoidCallback? onDownload,
    VoidCallback? onAdjustBudget,
  }) {
    final c = context.appColors;
    final double rightWidth = (onAdjustBudget != null ? 2 : 1) * 48.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          SizedBox(width: rightWidth),
          Expanded(
            child: Center(
              child: Text(
                AppStrings.statistics,
                style: AppTextStyles.heading2.copyWith(fontSize: 20, color: c.textPrimary),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onAdjustBudget != null)
                IconButton(
                  icon: Icon(Icons.account_balance_wallet_outlined,
                      color: c.textPrimary, size: 28),
                  onPressed: onAdjustBudget,
                ),
              IconButton(
                icon: Icon(Icons.download_outlined,
                    color: c.textPrimary, size: 28),
                onPressed: onDownload,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildTimeFilters({
    required List<String> filters,
    required String selectedFilter,
    required Function(String) onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(filter),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  filter,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color:
                        isSelected ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget buildTypeDropdown({
    required BuildContext context,
    required String selectedType,
    required List<String> types,
    required Function(String?) onChanged,
  }) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          dropdownColor: c.card,
          icon: Icon(Icons.keyboard_arrow_down,
              color: c.textPrimary),
          elevation: 16,
          style:
              AppTextStyles.bodyMedium.copyWith(color: c.textPrimary),
          onChanged: onChanged,
          items: types.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: TextStyle(color: c.textPrimary)),
            );
          }).toList(),
        ),
      ),
    );
  }

  static Widget buildSpendingHeader({required BuildContext context}) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.topSpending,
            style: AppTextStyles.heading2.copyWith(fontSize: 18, color: c.textPrimary),
          ),
          Icon(Icons.import_export, color: c.textSecondary),
        ],
      ),
    );
  }

  static Widget buildSpendingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String date,
    required String amount,
    bool isHighlighted = false,
    double? progress,
  }) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primary : c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isHighlighted ? Colors.transparent : c.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: isHighlighted 
              ? AppColors.primary.withOpacity(0.3) 
              : c.shadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.white24 : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isHighlighted ? Colors.white : AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isHighlighted ? Colors.white : c.textPrimary,
                      ),
                    ),
                    Text(
                      date,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 13,
                        color: isHighlighted ? Colors.white70 : c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isHighlighted ? Colors.white : AppColors.expenseRed,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: isHighlighted ? Colors.white24 : c.tabBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.orangeAccent : (isHighlighted ? Colors.white : AppColors.primary),
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(progress * 100).toInt()}% ${AppStrings.used}",
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: isHighlighted ? Colors.white70 : c.textSecondary,
                  ),
                ),
                if (progress >= 1.0)
                  Text(
                    AppStrings.exceeded,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: isHighlighted ? Colors.orangeAccent : AppColors.expenseRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildMonthlyBudgetCard({
    required BuildContext context,
    required double totalBudget,
    required double totalSpent,
    required String monthYear,
    required VoidCallback onPreviousMonth,
    required VoidCallback onNextMonth,
    bool showNextMonth = true,
    double? availableBalance,
    VoidCallback? onSetBudget,
  }) {
    final progress = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final isOverBudget = totalSpent > totalBudget && totalBudget > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isOverBudget 
            ? const LinearGradient(colors: [AppColors.expenseRed, Color(0xFFFF8E8E)]) 
            : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isOverBudget ? AppColors.expenseRed : AppColors.secondary)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white70),
                    onPressed: onPreviousMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      monthYear,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showNextMonth)
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white70),
                      onPressed: onNextMonth,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  final c = context.appColors;
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: c.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            AppStrings.budgetInfo, 
                            style: AppTextStyles.heading2.copyWith(color: c.textPrimary, fontSize: 20),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.budgetDescription, 
                            style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow(context, AppStrings.budgetTarget, "₹ ${totalBudget.toStringAsFixed(2)}"),
                          _buildInfoRow(context, AppStrings.actualSpent, "₹ ${totalSpent.toStringAsFixed(2)}"),
                          _buildInfoRow(context, AppStrings.remaining, "₹ ${(totalBudget - totalSpent).clamp(0, double.infinity).toStringAsFixed(2)}", isBold: true),
                          Divider(height: 30, color: c.divider),
                          Text(
                            AppStrings.budgetTip, 
                            style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic, color: c.textSecondary),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            AppStrings.gotIt, 
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(Icons.info_outline, color: Colors.white70, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (totalBudget > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.budgetTarget,
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.white70, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "₹ ${totalBudget.toStringAsFixed(2)}",
                        style: AppTextStyles.heading1
                            .copyWith(color: Colors.white, fontSize: 24),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (availableBalance != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppStrings.walletBalance,
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "₹ ${availableBalance.toStringAsFixed(2)}",
                          style: AppTextStyles.heading2
                              .copyWith(color: Colors.white, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${AppStrings.spent}: ₹ ${totalSpent.toStringAsFixed(2)}",
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${AppStrings.remaining}: ₹ ${(totalBudget - totalSpent).clamp(0, double.infinity).toStringAsFixed(2)}",
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withAlpha(51),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.orangeAccent : Colors.white
                ),
                minHeight: 10,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  const Text(
                    AppStrings.noBudgetSet,
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: onSetBudget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(AppStrings.setMonthlyBudget),
                  ),
                ],
              ),
            ),
          ],
          if (isOverBudget)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                AppStrings.budgetWarning,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(BuildContext context, String label, String value, {bool isBold = false}) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: c.textSecondary)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.primary : c.textPrimary,
          )),
        ],
      ),
    );
  }

  static Widget buildSpendingInsightCard({
    required BuildContext context,
    required double currentTotal,
    required double previousTotal,
    required double difference,
    required bool isIncrease,
  }) {
    if (previousTotal == 0) return const SizedBox.shrink();

    final c = context.appColors;
    final color = isIncrease ? Colors.redAccent : Colors.green;
    final icon = isIncrease ? Icons.trending_up : Icons.trending_down;
    final text = isIncrease ? "Spending increased by" : "Spending decreased by";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: c.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "${difference.abs().toStringAsFixed(1)}% vs last month",
                  style: AppTextStyles.heading2.copyWith(
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Last Month",
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: c.textSecondary),
              ),
              Text(
                "₹ ${previousTotal.toStringAsFixed(0)}",
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color getCategoryColor(String category, {bool isIncome = false}) {
    return AddExpenseHelper.getCategoryColor(category, isIncome: isIncome);
  }

  static IconData getCategoryIcon(String category, {bool isIncome = false}) {
    return AddExpenseHelper.getCategoryIcon(category, isIncome: isIncome);
  }
}
