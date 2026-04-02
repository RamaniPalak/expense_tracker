import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';

class StatisticsHelper {
  static Widget buildHeader({VoidCallback? onDownload, VoidCallback? onAdjustBudget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () {
              // Navigation handled by parent
            },
          ),
          Text(
            AppStrings.statistics,
            style: AppTextStyles.heading2.copyWith(fontSize: 20),
          ),
          Row(
            children: [
              if (onAdjustBudget != null)
                IconButton(
                  icon: const Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.textPrimary, size: 28),
                  onPressed: onAdjustBudget,
                ),
              IconButton(
                icon: const Icon(Icons.download_outlined,
                    color: AppColors.textPrimary, size: 28),
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
    required String selectedType,
    required List<String> types,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textPrimary),
          elevation: 16,
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          onChanged: onChanged,
          items: types.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  static Widget buildSpendingHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppStrings.topSpending,
              style: AppTextStyles.heading2.copyWith(fontSize: 18)),
          const Icon(Icons.import_export, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  static Widget buildSpendingItem({
    required IconData icon,
    required String title,
    required String date,
    required String amount,
    bool isHighlighted = false,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.secondary : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.secondary.withAlpha(102),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.secondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 16,
                        color: isHighlighted
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      date,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isHighlighted
                            ? AppColors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 16,
                  color: isHighlighted ? AppColors.white : AppColors.expenseRed,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.greyLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? AppColors.expenseRed : AppColors.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(progress * 100).toInt()}% ${AppStrings.used}",
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: isHighlighted
                        ? AppColors.white70
                        : AppColors.textSecondary,
                  ),
                ),
                if (progress >= 1.0)
                  Text(
                    AppStrings.exceeded,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.expenseRed,
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
    double? availableBalance,
    VoidCallback? onSetBudget,
  }) {
    final progress = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final isOverBudget = totalSpent > totalBudget && totalBudget > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverBudget 
              ? [AppColors.expenseRed, AppColors.secondary] 
              : [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isOverBudget ? AppColors.expenseRed : AppColors.primary)
                .withAlpha(76),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.monthlyOverview,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(AppStrings.budgetInfo, style: AppTextStyles.heading2),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.budgetDescription, style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 15),
                          _buildInfoRow(AppStrings.budgetTarget, "₹ ${totalBudget.toStringAsFixed(2)}"),
                          _buildInfoRow(AppStrings.actualSpent, "₹ ${totalSpent.toStringAsFixed(2)}"),
                          _buildInfoRow(AppStrings.remaining, "₹ ${(totalBudget - totalSpent).clamp(0, double.infinity).toStringAsFixed(2)}", isBold: true),
                          const Divider(height: 30),
                          Text(AppStrings.budgetTip, 
                            style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(AppStrings.gotIt, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
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

  static Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.primary : Colors.black87,
          )),
        ],
      ),
    );
  }
}
