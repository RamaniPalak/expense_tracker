import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/text_styles.dart';

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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForTitle(title),
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onPayTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.payButtonBackground, // Light cyan/mint color
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Pay",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
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
