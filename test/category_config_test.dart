import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/constants/category_config.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/add_expense_helper.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_helper.dart';

void main() {
  group('CategoryConfig Centralization Tests', () {
    test(
        'CategoryConfig returns correct emojis for standard and alias categories',
        () {
      expect(CategoryConfig.getEmoji(AppStrings.catFoodDining), '🍔');
      expect(CategoryConfig.getEmoji('Food'), '🍔');
      expect(CategoryConfig.getEmoji(AppStrings.catNetflix), '🎬');
      expect(CategoryConfig.getEmoji(AppStrings.catSalary), '💼');
      expect(CategoryConfig.getEmoji('UnknownCategory'), '🏷️');
    });

    test(
        'CategoryConfig returns correct colors for standard categories and fallback',
        () {
      expect(CategoryConfig.getColor(AppStrings.catFoodDining),
          const Color(0xFFF59E0B));
      expect(CategoryConfig.getColor(AppStrings.catNetflix),
          const Color(0xFFFF4B4B));
      expect(CategoryConfig.getColor('Shopping'), const Color(0xFFFF69B4));

      // Fallback check
      final incomeFallback =
          CategoryConfig.getColor('NonExistent', isIncome: true);
      final expenseFallback =
          CategoryConfig.getColor('NonExistent', isIncome: false);
      expect(incomeFallback != expenseFallback, isTrue);
    });

    test('CategoryConfig returns correct pastel colors', () {
      expect(CategoryConfig.getPastelColor(AppStrings.catBills),
          const Color(0xFFE2FAFC));
      expect(CategoryConfig.getPastelColor('Unknown', isIncome: true),
          const Color(0xFFDCFCE7));
      expect(CategoryConfig.getPastelColor('Unknown', isIncome: false),
          const Color(0xFFFFEAEA));
    });

    test('CategoryConfig returns correct icons', () {
      expect(CategoryConfig.getIcon(AppStrings.catEducation),
          Icons.school_rounded);
      expect(
          CategoryConfig.getIcon(AppStrings.catNetflix), Icons.movie_outlined);
      expect(CategoryConfig.getIcon('Unknown', isIncome: true),
          Icons.add_circle_outline);
      expect(CategoryConfig.getIcon('Unknown', isIncome: false),
          Icons.shopping_cart_outlined);
    });

    test('AddExpenseHelper delegates correctly to CategoryConfig', () {
      expect(
        AddExpenseHelper.getCategoryEmoji(AppStrings.catFoodDining),
        CategoryConfig.getEmoji(AppStrings.catFoodDining),
      );
      expect(
        AddExpenseHelper.getCategoryColor(AppStrings.catFoodDining),
        CategoryConfig.getColor(AppStrings.catFoodDining),
      );
      expect(
        AddExpenseHelper.getCategoryPastelColor(AppStrings.catFoodDining),
        CategoryConfig.getPastelColor(AppStrings.catFoodDining),
      );
      expect(
        AddExpenseHelper.getCategoryIcon(AppStrings.catFoodDining),
        CategoryConfig.getIcon(AppStrings.catFoodDining),
      );
    });

    test('StatisticsHelper delegates correctly to CategoryConfig', () {
      expect(
        StatisticsHelper.getCategoryColor(AppStrings.catEntertainment),
        CategoryConfig.getColor(AppStrings.catEntertainment),
      );
      expect(
        StatisticsHelper.getCategoryIcon(AppStrings.catEntertainment),
        CategoryConfig.getIcon(AppStrings.catEntertainment),
      );
    });
  });
}
