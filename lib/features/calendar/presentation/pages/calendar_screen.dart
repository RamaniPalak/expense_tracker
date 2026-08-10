import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/calendar/presentation/widgets/calendar_transaction_tile.dart';
import 'package:expense_tracker/features/calendar/presentation/widgets/calendar_summary_card.dart';
import 'package:expense_tracker/features/calendar/presentation/widgets/calendar_view_mode_sheet.dart';
import 'package:expense_tracker/features/calendar/presentation/widgets/calendar_month_view.dart';
import 'package:expense_tracker/features/calendar/presentation/widgets/calendar_year_view.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String? _userEmail;
  String _viewMode = "Month"; // "Month" or "Year"
  
  // State for Month View
  DateTime _currentMonthYear = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  
  // State for Year View
  int _currentYear = DateTime.now().year;
  int _selectedMonthIndex = DateTime.now().month; // 1 to 12

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
    }
  }

  Future<void> _editTransaction(TransactionModel tx) async {
    final updated = await context.push<bool>(RoutePaths.addExpense, extra: tx);
    if (updated == true || true) {
      sl<DatabaseHelper>().refreshExpenses(_userEmail);
    }
  }

  Future<void> _confirmDeleteTransaction(TransactionModel tx) async {
    final c = context.appColors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Transaction?', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${tx.title}" (₹${tx.amount.toStringAsFixed(2)})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && tx.id != null) {
      await sl<DatabaseHelper>().deleteExpense(tx.id!, _userEmail);
    }
  }

  // Navigate calendar month or year offsets
  void _navigateOffset(int direction) {
    setState(() {
      if (_viewMode == "Month") {
        int newMonth = _currentMonthYear.month + direction;
        int newYear = _currentMonthYear.year;
        if (newMonth > 12) {
          newMonth = 1;
          newYear++;
        } else if (newMonth < 1) {
          newMonth = 12;
          newYear--;
        }
        _currentMonthYear = DateTime(newYear, newMonth);
        _selectedDate = DateTime(newYear, newMonth, 1);
      } else {
        _currentYear += direction;
        _selectedDate = DateTime(_currentYear, _selectedMonthIndex, 1);
      }
    });
  }

  // Date Suffix generator (e.g. 1 -> 1st, 2 -> 2nd, etc.)
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:  return 'st';
      case 2:  return 'nd';
      case 3:  return 'rd';
      default: return 'th';
    }
  }

  String _formatHeaderDate(DateTime date) {
    final day = date.day;
    final suffix = _getDaySuffix(day);
    final dayName = DateFormat('EEE').format(date);
    final monthName = DateFormat('MMM').format(date);
    return "$dayName, $monthName $day$suffix ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ValueListenableBuilder<List<TransactionModel>>(
          valueListenable: sl<DatabaseHelper>().expensesNotifier,
          builder: (context, allExpenses, _) {
            // 1. Calculate filtered lists & summary aggregates
            List<TransactionModel> displayTransactions = [];
            double totalIncome = 0;
            double totalExpense = 0;

            if (_viewMode == "Month") {
              // Transactions for the selected day in Month View
              displayTransactions = allExpenses.where((tx) =>
                  tx.date.year == _selectedDate.year &&
                  tx.date.month == _selectedDate.month &&
                  tx.date.day == _selectedDate.day).toList();

              for (var tx in displayTransactions) {
                if (tx.isIncome) {
                  totalIncome += tx.amount;
                } else {
                  totalExpense += tx.amount;
                }
              }
            } else {
              // Transactions for the selected month in Year View
              displayTransactions = allExpenses.where((tx) =>
                  tx.date.year == _currentYear &&
                  tx.date.month == _selectedMonthIndex).toList();

              for (var tx in displayTransactions) {
                if (tx.isIncome) {
                  totalIncome += tx.amount;
                } else {
                  totalExpense += tx.amount;
                }
              }
            }

            final totalSavings = totalIncome - totalExpense;

            // Sort transactions chronologically descending
            displayTransactions.sort((a, b) => b.date.compareTo(a.date));

            // Generate list items dynamically
            final List<Widget> listItems = [];
            if (displayTransactions.isEmpty) {
              listItems.add(
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      "No entries for this period",
                      style: TextStyle(color: c.textSecondary),
                    ),
                  ),
                ),
              );
            } else {
              if (_viewMode == "Month") {
                listItems.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _formatHeaderDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                );
                for (var tx in displayTransactions) {
                  listItems.add(
                    CalendarTransactionTile(
                      tx: tx,
                      onEdit: () => _editTransaction(tx),
                      onDelete: () => _confirmDeleteTransaction(tx),
                    ),
                  );
                }
              } else {
                DateTime? lastDate;
                for (var tx in displayTransactions) {
                  final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
                  if (lastDate == null || txDate != lastDate) {
                    listItems.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _formatHeaderDate(tx.date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    );
                    lastDate = txDate;
                  }
                  listItems.add(
                    CalendarTransactionTile(
                      tx: tx,
                      onEdit: () => _editTransaction(tx),
                      onDelete: () => _confirmDeleteTransaction(tx),
                    ),
                  );
                }
              }
            }

            return Column(
              children: [
                // Header (Title & INR Badge)
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48), // Spacer to balance chip
                      Text(
                        "Calendar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      // INR Badge Chip (static as currency is Rupee)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          "INR (₹)",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selector Navigation Row (< Name >)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 18),
                        onPressed: () => _navigateOffset(-1),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => showCalendarViewModeSheet(
                          context: context,
                          currentViewMode: _viewMode,
                          onViewModeSelected: (newMode) {
                            setState(() {
                              _viewMode = newMode;
                              if (newMode == "Month") {
                                _selectedDate = DateTime(_currentMonthYear.year, _currentMonthYear.month, 1);
                              } else {
                                _selectedDate = DateTime(_currentYear, _selectedMonthIndex, 1);
                              }
                            });
                          },
                        ),
                        child: Row(
                          children: [
                            Text(
                              _viewMode == "Month"
                                  ? DateFormat('MMMM yyyy').format(_currentMonthYear)
                                  : "$_currentYear",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 18),
                        onPressed: () => _navigateOffset(1),
                      ),
                    ],
                  ),
                ),

                // Calendar Grid Container
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: _viewMode == "Year" ? 2 : 4,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _viewMode == "Month"
                        ? CalendarMonthView(
                            key: const ValueKey("MonthGrid"),
                            currentMonthYear: _currentMonthYear,
                            selectedDate: _selectedDate,
                            allExpenses: allExpenses,
                            onDateSelected: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                          )
                        : CalendarYearView(
                            key: const ValueKey("YearGrid"),
                            currentYear: _currentYear,
                            selectedMonthIndex: _selectedMonthIndex,
                            allExpenses: allExpenses,
                            onMonthSelected: (monthIndex, cellDate) {
                              setState(() {
                                _selectedMonthIndex = monthIndex;
                                _selectedDate = cellDate;
                              });
                            },
                          ),
                  ),
                ),

                // Bottom Content Area (Aggregates & List)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 18, right: 18, top: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F132B) : const Color(0xFFF9FAFC),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CalendarSummaryCard(
                          income: totalIncome,
                          expense: totalExpense,
                          savings: totalSavings,
                        ),
                        const SizedBox(height: 10),
                        
                        // Transaction List with bottom padding so items aren't hidden by bottom bar
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 100),
                            children: listItems,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
