import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String? _userEmail;
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>("");
  final String _selectedSort = "Date"; // Date, Amount

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final email = await sl<IAuthRepository>().getUserEmail();
    if (mounted) {
      _userEmail = email;
      context.read<TransactionBloc>().add(LoadTransactions(_userEmail));
    }
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    super.dispose();
  }

  Map<String, List<TransactionModel>> _groupExpensesByMonthYear(
      List<TransactionModel> expenses) {
    // Sort expenses first
    if (_selectedSort == "Date") {
      expenses.sort((a, b) => b.date.compareTo(a.date));
    } else {
      expenses.sort((a, b) => b.amount.compareTo(a.amount));
    }

    final grouped = <String, List<TransactionModel>>{};
    for (var expense in expenses) {
      if (_searchQuery.value.isNotEmpty &&
          !expense.title
              .toLowerCase()
              .contains(_searchQuery.value.toLowerCase())) {
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
          onPressed: () => context.pop(),
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
                    color: Colors.black.withAlpha(13), // 0.05 * 255
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => _searchQuery.value = value,
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

          // Transactions List
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _searchQuery,
              builder: (context, query, _) {
                return BlocBuilder<TransactionBloc, TransactionState>(
                  builder: (context, state) {
                    if (state is TransactionLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is TransactionFailure) {
                      return Center(child: Text(state.message));
                    } else if (state is TransactionLoaded) {
                      final grouped =
                          _groupExpensesByMonthYear(state.transactions);
                      if (grouped.isEmpty) {
                        return const Center(
                            child: Text("No transactions found"));
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
                                padding:
                                    const EdgeInsets.fromLTRB(24, 20, 24, 12),
                                child: Text(
                                  monthYear,
                                  style: AppTextStyles.heading2
                                      .copyWith(fontSize: 16),
                                ),
                              ),
                              ...monthExpenses.map((expense) {
                                return TransactionTile(
                                  title: expense.title,
                                  category: expense.category,
                                  date: DateFormat('MMMM dd, yyyy')
                                      .format(expense.date),
                                  amount: expense.amount.toStringAsFixed(2),
                                  isIncome: expense.isIncome,
                                  onEdit: () {
                                    context
                                        .push<bool>(
                                          RoutePaths.addExpense,
                                          extra: expense,
                                        )
                                        .then((_) => _loadUserAndData());
                                  },
                                  onDelete: () {
                                    if (expense.id != null) {
                                      context.read<TransactionBloc>().add(
                                            DeleteTransaction(
                                              transactionId: expense.id!,
                                              remoteId:
                                                  expense.remoteId?.toString(),
                                              userEmail: _userEmail,
                                            ),
                                          );
                                    }
                                  },
                                );
                              }),
                            ],
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
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
        border: Border.all(color: Colors.grey.withAlpha(51)), // 0.2 * 255
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
