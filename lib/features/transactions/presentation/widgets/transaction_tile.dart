import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';

class TransactionTile extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final bool isIncome;
  final String category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.category,
    this.onEdit,
    this.onDelete,
  });

  IconData _getCategoryIcon() {
    switch (category) {
      case AppStrings.catNetflix:
        return Icons.movie_outlined;
      case AppStrings.catFood:
        return Icons.fastfood_outlined;
      case AppStrings.catTransport:
        return Icons.directions_car_outlined;
      case AppStrings.catShopping:
        return Icons.shopping_bag_outlined;
      case AppStrings.catSalary:
        return Icons.attach_money;
      case AppStrings.catUpwork:
        return Icons.work_outline;
      case AppStrings.catInterest:
        return Icons.account_balance_outlined;
      case AppStrings.catFreelance:
        return Icons.computer_outlined;
      case AppStrings.catOther:
        return Icons.more_horiz;
      default:
        return isIncome
            ? Icons.add_circle_outline
            : Icons.shopping_cart_outlined;
    }
  }

  Color _getCategoryColor() {
    switch (category) {
      case AppStrings.catNetflix:
        return Colors.red;
      case AppStrings.catFood:
        return Colors.orange;
      case AppStrings.catTransport:
        return Colors.purple;
      case AppStrings.catShopping:
        return Colors.pink;
      case AppStrings.catSalary:
        return Colors.blue;
      case AppStrings.catUpwork:
        return Colors.green;
      case AppStrings.catInterest:
        return Colors.amber;
      case AppStrings.catFreelance:
        return Colors.teal;
      case AppStrings.catOther:
        return const Color(0xFF90A4AE); // Blue Grey
      default:
        return isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Section
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: _getCategoryColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Date Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount & Menu Section (Horizontal Row)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${isIncome ? "+" : "-"} ₹ $amount",
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isIncome
                            ? AppColors.incomeGreen
                            : AppColors.expenseRed,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onEdit != null || onDelete != null)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.more_vert,
                            color: AppColors.textSecondary, size: 18),
                        onSelected: (value) {
                          if (value == 'edit') onEdit?.call();
                          if (value == 'delete') onDelete?.call();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text(AppStrings.edit),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(AppStrings.delete,
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
