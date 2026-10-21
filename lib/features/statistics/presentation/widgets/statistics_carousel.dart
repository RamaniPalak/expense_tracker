import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_helper.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_pie_chart.dart';

/// Carousel that switches between the Monthly Budget Summary and the Breakdown Pie Chart.
class StatisticsCarousel extends StatelessWidget {
  final PageController pageController;
  final int carouselPage;
  final ValueChanged<int> onPageChanged;
  final double totalBudget;
  final double totalSpent;
  final double walletBalance;
  final String monthYear;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool showNextMonth;
  final VoidCallback onSetBudget;
  final bool isIncomeMode;
  final Map<String, dynamic> insight;
  final String selectedTransactionType;
  final List<String> transactionTypes;
  final ValueChanged<String?> onTypeChanged;
  final List<PieChartSectionData> pieSections;
  final List<Map<String, dynamic>> topSpendingList;
  final double totalInFilter;
  final int touchedIndex;
  final ValueChanged<int> onPieSelectionChanged;

  const StatisticsCarousel({
    super.key,
    required this.pageController,
    required this.carouselPage,
    required this.onPageChanged,
    required this.totalBudget,
    required this.totalSpent,
    required this.walletBalance,
    required this.monthYear,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.showNextMonth,
    required this.onSetBudget,
    required this.isIncomeMode,
    required this.insight,
    required this.selectedTransactionType,
    required this.transactionTypes,
    required this.onTypeChanged,
    required this.pieSections,
    required this.topSpendingList,
    required this.totalInFilter,
    required this.touchedIndex,
    required this.onPieSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView(
            controller: pageController,
            onPageChanged: onPageChanged,
            children: [
              // ── Page 0: Monthly Budget Card (centered) ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatisticsHelper.buildMonthlyBudgetCard(
                      context: context,
                      totalBudget: totalBudget,
                      totalSpent: totalSpent,
                      monthYear: monthYear,
                      onPreviousMonth: onPreviousMonth,
                      onNextMonth: onNextMonth,
                      showNextMonth: showNextMonth,
                      availableBalance: walletBalance,
                      onSetBudget: onSetBudget,
                    ),
                    if (!isIncomeMode) ...[
                      const SizedBox(height: 8),
                      StatisticsHelper.buildSpendingInsightCard(
                        context: context,
                        currentTotal: insight['current'],
                        previousTotal: insight['previous'],
                        difference: insight['difference'],
                        isIncrease: insight['isIncrease'],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Page 1: Expense Breakdown Pie Chart ──
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isIncomeMode
                                ? "Income Breakdown"
                                : "Expense Breakdown",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          StatisticsHelper.buildTypeDropdown(
                            context: context,
                            selectedType: selectedTransactionType,
                            types: transactionTypes,
                            onChanged: onTypeChanged,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    StatisticsPieChart(
                      pieSections: pieSections,
                      topSpendingList: topSpendingList,
                      totalInFilter: totalInFilter,
                      touchedIndex: touchedIndex,
                      selectedTransactionType: selectedTransactionType,
                      onSelectionChanged: onPieSelectionChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── Dot Indicators ──
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (i) {
            final isActive = carouselPage == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
