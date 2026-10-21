import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_helper.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/features/wallet/data/models/monthly_budget_model.dart';

/// Memoization and statistical aggregation engine for the Statistics screen.
class StatisticsDataEngine {
  // ── Memoization Caches ──────────────────────────────────────────────
  // 1. Budget memoization
  List<MonthlyBudgetModel>? _cachedMonthlyBudgetsRef;
  List<BudgetModel>? _cachedCategoryBudgetsRef;
  int? _cachedBudgetMonth;
  int? _cachedBudgetYear;
  MonthlyBudgetModel? _cachedTotalBudget;

  // 2. Wallet balance memoization
  List<TransactionModel>? _cachedBalanceExpensesRef;
  double? _cachedWalletBalance;

  // 3. Month spent memoization
  List<TransactionModel>? _cachedSpentExpensesRef;
  int? _cachedSpentMonth;
  int? _cachedSpentYear;
  double? _cachedTotalSpent;

  // 4. Benchmark insight memoization
  List<TransactionModel>? _cachedInsightExpensesRef;
  int? _cachedInsightMonth;
  int? _cachedInsightYear;
  Map<String, dynamic>? _cachedBenchmarkInsight;

  // 5. Top spending list & filter total memoization
  List<TransactionModel>? _cachedSpendingExpensesRef;
  bool? _cachedSpendingIsIncome;
  String? _cachedSpendingTimeFilter;
  int? _cachedSpendingMonth;
  int? _cachedSpendingYear;
  DateTimeRange? _cachedSpendingCustomRange;
  List<Map<String, dynamic>>? _cachedTopSpendingList;
  double? _cachedTotalInFilter;

  double? get cachedTotalInFilter => _cachedTotalInFilter;

  MonthlyBudgetModel calculateTotalBudget({
    required List<MonthlyBudgetModel> allMonthlyBudgets,
    required List<BudgetModel> allCategoryBudgets,
    required int selectedMonth,
    required int selectedYear,
    required String? userEmail,
  }) {
    if (_cachedTotalBudget != null &&
        identical(allMonthlyBudgets, _cachedMonthlyBudgetsRef) &&
        identical(allCategoryBudgets, _cachedCategoryBudgetsRef) &&
        _cachedBudgetMonth == selectedMonth &&
        _cachedBudgetYear == selectedYear) {
      return _cachedTotalBudget!;
    }

    final result = _computeTotalBudget(
      allMonthlyBudgets: allMonthlyBudgets,
      allCategoryBudgets: allCategoryBudgets,
      selectedMonth: selectedMonth,
      selectedYear: selectedYear,
      userEmail: userEmail,
    );

    _cachedMonthlyBudgetsRef = allMonthlyBudgets;
    _cachedCategoryBudgetsRef = allCategoryBudgets;
    _cachedBudgetMonth = selectedMonth;
    _cachedBudgetYear = selectedYear;
    _cachedTotalBudget = result;

    return result;
  }

