import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_helper.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_pie_chart.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_spending_list.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_breakdown_button.dart';
import 'package:expense_tracker/core/common_widgets/budget_dialog.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/features/wallet/data/models/monthly_budget_model.dart';
import 'package:expense_tracker/core/utils/report_generator.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  String? _userEmail;
  late TabController _tabController;
  late PageController _carouselController;
  int _carouselPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _carouselController = PageController();
    _loadUserAndData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndData() async {
    final email = await sl<IAuthRepository>().getUserEmail();
    if (mounted) {
      setState(() {
        _userEmail = email;
      });
      sl<DatabaseHelper>().refreshExpenses(_userEmail, syncFromRemote: true);
      sl<DatabaseHelper>().refreshBudgets(_userEmail, syncFromRemote: true);
      sl<DatabaseHelper>()
          .refreshMonthlyBudgets(_userEmail, syncFromRemote: true);
      sl<DatabaseHelper>().refreshBills(_userEmail);
    }
  }

  String selectedTransactionType = AppStrings.expenses;
  final List<String> transactionTypes = [
    AppStrings.income,
    AppStrings.expenses
  ];

  String selectedTimeFilter = "Month";
  final List<String> timeFilters = [
    "Week",
    "Month",
    "Quarter",
    "Year",
    "Custom"
  ];
  DateTimeRange? selectedCustomRange;

  Future<void> _handleTimeFilterSelected(String filter) async {
    if (filter == "Custom") {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDateRange: selectedCustomRange ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      );
      if (picked != null) {
        setState(() {
          selectedCustomRange = picked;
          selectedTimeFilter = "Custom";
        });
      }
    } else {
      setState(() {
        selectedTimeFilter = filter;
      });
    }
  }

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  /// Generates a rolling window: 3 years back → 1 year ahead.
  /// e.g. in 2026 → [2023, 2024, 2025, 2026, 2027]
  List<int> get availableYears {
    final now = DateTime.now().year;
    return List.generate(5, (i) => now - 3 + i);
  }

  void _changeMonth(int offset) {
    setState(() {
      selectedMonth += offset;
      if (selectedMonth > 12) {
        selectedMonth = 1;
        selectedYear++;
      } else if (selectedMonth < 1) {
        selectedMonth = 12;
        selectedYear--;
      }
    });
  }

  Map<String, dynamic> _getBenchmarkInsight(
      List<TransactionModel> allExpenses) {
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

  int touchedIndex = -1;
  int selectedSpendingIndex = -1;

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

  MonthlyBudgetModel _calculateTotalBudget(
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

    final result = _computeTotalBudget(allMonthlyBudgets, allCategoryBudgets);

    _cachedMonthlyBudgetsRef = allMonthlyBudgets;
    _cachedCategoryBudgetsRef = allCategoryBudgets;
    _cachedBudgetMonth = selectedMonth;
    _cachedBudgetYear = selectedYear;
    _cachedTotalBudget = result;

    return result;
  }

  MonthlyBudgetModel _computeTotalBudget(
    List<MonthlyBudgetModel> allMonthlyBudgets,
    List<BudgetModel> allCategoryBudgets,
  ) {
    // 1. Direct lookup in dedicated monthly_budgets table
    final exactMonthly = allMonthlyBudgets.firstWhere(
      (b) => b.month == selectedMonth && b.year == selectedYear && b.amount > 0,
      orElse: () => const MonthlyBudgetModel(
          amount: -1, month: 0, year: 0, userEmail: ''),
    );
    if (exactMonthly.amount > 0) return exactMonthly;

    // 2. Direct lookup in budgets table with category == AppStrings.total
    final exactTotalCategory = allCategoryBudgets.firstWhere(
      (b) =>
          b.category.trim().toLowerCase() == AppStrings.total.toLowerCase() &&
          b.month == selectedMonth &&
          b.year == selectedYear &&
          b.amount > 0,
      orElse: () => const BudgetModel(
          category: '', amount: -1, month: 0, year: 0, userEmail: ''),
    );
    if (exactTotalCategory.amount > 0) {
      return MonthlyBudgetModel(
        id: exactTotalCategory.id,
        remoteId: exactTotalCategory.remoteId,
        amount: exactTotalCategory.amount,
        month: selectedMonth,
        year: selectedYear,
        userEmail: exactTotalCategory.userEmail,
      );
    }

    // 3. Sum of all individual category budgets for selected month/year
    final sumCategoryBudgets = allCategoryBudgets
        .where((b) =>
            b.category.trim().toLowerCase() != AppStrings.total.toLowerCase() &&
            b.month == selectedMonth &&
            b.year == selectedYear &&
            b.amount > 0)
        .fold(0.0, (sum, b) => sum + b.amount);

    if (sumCategoryBudgets > 0) {
      return MonthlyBudgetModel(
        amount: sumCategoryBudgets,
        month: selectedMonth,
        year: selectedYear,
        userEmail: _userEmail ?? '',
      );
    }

    // 4. Carry-Forward Fallback: Search backwards up to 24 months across all sources
    int checkYear = selectedYear;
    int checkMonth = selectedMonth;

    for (int i = 0; i < 24; i++) {
      checkMonth--;
      if (checkMonth < 1) {
        checkMonth = 12;
        checkYear--;
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
          userEmail: _userEmail ?? '',
        );
      }
    }

    return MonthlyBudgetModel(
      amount: 0,
      month: selectedMonth,
      year: selectedYear,
      userEmail: _userEmail ?? '',
    );
  }

  double _calculateTotalSpent(List<TransactionModel> allExpenses) {
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

  double _calculateWalletBalance(List<TransactionModel> allExpenses) {
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

  List<Map<String, dynamic>> _prepareTopSpendingList(
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

    final typeFilteredData =
        allExpenses.where((e) => e.isIncome == isIncomeMode).toList();
    final filteredData =
        _getFilteredByTime(typeFilteredData, selectedTimeFilter);

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

  List<PieChartSectionData> _buildPieSections(
    List<Map<String, dynamic>> topSpendingList,
    double totalInFilter,
    bool isIncomeMode,
  ) {
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

  List<TransactionModel> _getFilteredByTime(
      List<TransactionModel> data, String filter) {
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
            selectedCustomRange!.start.year,
            selectedCustomRange!.start.month,
            selectedCustomRange!.start.day,
          );
          final end = DateTime(
            selectedCustomRange!.end.year,
            selectedCustomRange!.end.month,
            selectedCustomRange!.end.day,
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

  Widget _buildPeriodSummaryCard({
    required BuildContext context,
    required String period,
    required double totalAmount,
    required bool isIncomeMode,
    required int transactionCount,
  }) {
    String periodTitle;
    switch (period) {
      case "Week":
        periodTitle = "Last 7 Days";
        break;
      case "Quarter":
        final q = ((selectedMonth - 1) ~/ 3) + 1;
        periodTitle = "Quarter $q, $selectedYear";
        break;
      case "Year":
        periodTitle = "Year $selectedYear";
        break;
      case "Custom":
        if (selectedCustomRange != null) {
          periodTitle =
              "${DateFormat('MMM d, y').format(selectedCustomRange!.start)} - ${DateFormat('MMM d, y').format(selectedCustomRange!.end)}";
        } else {
          periodTitle = "Custom Range";
        }
        break;
      default:
        periodTitle = period;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                periodTitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "₹ ${totalAmount.toStringAsFixed(2)}",
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "$transactionCount ${isIncomeMode ? 'income entries' : 'expenses'}",
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncomeMode
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nowTime = DateTime.now();
    final isCurrentMonth =
        selectedYear == nowTime.year && selectedMonth == nowTime.month;
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Tab Bar Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 14, 0),
              child: Row(
                children: [
                  Text(
                    AppStrings.statistics,
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 20,
                      color: c.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_tabController.index == 0) ...[
                    IconButton(
                      icon: Icon(
                        Icons.download_outlined,
                        color: c.textPrimary,
                        size: 24,
                      ),
                      onPressed: () {
                        final isIncomeMode =
                            selectedTransactionType == AppStrings.income;
                        final allExpenses =
                            sl<DatabaseHelper>().expensesNotifier.value;
                        final typeFilteredList =
                            _prepareTopSpendingList(allExpenses, isIncomeMode);
                        String reportPeriod = selectedTimeFilter;
                        if (selectedTimeFilter == "Custom" &&
                            selectedCustomRange != null) {
                          reportPeriod =
                              "${DateFormat('dd/MM/yy').format(selectedCustomRange!.start)} - ${DateFormat('dd/MM/yy').format(selectedCustomRange!.end)}";
                        } else if (selectedTimeFilter == "Month") {
                          reportPeriod = DateFormat('MMMM yyyy')
                              .format(DateTime(selectedYear, selectedMonth));
                        }
                        ReportGenerator.generateStatisticsReport(
                          type: selectedTransactionType,
                          period: reportPeriod,
                          spendingData: typeFilteredList
                              .map((e) => {
                                    ...e,
                                    "amount":
                                        "${isIncomeMode ? '+' : '-'} ₹ ${e['amount'].toStringAsFixed(2)}",
                                    "date": DateFormat('MMM dd, yyyy')
                                        .format(e['latestDate'] as DateTime),
                                  })
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: c.tabBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: c.textSecondary,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: "Analytics"),
                  Tab(text: "Bills"),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // ── Tab Views ───────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 1: Analytics ────────────────────────────
                  ValueListenableBuilder<List<TransactionModel>>(
                    valueListenable: sl<DatabaseHelper>().expensesNotifier,
                    builder: (context, allExpenses, _) {
                      return ValueListenableBuilder<List<BudgetModel>>(
                        valueListenable: sl<DatabaseHelper>().budgetsNotifier,
                        builder: (context, allBudgets, _) {
                          final isIncomeMode =
                              selectedTransactionType == AppStrings.income;

                          return ValueListenableBuilder<
                              List<MonthlyBudgetModel>>(
                            valueListenable:
                                sl<DatabaseHelper>().monthlyBudgetsNotifier,
                            builder: (context, allMonthlyBudgets, _) {
                              final totalBudgetObj = _calculateTotalBudget(
                                  allMonthlyBudgets, allBudgets);
                              final totalSpentResult =
                                  _calculateTotalSpent(allExpenses);
                              final walletBalance =
                                  _calculateWalletBalance(allExpenses);

                              final topSpendingList = _prepareTopSpendingList(
                                  allExpenses, isIncomeMode);
                              final double totalInFilter =
                                  _cachedTotalInFilter ??
                                      topSpendingList.fold<double>(
                                          0.0,
                                          (sum,
                                                  item) =>
                                              sum +
                                              (item['amount'] as num)
                                                  .toDouble());

                              final pieSections = _buildPieSections(
                                  topSpendingList, totalInFilter, isIncomeMode);

                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 6),
                                    StatisticsHelper.buildTimeFilters(
                                      filters: timeFilters,
                                      selectedFilter: selectedTimeFilter,
                                      onSelect: _handleTimeFilterSelected,
                                    ),
                                    if (selectedTimeFilter == "Custom" &&
                                        selectedCustomRange != null) ...[
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () =>
                                            _handleTimeFilterSelected("Custom"),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: AppColors.secondary
                                                    .withOpacity(0.4)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.calendar_today,
                                                  size: 12,
                                                  color: AppColors.secondary),
                                              const SizedBox(width: 6),
                                              Text(
                                                "${DateFormat('MMM d, y').format(selectedCustomRange!.start)} - ${DateFormat('MMM d, y').format(selectedCustomRange!.end)}",
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color: AppColors.secondary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.edit,
                                                  size: 11,
                                                  color: AppColors.secondary),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    if (selectedTimeFilter == "Month") ...[
                                      // ── Carousel: Budget ↔ Pie Chart ──
                                      Column(
                                        children: [
                                          SizedBox(
                                            height: 300,
                                            child: PageView(
                                              controller: _carouselController,
                                              onPageChanged: (i) =>
                                                  setState(() => _carouselPage = i),
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
                                                        totalBudget: totalBudgetObj.amount,
                                                        totalSpent: totalSpentResult,
                                                        monthYear: DateFormat('MMMM yyyy').format(
                                                            DateTime(selectedYear, selectedMonth)),
                                                        onPreviousMonth: () => _changeMonth(-1),
                                                        onNextMonth: () => _changeMonth(1),
                                                        showNextMonth: !isCurrentMonth,
                                                        availableBalance: walletBalance,
                                                        onSetBudget: () => _showBudgetDialog(
                                                            context, allMonthlyBudgets, allBudgets),
                                                      ),
                                                      if (!isIncomeMode) ...[
                                                        const SizedBox(height: 8),
                                                        Builder(builder: (context) {
                                                          final insight = _getBenchmarkInsight(allExpenses);
                                                          return StatisticsHelper.buildSpendingInsightCard(
                                                            context: context,
                                                            currentTotal: insight['current'],
                                                            previousTotal: insight['previous'],
                                                            difference: insight['difference'],
                                                            isIncrease: insight['isIncrease'],
                                                          );
                                                        }),
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
                                                              isIncomeMode ? "Income Breakdown" : "Expense Breakdown",
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
                                                              onChanged: (String? newValue) {
                                                                if (newValue != null) {
                                                                  setState(() {
                                                                    selectedTransactionType = newValue;
                                                                  });
                                                                }
                                                              },
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
                                                        onSelectionChanged: (index) {
                                                          setState(() {
                                                            touchedIndex = index;
                                                            selectedSpendingIndex = index;
                                                          });
                                                        },
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
                                              final isActive = _carouselPage == i;
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
                                      ),
                                    ] else ...[
                                      // Non-month filters: period summary + pie side by side
                                      _buildPeriodSummaryCard(
                                        context: context,
                                        period: selectedTimeFilter,
                                        totalAmount: totalInFilter,
                                        isIncomeMode: isIncomeMode,
                                        transactionCount: topSpendingList.length,
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              isIncomeMode ? "Income Breakdown" : "Expense Breakdown",
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
                                              onChanged: (String? newValue) {
                                                if (newValue != null) {
                                                  setState(() {
                                                    selectedTransactionType = newValue;
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      StatisticsPieChart(
                                        pieSections: pieSections,
                                        topSpendingList: topSpendingList,
                                        totalInFilter: totalInFilter,
                                        touchedIndex: touchedIndex,
                                        selectedTransactionType: selectedTransactionType,
                                        onSelectionChanged: (index) {
                                          setState(() {
                                            touchedIndex = index;
                                            selectedSpendingIndex = index;
                                          });
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    StatisticsHelper.buildSpendingHeader(context: context),
                                    const SizedBox(height: 8),
                                    StatisticsSpendingList(
                                      topSpendingList: topSpendingList,
                                      isIncomeMode: isIncomeMode,
                                      selectedSpendingIndex: selectedSpendingIndex,
                                      onItemTapped: (index) {
                                        setState(() {
                                          selectedSpendingIndex = index;
                                          touchedIndex = index;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    StatisticsBreakdownButton(
                                      isIncomeMode: isIncomeMode,
                                      onTap: () => context.push(
                                        RoutePaths.categoryBreakdown,
                                        extra: isIncomeMode,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),

                  // ── Tab 2: Upcoming Bills ────────────────────────
                  _UpcomingBillsTab(userEmail: _userEmail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBudgetDialog(
      BuildContext context,
      List<MonthlyBudgetModel> allMonthlyBudgets,
      List<BudgetModel> allCategoryBudgets) async {
    final existingMonthly = allMonthlyBudgets
        .where((b) => b.month == selectedMonth && b.year == selectedYear)
        .firstOrNull;

    final existingTotalCat = allCategoryBudgets
        .where((b) =>
            b.category.trim().toLowerCase() == AppStrings.total.toLowerCase() &&
            b.month == selectedMonth &&
            b.year == selectedYear)
        .firstOrNull;

    final BudgetModel? existingBudget = existingMonthly != null
        ? BudgetModel(
            id: existingMonthly.id,
            remoteId: existingMonthly.remoteId,
            category: AppStrings.total,
            amount: existingMonthly.amount,
            month: existingMonthly.month,
            year: existingMonthly.year,
            userEmail: existingMonthly.userEmail,
          )
        : existingTotalCat;

    await showDialog(
      context: context,
      builder: (ctx) => BudgetDialog(
        userEmail: _userEmail,
        month: selectedMonth,
        year: selectedYear,
        category: AppStrings.total,
        initialBudget: existingBudget,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Upcoming Bills Tab Widget
// ══════════════════════════════════════════════════════════════════════════════
class _UpcomingBillsTab extends StatelessWidget {
  final String? userEmail;

  const _UpcomingBillsTab({this.userEmail});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return ValueListenableBuilder<List<BillModel>>(
      valueListenable: sl<DatabaseHelper>().billsNotifier,
      builder: (context, bills, _) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final upcoming = bills.where((b) => !b.isPaid).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        final paid = bills.where((b) => b.isPaid).toList()
          ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

        final overdueCount = upcoming
            .where((b) =>
                DateTime(b.dueDate.year, b.dueDate.month, b.dueDate.day)
                    .isBefore(today))
            .length;

        final totalDue = upcoming.fold(0.0, (sum, b) => sum + b.amount);

        return Column(
          children: [
            // Summary card
            if (upcoming.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: overdueCount > 0
                      ? const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (overdueCount > 0
                              ? const Color(0xFFE53935)
                              : AppColors.secondary)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${upcoming.length} Upcoming Bill${upcoming.length == 1 ? '' : 's'}",
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            "₹ ${totalDue.toStringAsFixed(0)}",
                            style: AppTextStyles.heading1
                                .copyWith(color: Colors.white, fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                    if (overdueCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "$overdueCount Overdue",
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Bills list
            Expanded(
              child: upcoming.isEmpty && paid.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.green.withOpacity(0.6)),
                          const SizedBox(height: 16),
                          Text("All caught up!",
                              style: AppTextStyles.heading2
                                  .copyWith(color: c.textPrimary)),
                          const SizedBox(height: 8),
                          Text("No upcoming bills",
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: c.textSecondary)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push(RoutePaths.bills),
                            icon: const Icon(Icons.add),
                            label: const Text("Add Bill"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        if (upcoming.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                              child: Text(
                                "Upcoming Payments",
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: c.textSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildBillCard(
                                    context, upcoming[index], today, false);
                              },
                              childCount: upcoming.length,
                            ),
                          ),
                        ],
                        if (paid.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                              child: Text(
                                "Recently Paid",
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: c.textSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildBillCard(
                                    context, paid[index], today, true);
                              },
                              childCount: paid.length,
                            ),
                          ),
                        ],
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                            child: OutlinedButton.icon(
                              onPressed: () => context.push(RoutePaths.bills),
                              icon: const Icon(Icons.receipt_long),
                              label: const Text("Manage All Bills"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side:
                                    const BorderSide(color: AppColors.primary),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBillCard(
      BuildContext context, BillModel bill, DateTime today, bool isPaid) {
    final c = context.appColors;
    final dueDay =
        DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day);
    final diff = dueDay.difference(today).inDays;
    final isOverdue = !isPaid && diff < 0;
    final isUrgent = !isPaid && diff <= 3;

    Color statusColor = isPaid
        ? Colors.green
        : isOverdue
            ? Colors.red
            : isUrgent
                ? Colors.orange
                : AppColors.primary;

    String dueLabel = isPaid
        ? "Paid"
        : isOverdue
            ? "Overdue by ${diff.abs()} day${diff.abs() == 1 ? '' : 's'}"
            : diff == 0
                ? "Due today"
                : "Due in $diff day${diff == 1 ? '' : 's'}";

    return GestureDetector(
      onTap: () => context.push(RoutePaths.billDetail, extra: bill),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: isOverdue
              ? Border.all(color: Colors.red.withOpacity(0.4))
              : isUrgent
                  ? Border.all(color: Colors.orange.withOpacity(0.4))
                  : null,
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPaid
                    ? Icons.check_circle
                    : isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.calendar_today,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(isPaid ? Icons.check : Icons.schedule,
                          size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        dueLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: isOverdue || isUrgent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(bill.dueDate),
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 11, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹ ${bill.amount.toStringAsFixed(0)}",
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                    fontSize: 16,
                  ),
                ),
                if (bill.isRecurring)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat, size: 11, color: c.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        "Monthly",
                        style: AppTextStyles.bodySmall
                            .copyWith(fontSize: 11, color: c.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
