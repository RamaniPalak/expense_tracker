import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class UpcomingBillTile extends StatelessWidget {
  final String title;
  final String date;
  final VoidCallback onPayTap;

  const UpcomingBillTile({
    super.key,
    required this.title,
    required this.date,
    required this.onPayTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getIconForTitle(title),
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Due $date",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: c.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onPayTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Pay",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_fill_outlined; // Or custom generic icon
      case 'electricity':
        return Icons.bolt;
      case 'house rent':
        return Icons.home_filled;
      case 'spotify':
        return Icons.library_music;
      default:
        return Icons.receipt_long;
    }
  }
}
