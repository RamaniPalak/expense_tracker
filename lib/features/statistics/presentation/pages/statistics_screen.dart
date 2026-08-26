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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadUserAndData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      sl<DatabaseHelper>().refreshMonthlyBudgets(_userEmail, syncFromRemote: true);
      sl<DatabaseHelper>().refreshBills(_userEmail);
    }
  }

  String selectedTransactionType = AppStrings.expenses;
  final List<String> transactionTypes = [AppStrings.income, AppStrings.expenses];

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

  Map<String, dynamic> _getBenchmarkInsight(List<TransactionModel> allExpenses) {
    final prevMonthDate = DateTime(selectedYear, selectedMonth - 1);
    final prevMonth = prevMonthDate.month;
    final prevYear = prevMonthDate.year;

    final currentTotal = allExpenses
        .where((e) =>
            !e.isIncome && e.date.month == selectedMonth && e.date.year == selectedYear)
        .fold(0.0, (sum, e) => sum + e.amount);

    final previousTotal = allExpenses
        .where((e) => !e.isIncome && e.date.month == prevMonth && e.date.year == prevYear)
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

  MonthlyBudgetModel _calculateTotalBudget(List<MonthlyBudgetModel> allMonthlyBudgets) {
    final exact = allMonthlyBudgets.firstWhere(
      (b) =>
          b.month == selectedMonth &&
          b.year == selectedYear &&
          b.amount > 0,
      orElse: () => const MonthlyBudgetModel(
        amount: -1,
        month: 0,
        year: 0,
        userEmail: '',
      ),
    );

    if (exact.amount >= 0) return exact;

    // Carry-forward fallback: Find the most recent previous month's total budget
    final previousBudgets = allMonthlyBudgets.where((b) {
      if (b.amount <= 0) return false;
      if (b.year < selectedYear) return true;
      if (b.year == selectedYear && b.month < selectedMonth) return true;
      return false;
    }).toList();

    if (previousBudgets.isNotEmpty) {
      previousBudgets.sort((a, b) {
        final aKey = a.year * 100 + a.month;
        final bKey = b.year * 100 + b.month;
        return bKey.compareTo(aKey);
      });
      return previousBudgets.first.copyWith(
        month: selectedMonth,
        year: selectedYear,
      );
    }

    return MonthlyBudgetModel(
      amount: 0,
      month: selectedMonth,
      year: selectedYear,
      userEmail: _userEmail ?? '',
    );
  }

  double _calculateTotalSpent(List<TransactionModel> allExpenses) {
    return allExpenses
        .where((e) =>
            !e.isIncome && e.date.month == selectedMonth && e.date.year == selectedYear)
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
    final filteredData = _getFilteredByTime(typeFilteredData, selectedTimeFilter);

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
          "icon": StatisticsHelper.getCategoryIcon(e.category, isIncome: isIncomeMode),
        };
      }
    }

    final list = categoryMap.values.toList();
    list.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
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
      final radius = isTouched ? 32.0 : 24.0;

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

  List<TransactionModel> _getFilteredByTime(List<TransactionModel> data, String filter) {
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
    final isCurrentMonth = selectedYear == nowTime.year && selectedMonth == nowTime.month;
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Tab Bar Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Text(
                    AppStrings.statistics,
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 22,
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
                        size: 26,
                      ),
                      onPressed: () {
                        final isIncomeMode = selectedTransactionType == AppStrings.income;
                        final allExpenses = sl<DatabaseHelper>().expensesNotifier.value;
                        final typeFilteredData =
                            allExpenses.where((e) => e.isIncome == isIncomeMode).toList();
                        final typeFilteredList =
                            _prepareTopSpendingList(typeFilteredData, isIncomeMode);
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
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.tabBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: c.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: "Analytics"),
                  Tab(text: "Bills"),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
                          final typeFilteredData = allExpenses
                              .where((e) => e.isIncome == isIncomeMode)
                              .toList();

                          return ValueListenableBuilder<List<MonthlyBudgetModel>>(
                            valueListenable: sl<DatabaseHelper>().monthlyBudgetsNotifier,
                            builder: (context, allMonthlyBudgets, _) {
                              final totalBudgetObj = _calculateTotalBudget(allMonthlyBudgets);
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
                                        _showBudgetDialog(context, allMonthlyBudgets),
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
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: ExpansionTile(
                                    title: const Text(
                                      "DB Debug Panel",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    children: [
                                      Text("Active Email: $_userEmail",
                                          style: TextStyle(
                                              color: c.textSecondary, fontSize: 12)),
                                      Text(
                                          "Current Month: $selectedMonth / $selectedYear",
                                          style: TextStyle(
                                              color: c.textSecondary, fontSize: 12)),
                                      const SizedBox(height: 8),
                                      FutureBuilder<List<BudgetModel>>(
                                        future:
                                            sl<DatabaseHelper>().getBudgets(_userEmail),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const Text("Loading...");
                                          }
                                          final list = snapshot.data!;
                                          if (list.isEmpty) {
                                            return const Text("No budgets stored",
                                                style: TextStyle(
                                                    fontSize: 12, color: Colors.amber));
                                          }
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: list
                                                .map((b) => Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                          vertical: 2.0),
                                                      child: Text(
                                                        "• ${b.category}: ₹${b.amount} (${b.month}/${b.year}) [id:${b.id}]",
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: c.textPrimary),
                                                      ),
                                                    ))
                                                .toList(),
                                          );
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
      BuildContext context, List<MonthlyBudgetModel> allMonthlyBudgets) async {
    final existingMonthly = allMonthlyBudgets
        .where((b) =>
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
        : null;

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
                DateTime(b.dueDate.year, b.dueDate.month, b.dueDate.day).isBefore(today))
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              style:
                                  AppTextStyles.heading2.copyWith(color: c.textPrimary)),
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
                                return _buildBillCard(context, paid[index], today, true);
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
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
    final dueDay = DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day);
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
                          fontWeight:
                              isOverdue || isUrgent ? FontWeight.bold : FontWeight.normal,
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
