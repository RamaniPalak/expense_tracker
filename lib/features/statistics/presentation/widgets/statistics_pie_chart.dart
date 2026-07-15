import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_helper.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final isIncomeMode = selectedTransactionType == AppStrings.income;

    if (pieSections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 200,
          child: Center(
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 200,
            child: Stack(
              children: [
                // 1. Subtle background track (drawn behind the active sections)
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 65,
                    borderData: FlBorderData(show: false),
                    startDegreeOffset: 0,
                    sections: [
                      PieChartSectionData(
                        color: c.divider.withOpacity(0.4),
                        value: 1,
                        radius: 24,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                // 2. Interactive Pie Chart sections
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
                    sectionsSpace: pieSections.length > 1 ? 3 : 0,
                    centerSpaceRadius: 65,
                    sections: pieSections,
                  ),
                ),
                // 3. Central Hierarchy Info
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (touchedIndex == -1
                                ? (isIncomeMode ? "TOTAL INCOME" : "TOTAL SPENT")
                                : topSpendingList[touchedIndex]['title'].toString().toUpperCase()),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: c.textSecondary.withOpacity(0.8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        touchedIndex == -1
                            ? "₹${totalInFilter.toStringAsFixed(0)}"
                            : "₹${topSpendingList[touchedIndex]['amount'].toStringAsFixed(0)}",
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 4. Interactive Legends
        _buildLegends(context, c, isIncomeMode),
      ],
    );
  }

  Widget _buildLegends(BuildContext context, dynamic c, bool isIncomeMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(topSpendingList.length, (index) {
          final item = topSpendingList[index];
          final isTouched = index == touchedIndex;
          final percentage = totalInFilter > 0
              ? (item['amount'] as double) / totalInFilter * 100
              : 0.0;
          final color = StatisticsHelper.getCategoryColor(
            item['title'] as String,
            isIncome: isIncomeMode,
          );

          return GestureDetector(
            onTap: () => onSelectionChanged(isTouched ? -1 : index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isTouched ? color.withOpacity(0.08) : c.card.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isTouched ? color.withOpacity(0.3) : c.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['title'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isTouched ? FontWeight.bold : FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${percentage.toStringAsFixed(0)}%",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                      color: isTouched ? color : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