  MonthlyBudgetModel _computeTotalBudget({
    required List<MonthlyBudgetModel> allMonthlyBudgets,
    required List<BudgetModel> allCategoryBudgets,
    required int selectedMonth,
    required int selectedYear,
    required String? userEmail,
  }) {
    // 1. Direct lookup in dedicated monthly_budgets table
    final exactMonthly = allMonthlyBudgets.firstWhere(
      (b) => b.month == selectedMonth && b.year == selectedYear && b.amount > 0,
      orElse: () => const MonthlyBudgetModel(
          amount: -1, month: 0, year: 0, userEmail: ''),
    );
    if (exactMonthly.amount > 0) return exactMonthly;

    // 2. Fallback: dedicated 'Total' category in standard budgets table
    final totalCatBudget = allCategoryBudgets.firstWhere(
      (b) =>
          b.category.trim().toLowerCase() == AppStrings.total.toLowerCase() &&
          b.month == selectedMonth &&
          b.year == selectedYear &&
          b.amount > 0,
      orElse: () => const BudgetModel(
          category: '', amount: -1, month: 0, year: 0, userEmail: ''),
    );
    if (totalCatBudget.amount > 0) {
      return MonthlyBudgetModel(
        id: totalCatBudget.id,
        remoteId: totalCatBudget.remoteId,
        amount: totalCatBudget.amount,
        month: selectedMonth,
        year: selectedYear,
        userEmail: totalCatBudget.userEmail,
      );
    }

    // 3. Fallback: Sum of individual category budgets
    final sumOfCategories = allCategoryBudgets
        .where((b) =>
            b.category.trim().toLowerCase() != AppStrings.total.toLowerCase() &&
            b.month == selectedMonth &&
            b.year == selectedYear &&
            b.amount > 0)
        .fold(0.0, (sum, b) => sum + b.amount);

    if (sumOfCategories > 0) {
      return MonthlyBudgetModel(
        amount: sumOfCategories,
        month: selectedMonth,
        year: selectedYear,
        userEmail: userEmail ?? '',
      );
    }

    // 4. Fallback: Check past months (most recent budget carryover)
    for (int i = 1; i <= 12; i++) {
      var checkMonth = selectedMonth - i;
      var checkYear = selectedYear;
      while (checkMonth <= 0) {
        checkMonth += 12;
        checkYear -= 1;
      }

      final prevMonthly = allMonthlyBudgets.firstWhere(
        (b) => b.month == checkMonth && b.year == checkYear && b.amount > 0,
        orElse: () => const MonthlyBudgetModel(
            amount: -1, month: 0, year: 0, userEmail: ''),
      );
      if (prevMonthly.amount > 0) {
        return prevMonthly.copyWith(month: selectedMonth, year: selectedYear);
      }

      final prevTotalCat = allCategoryBudgets.firstWhere(
        (b) =>
            b.category.trim().toLowerCase() == AppStrings.total.toLowerCase() &&
            b.month == checkMonth &&
            b.year == checkYear &&
            b.amount > 0,
        orElse: () => const BudgetModel(
            category: '', amount: -1, month: 0, year: 0, userEmail: ''),
      );
      if (prevTotalCat.amount > 0) {
        return MonthlyBudgetModel(
          id: prevTotalCat.id,
          remoteId: prevTotalCat.remoteId,
          amount: prevTotalCat.amount,
          month: selectedMonth,
          year: selectedYear,
          userEmail: prevTotalCat.userEmail,
        );
      }

      final prevSum = allCategoryBudgets
          .where((b) =>
              b.category.trim().toLowerCase() !=
                  AppStrings.total.toLowerCase() &&
              b.month == checkMonth &&
              b.year == checkYear &&
              b.amount > 0)
          .fold(0.0, (sum, b) => sum + b.amount);

      if (prevSum > 0) {
        return MonthlyBudgetModel(
          amount: prevSum,
          month: selectedMonth,
          year: selectedYear,
          userEmail: userEmail ?? '',
        );
      }
    }

    return MonthlyBudgetModel(
      amount: 0,
      month: selectedMonth,
      year: selectedYear,
      userEmail: userEmail ?? '',
    );
  }

  double calculateTotalSpent({
    required List<TransactionModel> allExpenses,
    required int selectedMonth,
    required int selectedYear,
  }) {
    if (_cachedTotalSpent != null &&
        identical(allExpenses, _cachedSpentExpensesRef) &&
        _cachedSpentMonth == selectedMonth &&
        _cachedSpentYear == selectedYear) {
      return _cachedTotalSpent!;
    }

    final result = allExpenses
        .where((e) =>
            !e.isIncome &&
            e.date.month == selectedMonth &&
            e.date.year == selectedYear)
        .fold(0.0, (sum, e) => sum + e.amount);

    _cachedSpentExpensesRef = allExpenses;
    _cachedSpentMonth = selectedMonth;
    _cachedSpentYear = selectedYear;
    _cachedTotalSpent = result;

    return result;
  }

  double calculateWalletBalance(List<TransactionModel> allExpenses) {
    if (_cachedWalletBalance != null &&
        identical(allExpenses, _cachedBalanceExpensesRef)) {
      return _cachedWalletBalance!;
    }

    final result = allExpenses.fold(0.0, (sum, item) {
      return item.isIncome ? sum + item.amount : sum - item.amount;
    });

    _cachedBalanceExpensesRef = allExpenses;
    _cachedWalletBalance = result;

    return result;
  }

