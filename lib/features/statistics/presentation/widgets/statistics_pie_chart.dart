import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';

class StatisticsPieChart extends StatelessWidget {
  const StatisticsPieChart({
    super.key,
    required this.pieSections,
    required this.topSpendingList,
    required this.totalInFilter,
    required this.touchedIndex,
    required this.selectedTransactionType,
    required this.onSelectionChanged,
  });

  final List<PieChartSectionData> pieSections;
  final List<Map<String, dynamic>> topSpendingList;
  final double totalInFilter;
  final int touchedIndex;
  final String selectedTransactionType;
  final Function(int index) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 200,
        child: pieSections.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 60,
                      color: c.textSecondary.withAlpha(80),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.noData,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  PieChart(
                    key: ValueKey("pie_${pieSections.length}_${touchedIndex}_$selectedTransactionType"),
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            onSelectionChanged(-1);
                            return;
                          }
                          onSelectionChanged(
                              pieTouchResponse.touchedSection!.touchedSectionIndex);
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 55,
                      sections: pieSections,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          touchedIndex == -1
                              ? AppStrings.total
                              : topSpendingList[touchedIndex]['title'],
                          style: AppTextStyles.bodySmall.copyWith(
                            color: c.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          touchedIndex == -1
                              ? "₹ ${totalInFilter.toStringAsFixed(0)}"
                              : "₹ ${topSpendingList[touchedIndex]['amount'].toStringAsFixed(0)}",
                          style: AppTextStyles.heading1.copyWith(
                            color: c.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
