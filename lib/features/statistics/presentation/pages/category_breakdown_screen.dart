import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/common_widgets/budget_dialog.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/statistics/presentation/widgets/statistics_helper.dart';

class CategoryBreakdownScreen extends StatefulWidget {
  /// Pass true for income mode, false for expense mode
  final bool isIncome;

  const CategoryBreakdownScreen({super.key, this.isIncome = false});

  @override
  State<CategoryBreakdownScreen> createState() =>
      _CategoryBreakdownScreenState();
}

class _CategoryBreakdownScreenState extends State<CategoryBreakdownScreen>
    with SingleTickerProviderStateMixin {
  late bool _isIncome;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late AnimationController _animController;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.isIncome;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = await sl<IAuthRepository>().getUserEmail();
    if (mounted) {
      setState(() {
        _userEmail = email;
      });
      sl<DatabaseHelper>().refreshBudgets(_userEmail, syncFromRemote: true);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth += offset;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
      _animController
        ..reset()
        ..forward();
    });
  }

  BudgetModel? _findMostRecentPreviousCategoryBudget(
      List<BudgetModel> allBudgets, String category) {
    final previous = allBudgets.where((b) {
      if (b.category.trim().toLowerCase() != category.trim().toLowerCase() || b.amount <= 0) return false;
      if (b.year < _selectedYear) return true;
      if (b.year == _selectedYear && b.month < _selectedMonth) return true;
      return false;
    }).toList();

    if (previous.isEmpty) return null;

    previous.sort((a, b) {
      final aKey = a.year * 100 + a.month;
      final bKey = b.year * 100 + b.month;
      return bKey.compareTo(aKey);
    });

    return previous.first.copyWith(month: _selectedMonth, year: _selectedYear);
  }

  List<Map<String, dynamic>> _buildCategoryList(
      List<TransactionModel> all, List<BudgetModel> allBudgets) {
    final filtered = all.where((e) =>
        e.isIncome == _isIncome &&
        e.date.month == _selectedMonth &&
        e.date.year == _selectedYear);

    final Map<String, double> catTotals = {};
    for (final e in filtered) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }

    if (!_isIncome) {
      for (final b in allBudgets) {
        if (b.category != AppStrings.total && b.amount > 0) {
          final isSameOrPreviousMonth = b.year < _selectedYear ||
              (b.year == _selectedYear && b.month <= _selectedMonth);
          if (isSameOrPreviousMonth) {
            catTotals.putIfAbsent(b.category, () => 0.0);
          }
        }
      }
    }

    final list = catTotals.entries
        .map((entry) => {'category': entry.key, 'amount': entry.value})
        .toList();
    list.sort((a, b) =>
        (b['amount'] as double).compareTo(a['amount'] as double));
    return list;
  }

  String _buildSummaryText(List<Map<String, dynamic>> list, double total) {
    if (list.isEmpty) return "No transactions this month.";
    final topNames = list.take(3).map((e) => e['category'] as String).join(', ');
    final sign = _isIncome ? '+' : '-';
    return "$topNames made up 100% of your total ${_isIncome ? 'income' : 'expense'} this month.\n"
        "$sign${NumberFormat('#,##0.00').format(total)} ₹";
  }

  Future<void> _showCategoryBudgetDialog(
      BuildContext context, String category, BudgetModel? existingBudget) async {
    await showDialog(
      context: context,
      builder: (ctx) => BudgetDialog(
        userEmail: _userEmail,
        month: _selectedMonth,
        year: _selectedYear,
        category: category,
        initialBudget: existingBudget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth));
    final isCurrentMonth = _selectedYear == DateTime.now().year &&
        _selectedMonth == DateTime.now().month;
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      body: ValueListenableBuilder<List<TransactionModel>>(
        valueListenable: sl<DatabaseHelper>().expensesNotifier,
        builder: (context, allTransactions, _) {
          return ValueListenableBuilder<List<BudgetModel>>(
            valueListenable: sl<DatabaseHelper>().budgetsNotifier,
            builder: (context, allBudgets, _) {
              final categoryList = _buildCategoryList(allTransactions, allBudgets);
              final total = categoryList.fold(
                  0.0, (sum, e) => sum + (e['amount'] as double));

              return Column(
                children: [
                  // ── Header ──────────────────────────────────────────────
                  _buildHeader(context, monthLabel, isCurrentMonth, categoryList, total),

                  // ── Category list ────────────────────────────────────────
                  Expanded(
                    child: categoryList.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                            itemCount: categoryList.length,
                            itemBuilder: (context, index) {
                              final item = categoryList[index];
                              final pct = total > 0
                                  ? (item['amount'] as double) / total
                                  : 0.0;
                              final delay = index * 0.08;

                              final catBudget = allBudgets.where((b) =>
                                  b.category.trim().toLowerCase() == (item['category'] as String).trim().toLowerCase() &&
                                  b.month == _selectedMonth &&
                                  b.year == _selectedYear).firstOrNull ??
                                  _findMostRecentPreviousCategoryBudget(allBudgets, item['category'] as String);

                              return _CategoryTile(
                                key: ValueKey('$_selectedMonth-$_selectedYear-${item['category']}'),
                                category: item['category'] as String,
                                amount: item['amount'] as double,
                                percentage: pct,
                                isIncome: _isIncome,
                                budget: catBudget,
                                color: StatisticsHelper.getCategoryColor(item['category'] as String, isIncome: _isIncome),
                                icon: StatisticsHelper.getCategoryIcon(item['category'] as String, isIncome: _isIncome),
                                parentController: _animController,
                                delay: delay.clamp(0.0, 0.8),
                                onTap: _isIncome
                                    ? null
                                    : () => _showCategoryBudgetDialog(
                                          context,
                                          item['category'] as String,
                                          catBudget,
                                        ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String monthLabel,
    bool isCurrentMonth,
    List<Map<String, dynamic>> categoryList,
    double total,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    _isIncome ? "Income Category" : "Expense Category",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  // Toggle expense / income
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isIncome = !_isIncome;
                        _animController
                          ..reset()
                          ..forward();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isIncome
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isIncome ? "Income" : "Expense",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Month navigator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavArrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _changeMonth(-1),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    monthLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _NavArrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: isCurrentMonth ? null : () => _changeMonth(1),
                    disabled: isCurrentMonth,
                  ),
                ],
              ),
            ),

            // Summary card
            if (categoryList.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _buildSummaryText(categoryList, total),
                      style: TextStyle(
                        color: Colors.white.withAlpha(210),
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isIncome ? "Total Income" : "Total Expense",
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "${_isIncome ? '+' : '-'}${NumberFormat('#,##0.00').format(total)} ₹",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final c = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isIncome
                ? Icons.trending_up_rounded
                : Icons.receipt_long_rounded,
            size: 64,
            color: c.textSecondary.withAlpha(80),
          ),
          const SizedBox(height: 16),
          Text(
            "No ${_isIncome ? 'income' : 'expense'} transactions\nfor this month.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Category Tile ──────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final String category;
  final double amount;
  final double percentage;
  final bool isIncome;
  final BudgetModel? budget;
  final Color color;
  final IconData icon;
  final AnimationController parentController;
  final double delay;
  final VoidCallback? onTap;

  const _CategoryTile({
    super.key,
    required this.category,
    required this.amount,
    required this.percentage,
    required this.isIncome,
    this.budget,
    required this.color,
    required this.icon,
    required this.parentController,
    required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final barAnimation = CurvedAnimation(
      parent: parentController,
      curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );

    final fadeAnimation = CurvedAnimation(
      parent: parentController,
      curve: Interval(delay, (delay + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOut),
    );

    final amountLabel =
        "${isIncome ? '+' : '-'}${NumberFormat('#,##0.00').format(amount)} ₹";

    // Budget calculations
    final hasBudget = budget != null;
    final budgetLimit = budget?.amount ?? 0.0;
    final remaining = budgetLimit - amount;

    final String subtitleLabel;
    final String rightSubLabel;
    final double progressPercent;

    if (hasBudget) {
      subtitleLabel = "₹${NumberFormat('#,##0').format(amount)} of ₹${NumberFormat('#,##0').format(budgetLimit)}";
      rightSubLabel = remaining >= 0
          ? "₹${NumberFormat('#,##0').format(remaining)} left"
          : "Over by ₹${NumberFormat('#,##0').format(remaining.abs())}";
      progressPercent = budgetLimit > 0 ? (amount / budgetLimit) : 0.0;
    } else {
      subtitleLabel = isIncome ? "" : "No budget set (tap to set)";
      rightSubLabel = "${(percentage * 100).toStringAsFixed(0)}% of total";
      progressPercent = percentage;
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: (hasBudget && remaining < 0 ? AppColors.expenseRed : color).withAlpha(15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: c.shadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: (hasBudget && remaining < 0 ? AppColors.expenseRed : color).withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: hasBudget && remaining < 0 ? AppColors.expenseRed : color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                category,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (!isIncome) ...[
                              const SizedBox(width: 6),
                              Icon(
                                hasBudget ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                                size: 14,
                                color: hasBudget ? AppColors.primary : c.textSecondary.withAlpha(150),
                              ),
                            ],
                          ],
                        ),
                        if (subtitleLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitleLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: hasBudget ? c.textSecondary : c.textSecondary.withAlpha(140),
                              fontSize: 12,
                              fontWeight: hasBudget ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amountLabel,
                        style: TextStyle(
                          color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rightSubLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: hasBudget && remaining < 0
                              ? AppColors.expenseRed
                              : (hasBudget ? AppColors.incomeGreen : c.textSecondary),
                          fontWeight: hasBudget ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Animated progress bar
              LayoutBuilder(builder: (context, constraints) {
                final Color progressColor;
                if (hasBudget) {
                  if (progressPercent > 1.0) {
                    progressColor = AppColors.expenseRed;
                  } else if (progressPercent > 0.8) {
                    progressColor = const Color(0xFFFF9F0A);
                  } else {
                    progressColor = color;
                  }
                } else {
                  progressColor = c.textSecondary.withAlpha(120);
                }

                final clampedProgress = progressPercent.clamp(0.0, 1.0);

                return Stack(
                  children: [
                    // Track
                    Container(
                      height: 6,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: c.tabBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Filled
                    AnimatedBuilder(
                      animation: barAnimation,
                      builder: (context, _) {
                        return Container(
                          height: 6,
                          width: constraints.maxWidth * clampedProgress * barAnimation.value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                progressColor.withAlpha(200),
                                progressColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: progressColor.withAlpha(80),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav Arrow button ───────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _NavArrow(
      {required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(disabled ? 15 : 35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: disabled ? Colors.white38 : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