  Map<String, dynamic> getBenchmarkInsight({
    required List<TransactionModel> allExpenses,
    required int selectedMonth,
    required int selectedYear,
  }) {
    if (_cachedBenchmarkInsight != null &&
        identical(allExpenses, _cachedInsightExpensesRef) &&
        _cachedInsightMonth == selectedMonth &&
        _cachedInsightYear == selectedYear) {
      return _cachedBenchmarkInsight!;
    }

    final prevMonthDate = DateTime(selectedYear, selectedMonth - 1);
    final prevMonth = prevMonthDate.month;
    final prevYear = prevMonthDate.year;

    final currentTotal = allExpenses
        .where((e) =>
            !e.isIncome &&
            e.date.month == selectedMonth &&
            e.date.year == selectedYear)
        .fold(0.0, (sum, e) => sum + e.amount);

    final previousTotal = allExpenses
        .where((e) =>
            !e.isIncome && e.date.month == prevMonth && e.date.year == prevYear)
        .fold(0.0, (sum, e) => sum + e.amount);

    double diff = 0;
    if (previousTotal > 0) {
      diff = ((currentTotal - previousTotal) / previousTotal) * 100;
    }

    final result = {
      "current": currentTotal,
      "previous": previousTotal,
      "difference": diff,
      "isIncrease": currentTotal > previousTotal,
    };

    _cachedInsightExpensesRef = allExpenses;
    _cachedInsightMonth = selectedMonth;
    _cachedInsightYear = selectedYear;
    _cachedBenchmarkInsight = result;

    return result;
  }

  List<Map<String, dynamic>> prepareTopSpendingList({
    required List<TransactionModel> allExpenses,
    required bool isIncomeMode,
    required String selectedTimeFilter,
    required int selectedMonth,
    required int selectedYear,
    required DateTimeRange? selectedCustomRange,
  }) {
    final rangeEquals = (selectedCustomRange == null &&
            _cachedSpendingCustomRange == null) ||
        (selectedCustomRange != null &&
            _cachedSpendingCustomRange != null &&
            selectedCustomRange.start == _cachedSpendingCustomRange!.start &&
            selectedCustomRange.end == _cachedSpendingCustomRange!.end);

    if (_cachedTopSpendingList != null &&
        identical(allExpenses, _cachedSpendingExpensesRef) &&
        _cachedSpendingIsIncome == isIncomeMode &&
        _cachedSpendingTimeFilter == selectedTimeFilter &&
        _cachedSpendingMonth == selectedMonth &&
        _cachedSpendingYear == selectedYear &&
        rangeEquals) {
      return _cachedTopSpendingList!;
    }

    final typeFilteredData =
        allExpenses.where((e) => e.isIncome == isIncomeMode).toList();
    final filteredData = getFilteredByTime(
      data: typeFilteredData,
      filter: selectedTimeFilter,
      selectedYear: selectedYear,
      selectedMonth: selectedMonth,
      selectedCustomRange: selectedCustomRange,
    );

    final categoryMap = <String, Map<String, dynamic>>{};
    for (var e in filteredData) {
      if (categoryMap.containsKey(e.category)) {
        categoryMap[e.category]!['amount'] += e.amount;
        if (e.date.isAfter(categoryMap[e.category]!['latestDate'])) {
          categoryMap[e.category]!['latestDate'] = e.date;
        }
      } else {
        categoryMap[e.category] = {
          "title": e.category,
          "amount": e.amount,
          "latestDate": e.date,
          "icon": StatisticsHelper.getCategoryIcon(e.category,
              isIncome: isIncomeMode),
        };
      }
    }

    final list = categoryMap.values.toList();
    list.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    _cachedSpendingExpensesRef = allExpenses;
    _cachedSpendingIsIncome = isIncomeMode;
    _cachedSpendingTimeFilter = selectedTimeFilter;
    _cachedSpendingMonth = selectedMonth;
    _cachedSpendingYear = selectedYear;
    _cachedSpendingCustomRange = selectedCustomRange;
    _cachedTopSpendingList = list;
    _cachedTotalInFilter = list.fold<double>(
        0.0, (sum, item) => sum + (item['amount'] as num).toDouble());

    return list;
  }

  List<PieChartSectionData> buildPieSections({
    required List<Map<String, dynamic>> topSpendingList,
    required double totalInFilter,
    required bool isIncomeMode,
    required int touchedIndex,
  }) {
    List<PieChartSectionData> sections = [];
    for (var i = 0; i < topSpendingList.length; i++) {
      final item = topSpendingList[i];
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 22.0 : 16.0;

      sections.add(
        PieChartSectionData(
          color: StatisticsHelper.getCategoryColor(item['title'] as String,
              isIncome: isIncomeMode),
          value: item['amount'] as double,
          title: '',
          radius: radius,
        ),
      );
    }
    return sections;
  }

  List<TransactionModel> getFilteredByTime({
    required List<TransactionModel> data,
    required String filter,
    required int selectedYear,
    required int selectedMonth,
    required DateTimeRange? selectedCustomRange,
  }) {
    final nowFull = DateTime.now();
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
          return e.date.year == selectedYear && itemQuarter == selectedQuarter;
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
}
