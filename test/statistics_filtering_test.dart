import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';

void main() {
  group('Statistics Multi-Period Filtering Tests', () {
    List<TransactionModel> filterTransactions({
      required List<TransactionModel> data,
      required String filter,
      required int selectedYear,
      required int selectedMonth,
      DateTimeRange? selectedCustomRange,
      DateTime? simulatedNow,
    }) {
      final nowFull = simulatedNow ?? DateTime.now();
      final today = DateTime(nowFull.year, nowFull.month, nowFull.day);

      return data.where((e) {
        final eDate = DateTime(e.date.year, e.date.month, e.date.day);
        switch (filter) {
          case "Week":
            final diff = today.difference(eDate).inDays;
            return diff >= 0 && diff < 7;
          case "Month":
            return e.date.year == selectedYear && e.date.month == selectedMonth;
          case "Quarter":
            final selectedQuarter = (selectedMonth - 1) ~/ 3 + 1;
            final itemQuarter = (e.date.month - 1) ~/ 3 + 1;
            return e.date.year == selectedYear &&
                itemQuarter == selectedQuarter;
          case "Year":
            return e.date.year == selectedYear;
          case "Custom":
            if (selectedCustomRange == null) return true;
            final start = DateTime(
              selectedCustomRange.start.year,
              selectedCustomRange.start.month,
              selectedCustomRange.start.day,
            );
            final end = DateTime(
              selectedCustomRange.end.year,
              selectedCustomRange.end.month,
              selectedCustomRange.end.day,
              23,
              59,
              59,
            );
            return !e.date.isBefore(start) && !e.date.isAfter(end);
          default:
            return true;
        }
      }).toList();
    }

    final testItems = [
      TransactionModel(
        id: 1,
        title: 'Today Grocery',
        amount: 250,
        isIncome: false,
        date: DateTime(2026, 9, 22, 10, 0),
        category: 'Food',
        userEmail: 'user@test.com',
      ),
      TransactionModel(
        id: 2,
        title: '3 Days Ago Dinner',
        amount: 800,
        isIncome: false,
        date: DateTime(2026, 9, 19, 20, 0),
        category: 'Food',
        userEmail: 'user@test.com',
      ),
      TransactionModel(
        id: 3,
        title: '10 Days Ago Books',
        amount: 500,
        isIncome: false,
        date: DateTime(2026, 9, 12, 14, 0),
        category: 'Education',
        userEmail: 'user@test.com',
      ),
      TransactionModel(
        id: 4,
        title: 'August Shopping',
        amount: 3200,
        isIncome: false,
        date: DateTime(2026, 8, 15, 11, 0),
        category: 'Shopping',
        userEmail: 'user@test.com',
      ),
      TransactionModel(
        id: 5,
        title: 'March Flight (Q1)',
        amount: 6000,
        isIncome: false,
        date: DateTime(2026, 3, 10, 9, 0),
        category: 'Travel',
        userEmail: 'user@test.com',
      ),
      TransactionModel(
        id: 6,
        title: 'Last Year Item',
        amount: 1500,
        isIncome: false,
        date: DateTime(2025, 9, 20, 10, 0),
        category: 'Electronics',
        userEmail: 'user@test.com',
      ),
    ];

    test('Filter by "Week" only includes items within last 7 days', () {
      final simNow = DateTime(2026, 9, 22, 15, 0);
      final filtered = filterTransactions(
        data: testItems,
        filter: "Week",
        selectedYear: 2026,
        selectedMonth: 9,
        simulatedNow: simNow,
      );

      expect(filtered.length, 2);
      expect(filtered.map((e) => e.id), containsAll([1, 2]));
    });

    test('Filter by "Month" includes all items in selected month and year', () {
      final filteredSep = filterTransactions(
        data: testItems,
        filter: "Month",
        selectedYear: 2026,
        selectedMonth: 9,
      );

      expect(filteredSep.length, 3);
      expect(filteredSep.map((e) => e.id), containsAll([1, 2, 3]));

      final filteredAug = filterTransactions(
        data: testItems,
        filter: "Month",
        selectedYear: 2026,
        selectedMonth: 8,
      );

      expect(filteredAug.length, 1);
      expect(filteredAug.first.id, 4);
    });

    test('Filter by "Quarter" includes items across all 3 months of quarter',
        () {
      final filteredQ3 = filterTransactions(
        data: testItems,
        filter: "Quarter",
        selectedYear: 2026,
        selectedMonth: 9,
      );

      expect(filteredQ3.length, 4);
      expect(filteredQ3.map((e) => e.id), containsAll([1, 2, 3, 4]));

      final filteredQ1 = filterTransactions(
        data: testItems,
        filter: "Quarter",
        selectedYear: 2026,
        selectedMonth: 3,
      );

      expect(filteredQ1.length, 1);
      expect(filteredQ1.first.id, 5);
    });

    test(
        'Filter by "Year" includes all items in selected year regardless of month',
        () {
      final filtered2026 = filterTransactions(
        data: testItems,
        filter: "Year",
        selectedYear: 2026,
        selectedMonth: 9,
      );

      expect(filtered2026.length, 5);

      final filtered2025 = filterTransactions(
        data: testItems,
        filter: "Year",
        selectedYear: 2025,
        selectedMonth: 9,
      );

      expect(filtered2025.length, 1);
      expect(filtered2025.first.id, 6);
    });

    test('Filter by "Custom" restricts strictly to selected DateTimeRange', () {
      final customRange = DateTimeRange(
        start: DateTime(2026, 9, 10),
        end: DateTime(2026, 9, 20),
      );

      final filtered = filterTransactions(
        data: testItems,
        filter: "Custom",
        selectedYear: 2026,
        selectedMonth: 9,
        selectedCustomRange: customRange,
      );

      expect(filtered.length, 2);
      expect(filtered.map((e) => e.id), containsAll([2, 3]));
    });
  });
}
