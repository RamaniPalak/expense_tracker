import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/features/wallet/data/models/monthly_budget_model.dart';

/// Test class reproducing the memoized aggregation engine used in StatisticsScreen.
class StatisticsMemoizer {
  int selectedMonth = 9;
  int selectedYear = 2026;
  String selectedTimeFilter = "Month";
  DateTimeRange? selectedCustomRange;

  int budgetCalculationsCount = 0;
  int spentCalculationsCount = 0;
  int balanceCalculationsCount = 0;
  int insightCalculationsCount = 0;
  int spendingListCalculationsCount = 0;

  // Caches
  List<MonthlyBudgetModel>? _cachedMonthlyBudgetsRef;
  List<BudgetModel>? _cachedCategoryBudgetsRef;
  int? _cachedBudgetMonth;
  int? _cachedBudgetYear;
  MonthlyBudgetModel? _cachedTotalBudget;

  List<TransactionModel>? _cachedBalanceExpensesRef;
  double? _cachedWalletBalance;

  List<TransactionModel>? _cachedSpentExpensesRef;
  int? _cachedSpentMonth;
  int? _cachedSpentYear;
  double? _cachedTotalSpent;

  List<TransactionModel>? _cachedInsightExpensesRef;
  int? _cachedInsightMonth;
  int? _cachedInsightYear;
  Map<String, dynamic>? _cachedBenchmarkInsight;

  List<TransactionModel>? _cachedSpendingExpensesRef;
  bool? _cachedSpendingIsIncome;
  String? _cachedSpendingTimeFilter;
  int? _cachedSpendingMonth;
  int? _cachedSpendingYear;
  DateTimeRange? _cachedSpendingCustomRange;
  List<Map<String, dynamic>>? _cachedTopSpendingList;
  double? _cachedTotalInFilter;

  MonthlyBudgetModel calculateTotalBudget(
    List<MonthlyBudgetModel> allMonthlyBudgets,
    List<BudgetModel> allCategoryBudgets,
  ) {
    if (_cachedTotalBudget != null &&
        identical(allMonthlyBudgets, _cachedMonthlyBudgetsRef) &&
        identical(allCategoryBudgets, _cachedCategoryBudgetsRef) &&
        _cachedBudgetMonth == selectedMonth &&
        _cachedBudgetYear == selectedYear) {
      return _cachedTotalBudget!;
    }

    budgetCalculationsCount++;
    final exact = allMonthlyBudgets.firstWhere(
      (b) => b.month == selectedMonth && b.year == selectedYear && b.amount > 0,
      orElse: () =>
          const MonthlyBudgetModel(amount: 0, month: 0, year: 0, userEmail: ''),
    );

    _cachedMonthlyBudgetsRef = allMonthlyBudgets;
    _cachedCategoryBudgetsRef = allCategoryBudgets;
    _cachedBudgetMonth = selectedMonth;
    _cachedBudgetYear = selectedYear;
    _cachedTotalBudget = exact;

    return exact;
  }

  double calculateTotalSpent(List<TransactionModel> allExpenses) {
    if (_cachedTotalSpent != null &&
        identical(allExpenses, _cachedSpentExpensesRef) &&
        _cachedSpentMonth == selectedMonth &&
        _cachedSpentYear == selectedYear) {
      return _cachedTotalSpent!;
    }

    spentCalculationsCount++;
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

    balanceCalculationsCount++;
    final result = allExpenses.fold(0.0, (sum, item) {
      return item.isIncome ? sum + item.amount : sum - item.amount;
    });

    _cachedBalanceExpensesRef = allExpenses;
    _cachedWalletBalance = result;

    return result;
  }

