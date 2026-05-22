import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

void showCalendarViewModeSheet({
  required BuildContext context,
  required String currentViewMode,
  required Function(String) onViewModeSelected,
}) {
  final c = context.appColors;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Select View Mode",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildViewModeOption(
                  context,
                  title: "Month View",
                  icon: Icons.grid_view,
                  isSelected: currentViewMode == "Month",
                  onTap: () {
                    onViewModeSelected("Month");
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildViewModeOption(
                  context,
                  title: "Year View",
                  icon: Icons.calendar_month,
                  isSelected: currentViewMode == "Year",
                  onTap: () {
                    onViewModeSelected("Year");
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildViewModeOption(
  BuildContext context, {
  required String title,
  required IconData icon,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  final c = context.appColors;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : c.tabBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : c.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : c.textPrimary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    ),
  );
}
