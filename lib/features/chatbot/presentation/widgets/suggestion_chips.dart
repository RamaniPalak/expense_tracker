import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class SuggestionChips extends StatelessWidget {
  final Function(String) onChipTapped;

  const SuggestionChips({super.key, required this.onChipTapped});

  static const List<String> _suggestions = [
    'Analyze my spending',
    'Monthly summary',
    'Can I afford lunch?',
    'Budget health',
    'Saving tips',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(_suggestions[index]),
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: c.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.primary.withAlpha(51)),
              ),
              onPressed: () => onChipTapped(_suggestions[index]),
            ),
          );
        },
      ),
    );
  }
}
