import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

/// Row showing profile account status highlights (e.g. Budget status, Plan tier).
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ProfileStatItem(
              icon: Icons.account_balance_wallet_outlined,
              label: "Budget",
              value: "Active",
              color: AppColors.incomeGreen,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ProfileStatItem(
              icon: Icons.stars_outlined,
              label: "Plan",
              value: "Free Tier",
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// An individual stat tile inside [ProfileStatsRow].
class ProfileStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const ProfileStatItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.border.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: c.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
