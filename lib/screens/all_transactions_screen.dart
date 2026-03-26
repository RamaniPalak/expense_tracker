import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';

import '../utils/text_styles.dart';
import 'add_expense_screen.dart';
import '../services/expense_service.dart';
import '../widgets/transaction_tile.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String? _userEmail;
  String _searchQuery = "";
  String _selectedSort = "Date"; // Date, Amount

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final email = await AuthService().getUserEmail();
    if (mounted) {
      setState(() {
        _userEmail = email;
      });
      DatabaseHelper.instance.refreshExpenses(_userEmail, syncFromRemote: true);
    }
  }

  Map<String, List<Expense>> _groupExpensesByMonthYear(List<Expense> expenses) {
    // Sort expenses first
    if (_selectedSort == "Date") {
      expenses.sort((a, b) => b.date.compareTo(a.date));
    } else {
      expenses.sort((a, b) => b.amount.compareTo(a.amount));
    }

    final grouped = <String, List<Expense>>{};
    for (var expense in expenses) {
      if (_searchQuery.isNotEmpty &&
          !expense.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        continue;
      }

      final monthYear = DateFormat('MMMM yyyy').format(expense.date);
      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }
      grouped[monthYear]!.add(expense);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF3F7F2), // Light greenish background from image
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Transactions",
          style: AppTextStyles.heading2
              .copyWith(color: Colors.black, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search transactions...",
                  hintStyle:
                      AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip("Filter (3)",
                    isSelected: true, hasDropdown: true),
                const SizedBox(width: 12),
                _buildFilterChip("Subscription"),
                const SizedBox(width: 12),
                _buildFilterChip("Income"),
                const SizedBox(width: 12),
                _buildFilterChip("Expense"),
              ],
            ),
          ),

          // Sort By Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "Sort By: ",
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                ),
                DropdownButton<String>(
                  value: _selectedSort,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  items: ["Date", "Amount"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: AppTextStyles.bodySmall
                              .copyWith(fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSort = val);
                  },
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: ValueListenableBuilder<List<Expense>>(
              valueListenable: DatabaseHelper.instance.expensesNotifier,
              builder: (context, expenses, _) {
                final grouped = _groupExpensesByMonthYear(expenses);
                if (grouped.isEmpty) {
                  return const Center(child: Text("No transactions found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final monthYear = grouped.keys.elementAt(index);
                    final monthExpenses = grouped[monthYear]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                          child: Text(
                            monthYear,
                            style:
                                AppTextStyles.heading2.copyWith(fontSize: 16),
                          ),
                        ),
                        ...monthExpenses.map((expense) {
                          return TransactionTile(
                            title: expense.title,
                            category: expense.category,
                            date: DateFormat('MMMM dd, yyyy').format(expense.date),
                            amount: expense.amount.toStringAsFixed(2),
                            isIncome: expense.isIncome,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddExpenseScreen(expense: expense),
                                ),
                              ).then((_) => _loadUserAndData());
                            },
                            onDelete: () async {
                              if (expense.id != null) {
                                if (expense.remoteId != null) {
                                  await ExpenseService()
                                      .deleteExpense(expense.remoteId!);
                                }
                                await DatabaseHelper.instance
                                    .deleteExpense(expense.id!, _userEmail);
                                _loadUserAndData();
                              }
                            },
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label,
      {bool isSelected = false, bool hasDropdown = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hasDropdown) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 16, color: isSelected ? Colors.white : Colors.black),
          ],
        ],
      ),
    );
  }


}