  Map<String, dynamic> getBenchmarkInsight(List<TransactionModel> allExpenses) {
    if (_cachedBenchmarkInsight != null &&
        identical(allExpenses, _cachedInsightExpensesRef) &&
        _cachedInsightMonth == selectedMonth &&
        _cachedInsightYear == selectedYear) {
      return _cachedBenchmarkInsight!;
    }

    insightCalculationsCount++;
    final currentTotal = allExpenses
        .where((e) =>
            !e.isIncome &&
            e.date.month == selectedMonth &&
            e.date.year == selectedYear)
        .fold(0.0, (sum, e) => sum + e.amount);

    final result = {
      "current": currentTotal,
      "previous": 0.0,
      "difference": 0.0,
      "isIncrease": false,
    };

    _cachedInsightExpensesRef = allExpenses;
    _cachedInsightMonth = selectedMonth;
    _cachedInsightYear = selectedYear;
    _cachedBenchmarkInsight = result;

    return result;
  }

  List<Map<String, dynamic>> prepareTopSpendingList(
    List<TransactionModel> allExpenses,
    bool isIncomeMode,
  ) {
    final rangeEquals = (selectedCustomRange == null &&
            _cachedSpendingCustomRange == null) ||
        (selectedCustomRange != null &&
            _cachedSpendingCustomRange != null &&
            selectedCustomRange!.start == _cachedSpendingCustomRange!.start &&
            selectedCustomRange!.end == _cachedSpendingCustomRange!.end);

    if (_cachedTopSpendingList != null &&
        identical(allExpenses, _cachedSpendingExpensesRef) &&
        _cachedSpendingIsIncome == isIncomeMode &&
        _cachedSpendingTimeFilter == selectedTimeFilter &&
        _cachedSpendingMonth == selectedMonth &&
        _cachedSpendingYear == selectedYear &&
        rangeEquals) {
      return _cachedTopSpendingList!;
    }

    spendingListCalculationsCount++;
    final filtered = allExpenses
        .where((e) =>
            e.isIncome == isIncomeMode &&
            e.date.month == selectedMonth &&
            e.date.year == selectedYear)
        .toList();

    final categoryMap = <String, Map<String, dynamic>>{};
    for (var e in filtered) {
      categoryMap[e.category] = {
        "title": e.category,
        "amount": (categoryMap[e.category]?['amount'] ?? 0.0) + e.amount,
      };
    }

    final list = categoryMap.values.toList();
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

  double get cachedTotalInFilter => _cachedTotalInFilter ?? 0.0;
}

void main() {
  group('Statistics Aggregation Memoization Tests', () {
    late StatisticsMemoizer memoizer;
    late List<TransactionModel> sampleExpenses;
    late List<BudgetModel> sampleBudgets;
    late List<MonthlyBudgetModel> sampleMonthlyBudgets;

    setUp(() {
      memoizer = StatisticsMemoizer();
      sampleExpenses = [
        TransactionModel(
          id: 1,
          title: 'Grocery',
          amount: 500,
          isIncome: false,
          date: DateTime(2026, 9, 15),
          category: 'Food',
          userEmail: 'user@test.com',
        ),
        TransactionModel(
          id: 2,
          title: 'Salary',
          amount: 50000,
          isIncome: true,
          date: DateTime(2026, 9, 1),
          category: 'Salary',
          userEmail: 'user@test.com',
        ),
      ];
      sampleBudgets = [
        const BudgetModel(
          id: 1,
          category: 'Total',
          amount: 25000,
          month: 9,
          year: 2026,
          userEmail: 'user@test.com',
        ),
      ];
      sampleMonthlyBudgets = [
        const MonthlyBudgetModel(
          id: 1,
          amount: 25000,
          month: 9,
          year: 2026,
          userEmail: 'user@test.com',
        ),
      ];
    });

    test('Initial computation runs exactly once and caches result', () {
      final budget1 =
          memoizer.calculateTotalBudget(sampleMonthlyBudgets, sampleBudgets);
      expect(budget1.amount, 25000);
      expect(memoizer.budgetCalculationsCount, 1);

      final spent1 = memoizer.calculateTotalSpent(sampleExpenses);
      expect(spent1, 500);
      expect(memoizer.spentCalculationsCount, 1);

      final balance1 = memoizer.calculateWalletBalance(sampleExpenses);
      expect(balance1, 49500);
      expect(memoizer.balanceCalculationsCount, 1);

      final insight1 = memoizer.getBenchmarkInsight(sampleExpenses);
      expect(insight1['current'], 500);
      expect(memoizer.insightCalculationsCount, 1);

      final list1 = memoizer.prepareTopSpendingList(sampleExpenses, false);
      expect(list1.length, 1);
      expect(memoizer.spendingListCalculationsCount, 1);
      expect(memoizer.cachedTotalInFilter, 500);

      // Re-invoking with identical references (e.g. on slice touch or rebuild) hits cache
      final budget2 =
          memoizer.calculateTotalBudget(sampleMonthlyBudgets, sampleBudgets);
      expect(identical(budget1, budget2), isTrue);
      expect(memoizer.budgetCalculationsCount, 1); // Not incremented!

      final spent2 = memoizer.calculateTotalSpent(sampleExpenses);
      expect(spent2, 500);
      expect(memoizer.spentCalculationsCount, 1); // Not incremented!

      final balance2 = memoizer.calculateWalletBalance(sampleExpenses);
      expect(balance2, 49500);
      expect(memoizer.balanceCalculationsCount, 1); // Not incremented!

      final insight2 = memoizer.getBenchmarkInsight(sampleExpenses);
      expect(identical(insight1, insight2), isTrue);
      expect(memoizer.insightCalculationsCount, 1); // Not incremented!

      final list2 = memoizer.prepareTopSpendingList(sampleExpenses, false);
      expect(identical(list1, list2), isTrue);
      expect(memoizer.spendingListCalculationsCount, 1); // Not incremented!
    });

    test('Cache invalidates when selectedMonth or selectedYear changes', () {
      memoizer.calculateTotalBudget(sampleMonthlyBudgets, sampleBudgets);
      memoizer.calculateTotalSpent(sampleExpenses);
      expect(memoizer.budgetCalculationsCount, 1);
      expect(memoizer.spentCalculationsCount, 1);

      // Change month to August
      memoizer.selectedMonth = 8;

      memoizer.calculateTotalBudget(sampleMonthlyBudgets, sampleBudgets);
      memoizer.calculateTotalSpent(sampleExpenses);
      expect(memoizer.budgetCalculationsCount, 2);
      expect(memoizer.spentCalculationsCount, 2);
    });

    test('Cache invalidates when transaction list reference changes', () {
      memoizer.calculateTotalSpent(sampleExpenses);
      memoizer.calculateWalletBalance(sampleExpenses);
      expect(memoizer.spentCalculationsCount, 1);
      expect(memoizer.balanceCalculationsCount, 1);

      // New transaction list instance (e.g., from DB refresh)
      final newExpenses = List<TransactionModel>.from(sampleExpenses)
        ..add(
          TransactionModel(
            id: 3,
            title: 'Coffee',
            amount: 150,
            isIncome: false,
            date: DateTime(2026, 9, 16),
            category: 'Food',
            userEmail: 'user@test.com',
          ),
        );

      final newSpent = memoizer.calculateTotalSpent(newExpenses);
      expect(newSpent, 650);
      expect(memoizer.spentCalculationsCount, 2);

      final newBalance = memoizer.calculateWalletBalance(newExpenses);
      expect(newBalance, 49350);
      expect(memoizer.balanceCalculationsCount, 2);
    });

    test('Top spending list cache invalidates on income/expense mode toggle',
        () {
      final expenseList =
          memoizer.prepareTopSpendingList(sampleExpenses, false);
      expect(expenseList.first['title'], 'Food');
      expect(memoizer.spendingListCalculationsCount, 1);

      // Switch to income mode
      final incomeList = memoizer.prepareTopSpendingList(sampleExpenses, true);
      expect(incomeList.first['title'], 'Salary');
      expect(memoizer.spendingListCalculationsCount, 2);
    });

    test('Top spending list cache invalidates when time filter changes', () {
      memoizer.prepareTopSpendingList(sampleExpenses, false);
      expect(memoizer.spendingListCalculationsCount, 1);

      // Change filter from "Month" to "Week"
      memoizer.selectedTimeFilter = "Week";
      memoizer.prepareTopSpendingList(sampleExpenses, false);
      expect(memoizer.spendingListCalculationsCount, 2);
    });
  });
}
