import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/text_styles.dart';

class StatisticsHelper {
  static Widget buildHeader({VoidCallback? onDownload}) {
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
            "Statistics",
            style: AppTextStyles.heading2.copyWith(fontSize: 20),
          ),
          IconButton(
            icon: Icon(Icons.download_outlined,
                color: AppColors.textPrimary, size: 28),
            onPressed: onDownload,
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
          Text("Top Spending",
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.secondary : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                image: isHighlighted
                    ? const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/150?img=5'))
                    : null),
            child:
                isHighlighted ? null : Icon(icon, color: AppColors.secondary),
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
                    color:
                        isHighlighted ? AppColors.white : AppColors.textPrimary,
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
    );
  }
}
