import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_helper.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_badge.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_pie_chart.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_spending_list.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_breakdown_button.dart';
import 'package:expense_tracker/core/common_widgets/budget_dialog.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/core/utils/report_generator.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final email = await sl<IAuthRepository>().getUserEmail();
    if (mounted) {
      setState(() {
        _userEmail = email;
      });
      sl<DatabaseHelper>().refreshExpenses(_userEmail);
      sl<DatabaseHelper>().refreshBudgets(_userEmail);
    }
  }

  String selectedTransactionType = AppStrings.expenses;
  final List<String> transactionTypes = [
    AppStrings.income,
    AppStrings.expenses
  ];

  String selectedTimeFilter = "Month";
  final List<String> timeFilters = ["Month"];

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  final List<int> availableYears = [2024, 2025, 2026];

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

    return {
      "current": currentTotal,
      "previous": previousTotal,
      "difference": diff,
      "isIncrease": currentTotal > previousTotal,
    };
  }

  int touchedIndex = -1;
  int selectedSpendingIndex = -1;

  BudgetModel _calculateTotalBudget(List<BudgetModel> allBudgets) {
    return allBudgets.firstWhere(
      (b) =>
          b.category == AppStrings.total &&
          b.month == selectedMonth &&
          b.year == selectedYear,
      orElse: () => BudgetModel(
        category: AppStrings.total,
        amount: 0,
        month: selectedMonth,
        year: selectedYear,
        userEmail: _userEmail ?? '',
      ),
    );
  }

  double _calculateTotalSpent(List<TransactionModel> allExpenses) {
    return allExpenses
        .where((e) =>
            !e.isIncome &&
            e.date.month == selectedMonth &&
            e.date.year == selectedYear)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double _calculateWalletBalance(List<TransactionModel> allExpenses) {
    return allExpenses.fold(0.0, (sum, item) {
      return item.isIncome ? sum + item.amount : sum - item.amount;
    });
  }

  List<Map<String, dynamic>> _prepareTopSpendingList(
    List<TransactionModel> typeFilteredData,
    bool isIncomeMode,
  ) {
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
      final fontSize = isTouched ? 16.0 : 0.0;
      final radius = isTouched ? 50.0 : 40.0;
      final widgetSize = isTouched ? 35.0 : 30.0;

      sections.add(
        PieChartSectionData(
          color: StatisticsHelper.getCategoryColor(item['title'] as String,
              isIncome: isIncomeMode),
          value: item['amount'] as double,
          title:
              '${((item['amount'] as double) / totalInFilter * 100).toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: StatisticsBadge(
            item['icon'] as IconData,
            size: widgetSize,
            borderColor: StatisticsHelper.getCategoryColor(
                item['title'] as String,
                isIncome: isIncomeMode),
          ),
          badgePositionPercentageOffset: .98,
        ),
      );
    }
    return sections;
  }

  List<TransactionModel> _getFilteredByTime(
      List<TransactionModel> data, String filter) {
    final nowFull = DateTime.now();
    final now = DateTime(nowFull.year, nowFull.month, nowFull.day);

    return data.where((e) {
      final eDate = DateTime(e.date.year, e.date.month, e.date.day);
      switch (filter) {
        case "Week":
          final diff = now.difference(eDate).inDays;
          return diff >= 0 && diff < 28;
        case "Month":
          return e.date.year == selectedYear && e.date.month == selectedMonth;
        case "Year":
          final diff = now.year - e.date.year;
          return diff >= 0 && diff < 5;
        default:
          return true;
      }
    }).toList();
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
        child: ValueListenableBuilder<List<TransactionModel>>(
          valueListenable: sl<DatabaseHelper>().expensesNotifier,
          builder: (context, allExpenses, _) {
            return ValueListenableBuilder<List<BudgetModel>>(
              valueListenable: sl<DatabaseHelper>().budgetsNotifier,
              builder: (context, allBudgets, _) {
                final isIncomeMode =
                    selectedTransactionType == AppStrings.income;
                final typeFilteredData = allExpenses
                    .where((e) => e.isIncome == isIncomeMode)
                    .toList();

                final totalBudgetObj = _calculateTotalBudget(allBudgets);
                final totalSpentResult = _calculateTotalSpent(allExpenses);
                final walletBalance = _calculateWalletBalance(allExpenses);

                final topSpendingList =
                    _prepareTopSpendingList(typeFilteredData, isIncomeMode);
                final totalInFilter = topSpendingList.fold(
                    0.0, (sum, item) => sum + item['amount']);

                final pieSections = _buildPieSections(
                    topSpendingList, totalInFilter, isIncomeMode);

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      StatisticsHelper.buildHeader(
                        context: context,
                        onDownload: () {
                          final typeFilteredList = _prepareTopSpendingList(
                              typeFilteredData, isIncomeMode);
                          ReportGenerator.generateStatisticsReport(
                            type: selectedTransactionType,
                            period: selectedTimeFilter,
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
                        onAdjustBudget: () =>
                            _showBudgetDialog(context, allBudgets),
                      ),
                      if (selectedTimeFilter == "Month") ...[
                        const SizedBox(height: 10),
                        StatisticsHelper.buildMonthlyBudgetCard(
                          context: context,
                          totalBudget: totalBudgetObj.amount,
                          totalSpent: totalSpentResult,
                          monthYear: DateFormat('MMMM yyyy')
                              .format(DateTime(selectedYear, selectedMonth)),
                          onPreviousMonth: () => _changeMonth(-1),
                          onNextMonth: () => _changeMonth(1),
                          showNextMonth: !isCurrentMonth,
                          availableBalance: walletBalance,
                          onSetBudget: () =>
                              _showBudgetDialog(context, allBudgets),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (!isIncomeMode && selectedTimeFilter == "Month") ...[
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
                        const SizedBox(height: 20),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 30),
                      StatisticsHelper.buildSpendingHeader(context: context),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      StatisticsBreakdownButton(
                        isIncomeMode: isIncomeMode,
                        onTap: () => context.push(
                          RoutePaths.categoryBreakdown,
                          extra: isIncomeMode,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showBudgetDialog(
      BuildContext context, List<BudgetModel> allBudgets) async {
    final existingBudget = allBudgets
        .where((b) =>
            b.category == AppStrings.total &&
            b.month == selectedMonth &&
            b.year == selectedYear)
        .firstOrNull;

    await showDialog(
      context: context,
      builder: (ctx) => BudgetDialog(
        userEmail: _userEmail,
        month: selectedMonth,
        year: selectedYear,
        initialBudget: existingBudget,
      ),
    );
  }
}
