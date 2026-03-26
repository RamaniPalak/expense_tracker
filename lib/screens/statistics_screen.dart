import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/text_styles.dart';
import '../widgets/statistics_helper.dart';
import '../utils/report_generator.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import '../models/expense_model.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoaded = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });
  }

  Future<void> _loadUserAndData() async {
    final email = await AuthService().getUserEmail();
    if (mounted) {
      setState(() {
        _userEmail = email;
      });
      DatabaseHelper.instance.refreshExpenses(_userEmail);
    }
  }

  String selectedTransactionType = "Expense";
  final List<String> transactionTypes = ["Income", "Expense"];

  String selectedTimeFilter = "Week";
  final List<String> timeFilters = ["Week", "Month", "Year"];

  int selectedYear = DateTime.now().year;
  final List<int> availableYears = [2024, 2025, 2026];

  int selectedSpendingIndex = 0;

  List<FlSpot> _getZeroSpots(List<FlSpot> originalSpots) {
    return originalSpots.map((spot) => FlSpot(spot.x, 0)).toList();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      // Expense
      case "Netflix":
        return Icons.movie;
      case "Food":
        return Icons.fastfood;
      case "Transport":
        return Icons.directions_car;
      case "Shopping":
        return Icons.shopping_bag;
      // Income
      case "Salary":
        return Icons.attach_money;
      case "Upwork":
        return Icons.work;
      case "Interest":
        return Icons.account_balance;
      case "Freelance":
        return Icons.computer;
      default:
        return Icons.category;
    }
  }

  List<String> _getXAxisTitles(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case "Week":
        // Return 4 weeks: W-3, W-2, W-1, Current
        return ["W1", "W2", "W3", "W4"];
      case "Month":
        return [
          "Jan",
          "Feb",
          "Mar",
          "Apr",
          "May",
          "Jun",
          "Jul",
          "Aug",
          "Sep",
          "Oct",
          "Nov",
          "Dec"
        ];
      case "Year":
        return List.generate(5, (i) => (now.year - (4 - i)).toString());
      default:
        return [];
    }
  }

  List<Expense> _getFilteredByTime(List<Expense> data, String filter) {
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

  List<FlSpot> _getChartSpots(List<Expense> data, String filter) {
    final nowFull = DateTime.now();
    final now = DateTime(nowFull.year, nowFull.month, nowFull.day);
    final aggregated = <int, double>{};

    switch (filter) {
      case "Week":
        // Last 4 weeks
        for (var i = 0; i < 4; i++) {
          aggregated[i] = 0;
        }
        for (var e in data) {
          final eDate = DateTime(e.date.year, e.date.month, e.date.day);
          final diff = now.difference(eDate).inDays;
          if (diff >= 0 && diff < 28) {
            final weekIdx = 3 - (diff ~/ 7);
            aggregated[weekIdx] = (aggregated[weekIdx] ?? 0) + e.amount;
          }
        }
        break;
      case "Month":
        // Fixed Jan-Dec for selectedYear
        for (var i = 0; i < 12; i++) {
          aggregated[i] = 0;
        }
        for (var e in data) {
          if (e.date.year == selectedYear) {
            final monthIdx = e.date.month - 1; // 0-indexed
            aggregated[monthIdx] = (aggregated[monthIdx] ?? 0) + e.amount;
          }
        }
        break;
      case "Year":
        // Last 5 years
        for (var i = 0; i < 5; i++) {
          aggregated[i] = 0;
        }
        for (var e in data) {
          final yearDiff = now.year - e.date.year;
          if (yearDiff >= 0 && yearDiff < 5) {
            aggregated[4 - yearDiff] =
                (aggregated[4 - yearDiff] ?? 0) + e.amount;
          }
        }
        break;
    }

    final sortedKeys = aggregated.keys.toList()..sort();
    return sortedKeys.map((k) => FlSpot(k.toDouble(), aggregated[k]!)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ValueListenableBuilder<List<Expense>>(
          valueListenable: DatabaseHelper.instance.expensesNotifier,
          builder: (context, allExpenses, _) {
            // Filter expenses based on selected type (Income/Expense)
            final isIncomeMode = selectedTransactionType == "Income";
            final typeFilteredData =
                allExpenses.where((e) => e.isIncome == isIncomeMode).toList();

            // Further filter by selected time period
            final filteredData =
                _getFilteredByTime(typeFilteredData, selectedTimeFilter);

            // Prepare Top Spending (Group by Category)
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

            // Prepare Chart Data
            final spots = _getChartSpots(filteredData, selectedTimeFilter);
            final xTitles = _getXAxisTitles(selectedTimeFilter);

            // Calculate Dynamic Y-axis Max
            double maxY = 0;
            for (var spot in spots) {
              if (spot.y > maxY) maxY = spot.y;
            }

            // Add padding (40%) and round to avoid cutoffs
            maxY = maxY > 0 ? (maxY * 1.4) : 1000;
            // Round maxY to a nice number
            if (maxY > 1000) {
              maxY = (maxY / 200).ceil() * 200.0;
            } else if (maxY > 0) {
              maxY = (maxY / 10).ceil() * 10.0; // More sensitive rounding
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header
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
                  ),

                  const SizedBox(height: 20),

                  // Time Filters
                  StatisticsHelper.buildTimeFilters(
                    filters: timeFilters,
                    selectedFilter: selectedTimeFilter,
                    onSelect: (filter) =>
                        setState(() => selectedTimeFilter = filter),
                  ),

                  const SizedBox(height: 20),

                  // Filters Row (Type and Year)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (selectedTimeFilter == "Month") ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.greyLight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: selectedYear,
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    color: AppColors.textPrimary),
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textPrimary),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    selectedYear = newValue!;
                                  });
                                },
                                items: availableYears
                                    .map<DropdownMenuItem<int>>((int value) {
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text(value.toString()),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
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

                  // Fixed Y-Axis and Scrollable Chart
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 280, // Increased height for titles and padding
                      child: Row(
                        children: [
                          // Fixed Y-Axis Labels
                          Container(
                            width: 50,
                            padding: const EdgeInsets.only(bottom: 38, top: 10),
                            child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  final value = maxY - (index * (maxY / 5));
                                  return Text(
                                    value >= 1000
                                        ? '${(value / 1000).toStringAsFixed(1)}k'
                                        : value.toInt().toString(),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  );
                                }).toList()),
                          ),
                          // Scrollable Chart area
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                width: selectedTimeFilter == "Month"
                                    ? MediaQuery.of(context).size.width * 1.8
                                    : MediaQuery.of(context).size.width - 66,
                                padding: const EdgeInsets.only(
                                    top: 20, bottom: 8, right: 16),
                                child: LineChart(
                                  LineChartData(
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots
                                              .map((LineBarSpot touchedSpot) {
                                            return LineTooltipItem(
                                              '₹ ${touchedSpot.y.toStringAsFixed(2)}',
                                              TextStyle(
                                                color: isIncomeMode
                                                    ? AppColors.incomeGreen
                                                    : AppColors.secondary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                    minY: 0,
                                    maxY: maxY,
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      horizontalInterval: maxY / 5,
                                      getDrawingHorizontalLine: (value) =>
                                          FlLine(
                                        color: AppColors.greyLight
                                            .withValues(alpha: 0.1),
                                        strokeWidth: 1,
                                      ),
                                      getDrawingVerticalLine: (value) => FlLine(
                                        color: AppColors.greyLight
                                            .withValues(alpha: 0.1),
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >= 0 &&
                                                value.toInt() <
                                                    xTitles.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: Text(
                                                  xTitles[value.toInt()],
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                          reservedSize: 30,
                                          interval: 1,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        bottom: BorderSide(
                                            color: AppColors.greyLight,
                                            width: 1),
                                        left: BorderSide(
                                            color: AppColors.greyLight,
                                            width: 1),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _isLoaded
                                            ? spots
                                            : _getZeroSpots(spots),
                                        isCurved: true,
                                        color: isIncomeMode
                                            ? AppColors.incomeGreen
                                            : AppColors.secondary,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              (isIncomeMode
                                                      ? AppColors.incomeGreen
                                                      : AppColors.secondary)
                                                  .withValues(alpha: 0.2),
                                              (isIncomeMode
                                                      ? AppColors.incomeGreen
                                                      : AppColors.secondary)
                                                  .withValues(alpha: 0.0),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Top Spending Header
                  StatisticsHelper.buildSpendingHeader(),

                  const SizedBox(height: 16),

                  // Spend List (Selectable)
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
                                onTap: () => setState(
                                    () => selectedSpendingIndex = index),
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
        ),
      ),
    );
  }
}
