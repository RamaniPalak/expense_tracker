import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

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
        return isIncome ? Icons.add_circle_outline : Icons.shopping_cart_outlined;
    }
  }

  Color _getCategoryColor() {
    switch (category) {
      case AppStrings.catNetflix:
        return AppColors.catNetflix;
      case AppStrings.catFood:
        return AppColors.catFood;
      case AppStrings.catTransport:
        return AppColors.catTransport;
      case AppStrings.catShopping:
        return const Color(0xFFFF69B4);
      case AppStrings.catSalary:
        return Colors.blue;
      case AppStrings.catUpwork:
        return AppColors.catUpwork;
      case AppStrings.catInterest:
        return Colors.amber;
      case AppStrings.catFreelance:
        return Colors.teal;
      case AppStrings.catOther:
        return const Color(0xFF90A4AE);
      default:
        return isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final catColor = _getCategoryColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon Section (Tighter 44x44 container)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getCategoryIcon(), color: catColor, size: 20),
                ),
                const SizedBox(width: 14),

                // Title & Date Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        date,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontSize: 12, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  "${isIncome ? "+" : "-"} ₹$amount",
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (onEdit != null || onDelete != null) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.more_vert, color: c.textSecondary, size: 20),
                    color: c.card,
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: c.textPrimary),
                            const SizedBox(width: 8),
                            Text(AppStrings.edit, style: TextStyle(color: c.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(AppStrings.delete, style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
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
