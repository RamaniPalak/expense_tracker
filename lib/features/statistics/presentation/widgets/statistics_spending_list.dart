import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_helper.dart';

class StatisticsSpendingList extends StatelessWidget {
  const StatisticsSpendingList({
    super.key,
    required this.topSpendingList,
    required this.isIncomeMode,
    required this.selectedSpendingIndex,
    required this.onItemTapped,
  });

  final List<Map<String, dynamic>> topSpendingList;
  final bool isIncomeMode;
  final int selectedSpendingIndex;
  final Function(int index) onItemTapped;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: topSpendingList.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "No data for this period",
                  style: TextStyle(color: c.textSecondary),
                ),
              ),
            )
          : Column(
              children: List.generate(topSpendingList.length, (index) {
                final item = topSpendingList[index];
                return GestureDetector(
                  onTap: () => onItemTapped(index),
                  child: Column(
                    children: [
                      StatisticsHelper.buildSpendingItem(
                        context: context,
                        icon: item['icon'],
                        title: item['title'],
                        date: DateFormat('MMM dd, yyyy').format(item['latestDate']),
                        amount:
                            "${isIncomeMode ? '+' : '-'} ₹ ${item['amount'].toStringAsFixed(2)}",
                        isHighlighted: index == selectedSpendingIndex,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              }),
            ),
    );
  }
}
