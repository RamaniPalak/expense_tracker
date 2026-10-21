import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:expense_tracker/core/common_widgets/budget_dialog.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/utils/report_generator.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_breakdown_button.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_carousel.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_data_engine.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_helper.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_period_summary_card.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_pie_chart.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_spending_list.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/features/wallet/data/models/monthly_budget_model.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/services/database_helper.dart';

/// Analytics Tab containing time filters, budget carousel/period summary,
/// pie chart breakdown, and spending list.
class StatisticsAnalyticsTab extends StatefulWidget {
  final String? userEmail;

  const StatisticsAnalyticsTab({
    super.key,
    required this.userEmail,
  });

  @override
  State<StatisticsAnalyticsTab> createState() => StatisticsAnalyticsTabState();
}

class StatisticsAnalyticsTabState extends State<StatisticsAnalyticsTab> {
  final StatisticsDataEngine _engine = StatisticsDataEngine();
  late PageController _carouselController;
  int _carouselPage = 0;

  String selectedTransactionType = AppStrings.expenses;
  final List<String> transactionTypes = [
    AppStrings.income,
    AppStrings.expenses,
  ];

  String selectedTimeFilter = "Month";
  final List<String> timeFilters = [
    "Week",
    "Month",
    "Quarter",
    "Year",
    "Custom",
  ];
  DateTimeRange? selectedCustomRange;

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  int touchedIndex = -1;
  int selectedSpendingIndex = -1;

  @override
  void initState() {
    super.initState();
    _carouselController = PageController();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  /// Generates and shares a PDF/CSV statistics report for the current filter view.
  void exportReport() {
    final isIncomeMode = selectedTransactionType == AppStrings.income;
    final allExpenses = sl<DatabaseHelper>().expensesNotifier.value;
    final typeFilteredList = _engine.prepareTopSpendingList(
      allExpenses: allExpenses,
      isIncomeMode: isIncomeMode,
      selectedTimeFilter: selectedTimeFilter,
      selectedMonth: selectedMonth,
      selectedYear: selectedYear,
      selectedCustomRange: selectedCustomRange,
    );
    String reportPeriod = selectedTimeFilter;
    if (selectedTimeFilter == "Custom" && selectedCustomRange != null) {
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
                    "${isIncomeMode ? '+' : '-'} ₹ ${(e['amount'] as num).toDouble().toStringAsFixed(2)}",
                "date": DateFormat('MMM dd, yyyy')
                    .format(e['latestDate'] as DateTime),
              })
          .toList(),
    );
  }

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

  Future<void> _showBudgetDialog(
    BuildContext context,
    List<MonthlyBudgetModel> allMonthlyBudgets,
    List<BudgetModel> allCategoryBudgets,
  ) async {
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
        userEmail: widget.userEmail,
        month: selectedMonth,
        year: selectedYear,
        category: AppStrings.total,
        initialBudget: existingBudget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nowTime = DateTime.now();
    final isCurrentMonth =
        selectedYear == nowTime.year && selectedMonth == nowTime.month;
    final c = context.appColors;

    return ValueListenableBuilder<List<TransactionModel>>(
      valueListenable: sl<DatabaseHelper>().expensesNotifier,
      builder: (context, allExpenses, _) {
        return ValueListenableBuilder<List<BudgetModel>>(
          valueListenable: sl<DatabaseHelper>().budgetsNotifier,
          builder: (context, allBudgets, _) {
            final isIncomeMode = selectedTransactionType == AppStrings.income;

            return ValueListenableBuilder<List<MonthlyBudgetModel>>(
              valueListenable: sl<DatabaseHelper>().monthlyBudgetsNotifier,
              builder: (context, allMonthlyBudgets, _) {
                final totalBudgetObj = _engine.calculateTotalBudget(
                  allMonthlyBudgets: allMonthlyBudgets,
                  allCategoryBudgets: allBudgets,
                  selectedMonth: selectedMonth,
                  selectedYear: selectedYear,
                  userEmail: widget.userEmail,
                );
                final totalSpentResult = _engine.calculateTotalSpent(
                  allExpenses: allExpenses,
                  selectedMonth: selectedMonth,
                  selectedYear: selectedYear,
                );
                final walletBalance =
                    _engine.calculateWalletBalance(allExpenses);

                final topSpendingList = _engine.prepareTopSpendingList(
                  allExpenses: allExpenses,
                  isIncomeMode: isIncomeMode,
                  selectedTimeFilter: selectedTimeFilter,
                  selectedMonth: selectedMonth,
                  selectedYear: selectedYear,
                  selectedCustomRange: selectedCustomRange,
                );
                final double totalInFilter = _engine.cachedTotalInFilter ??
                    topSpendingList.fold<double>(
                        0.0,
                        (sum, item) =>
                            sum + (item['amount'] as num).toDouble());

                final pieSections = _engine.buildPieSections(
                  topSpendingList: topSpendingList,
                  totalInFilter: totalInFilter,
                  isIncomeMode: isIncomeMode,
                  touchedIndex: touchedIndex,
                );

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
                          onTap: () => _handleTimeFilterSelected("Custom"),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.secondary.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 12, color: AppColors.secondary),
                                const SizedBox(width: 6),
                                Text(
                                  "${DateFormat('MMM d, y').format(selectedCustomRange!.start)} - ${DateFormat('MMM d, y').format(selectedCustomRange!.end)}",
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit,
                                    size: 11, color: AppColors.secondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // ── Content depending on Month vs Other Periods ──
                      if (selectedTimeFilter == "Month") ...[
                        StatisticsCarousel(
                          pageController: _carouselController,
                          carouselPage: _carouselPage,
                          onPageChanged: (i) =>
                              setState(() => _carouselPage = i),
                          totalBudget: totalBudgetObj.amount,
                          totalSpent: totalSpentResult,
                          walletBalance: walletBalance,
                          monthYear: DateFormat('MMMM yyyy')
                              .format(DateTime(selectedYear, selectedMonth)),
                          onPreviousMonth: () => _changeMonth(-1),
                          onNextMonth: () => _changeMonth(1),
                          showNextMonth: !isCurrentMonth,
                          onSetBudget: () => _showBudgetDialog(
                              context, allMonthlyBudgets, allBudgets),
                          isIncomeMode: isIncomeMode,
                          insight: _engine.getBenchmarkInsight(
                            allExpenses: allExpenses,
                            selectedMonth: selectedMonth,
                            selectedYear: selectedYear,
                          ),
                          selectedTransactionType: selectedTransactionType,
                          transactionTypes: transactionTypes,
                          onTypeChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedTransactionType = newValue;
                              });
                            }
                          },
                          pieSections: pieSections,
                          topSpendingList: topSpendingList,
                          totalInFilter: totalInFilter,
                          touchedIndex: touchedIndex,
                          onPieSelectionChanged: (index) {
                            setState(() {
                              touchedIndex = index;
                              selectedSpendingIndex = index;
                            });
                          },
                        ),
                      ] else ...[
                        // Non-month filters: period summary + pie
                        StatisticsPeriodSummaryCard(
                          period: selectedTimeFilter,
                          totalAmount: totalInFilter,
                          isIncomeMode: isIncomeMode,
                          transactionCount: topSpendingList.length,
                          selectedYear: selectedYear,
                          selectedMonth: selectedMonth,
                          selectedCustomRange: selectedCustomRange,
                        ),
                        const SizedBox(height: 8),
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
    );
  }
}
