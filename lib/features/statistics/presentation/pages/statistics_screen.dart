import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_helper.dart';
import 'package:expense_tracker/core/common_widgets/budget_dialog.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/core/utils/report_generator.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

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
  final List<String> transactionTypes = [AppStrings.income, AppStrings.expenses];

  String selectedTimeFilter = "Month";
  final List<String> timeFilters = ["Month"];

  int selectedYear = DateTime.now().year;
  final List<int> availableYears = [2024, 2025, 2026];

  int touchedIndex = -1;
  int selectedSpendingIndex = -1;

  Color _getCategoryColor(String category) {
    switch (category) {
      case AppStrings.catNetflix:
        return const Color(0xFFEF5350); // Soft Vibrant Red
      case AppStrings.catFood:
        return const Color(0xFF66BB6A); // Soft Vibrant Green
      case AppStrings.catTransport:
        return const Color(0xFF42A5F5); // Soft Vibrant Blue
      case AppStrings.catShopping:
        return const Color(0xFFFFA726); // Soft Vibrant Orange
      case AppStrings.catSalary:
        return const Color(0xFF26A69A); // Soft Vibrant Teal
      case AppStrings.catUpwork:
        return const Color(0xFF9CCC65); // Soft Vibrant Lime
      case AppStrings.catInterest:
        return const Color(0xFF26C6DA); // Soft Vibrant Cyan
      case AppStrings.catFreelance:
        return const Color(0xFFAB47BC); // Soft Vibrant Purple
      case AppStrings.catOther:
        return const Color(0xFF90A4AE); // Blue Grey
      default:
        return AppColors.primary.withAlpha(127);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      // Expense
      case AppStrings.catNetflix:
        return Icons.movie;
      case AppStrings.catFood:
        return Icons.fastfood;
      case AppStrings.catTransport:
        return Icons.directions_car;
      case AppStrings.catShopping:
        return Icons.shopping_bag;
      // Income
      case AppStrings.catSalary:
        return Icons.attach_money;
      case AppStrings.catUpwork:
        return Icons.work;
      case AppStrings.catInterest:
        return Icons.account_balance;
      case AppStrings.catFreelance:
        return Icons.computer;
      case AppStrings.catOther:
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
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
          return e.date.year == selectedYear;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ValueListenableBuilder<List<TransactionModel>>(
          valueListenable: sl<DatabaseHelper>().expensesNotifier,
          builder: (context, allExpenses, _) {
            return ValueListenableBuilder<List<BudgetModel>>(
              valueListenable: sl<DatabaseHelper>().budgetsNotifier,
              builder: (context, allBudgets, _) {
                final isIncomeMode = selectedTransactionType == AppStrings.income;
                final typeFilteredData =
                    allExpenses.where((e) => e.isIncome == isIncomeMode).toList();

                final now = DateTime.now();
                
                final totalBudgetObj = allBudgets.firstWhere(
                  (b) => b.category == AppStrings.total,
                  orElse: () => BudgetModel(
                    category: AppStrings.total,
                    amount: 0,
                    month: now.month,
                    year: now.year,
                    userEmail: _userEmail ?? '',
                  ),
                );
                
                final totalSpentResult = allExpenses
                    .where((e) => !e.isIncome && e.date.month == now.month && e.date.year == now.year)
                    .fold(0.0, (sum, e) => sum + e.amount);

                final walletBalance = allExpenses.fold(0.0, (sum, item) {
                  return item.isIncome ? sum + item.amount : sum - item.amount;
                });

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
                      "icon": _getCategoryIcon(e.category),
                    };
                  }
                }

                final topSpendingList = categoryMap.values.toList();
                topSpendingList.sort((a, b) =>
                    (b['amount'] as double).compareTo(a['amount'] as double));

                final totalInFilter = topSpendingList.fold(0.0, (sum, item) => sum + item['amount']);

                List<PieChartSectionData> pieSections = [];
                for (var i = 0; i < topSpendingList.length; i++) {
                  final item = topSpendingList[i];
                  final isTouched = i == touchedIndex;
                  final fontSize = isTouched ? 16.0 : 0.0;
                  final radius = isTouched ? 50.0 : 40.0;
                  final widgetSize = isTouched ? 35.0 : 30.0;

                  pieSections.add(
                    PieChartSectionData(
                      color: _getCategoryColor(item['title'] as String),
                      value: item['amount'] as double,
                      title: '${((item['amount'] as double) / totalInFilter * 100).toStringAsFixed(0)}%',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      badgeWidget: _Badge(
                        item['icon'] as IconData,
                        size: widgetSize,
                        borderColor: _getCategoryColor(item['title'] as String),
                      ),
                      badgePositionPercentageOffset: .98,
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      StatisticsHelper.buildHeader(
                        onDownload: () {
                          ReportGenerator.generateStatisticsReport(
                            type: selectedTransactionType,
                            period: selectedTimeFilter,
                            spendingData: topSpendingList
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
                        onAdjustBudget: () async {
                          await showDialog(
                            context: context,
                            builder: (ctx) => BudgetDialog(userEmail: _userEmail),
                          );
                        },
                      ),

                      if (!isIncomeMode && selectedTimeFilter == "Month") ...[
                        const SizedBox(height: 10),
                        StatisticsHelper.buildMonthlyBudgetCard(
                          context: context,
                          totalBudget: totalBudgetObj.amount,
                          totalSpent: totalSpentResult,
                          availableBalance: walletBalance,
                          onSetBudget: () async {
                            await showDialog(
                              context: context,
                              builder: (ctx) => BudgetDialog(userEmail: _userEmail),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            StatisticsHelper.buildTypeDropdown(
                              selectedType: selectedTransactionType,
                              types: transactionTypes,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedTransactionType = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 200,
                          child: Stack(
                            children: [
                              PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          touchedIndex = -1;
                                          selectedSpendingIndex = -1;
                                          return;
                                        }
                                        touchedIndex = pieTouchResponse
                                            .touchedSection!.touchedSectionIndex;
                                        selectedSpendingIndex = touchedIndex;
                                      });
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
                                      touchedIndex == -1 ? AppStrings.total : topSpendingList[touchedIndex]['title'],
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      touchedIndex == -1 
                                        ? "₹ ${totalInFilter.toStringAsFixed(0)}"
                                        : "₹ ${topSpendingList[touchedIndex]['amount'].toStringAsFixed(0)}",
                                      style: AppTextStyles.heading1.copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      StatisticsHelper.buildSpendingHeader(),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: topSpendingList.isEmpty
                            ? const Center(
                                child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text("No data for this period"),
                              ))
                            : Column(
                                children:
                                    List.generate(topSpendingList.length, (index) {
                                  final item = topSpendingList[index];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedSpendingIndex = index;
                                        touchedIndex = index;
                                      });
                                    },
                                    child: Column(
                                      children: [
                                        StatisticsHelper.buildSpendingItem(
                                          icon: item['icon'],
                                          title: item['title'],
                                          date: DateFormat('MMM dd, yyyy')
                                              .format(item['latestDate']),
                                          amount:
                                              "${isIncomeMode ? '+' : '-'} ₹ ${item['amount'].toStringAsFixed(2)}",
                                          isHighlighted:
                                              index == selectedSpendingIndex,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  );
                                }),
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
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.icon, {
    required this.size,
    required this.borderColor,
  });
  final IconData icon;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(127),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Icon(
          icon,
          size: size * .5,
          color: borderColor,
        ),
      ),
    );
  }
}
