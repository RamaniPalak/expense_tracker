import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/features/wallet/presentation/widgets/wallet_helper.dart';
import 'package:expense_tracker/features/wallet/presentation/widgets/upcoming_bill_tile.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';

import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ValueNotifier<int> _selectedTabIndex = ValueNotifier<int>(0); // 0 for Transactions, 1 for Upcoming Bills
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = await sl<IAuthRepository>().getUserEmail();
    if (mounted) {
      setState(() {
        _userEmail = email;
      });
      context.read<TransactionBloc>().add(LoadTransactions(_userEmail));
      sl<DatabaseHelper>().refreshBills(_userEmail);
    }
  }

  @override
  void dispose() {
    _selectedTabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          // Header
          WalletHelper.buildHeader(context),

          // Main Content Area (Using Transform to overlap header slightly)
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Total Balance Card
                        _buildTotalBalanceCard(),
                        const SizedBox(height: 32),
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            WalletHelper.buildActionButton(
                                context, Icons.add, "Add", onTap: () {
                              context.push(RoutePaths.addExpense).then((_) => _loadUser());
                            }),
                            WalletHelper.buildActionButton(
                                context, Icons.qr_code_scanner, "Pay", onTap: () {
                                  // Add Pay functionality if needed
                                }),
                            WalletHelper.buildActionButton(
                                context, Icons.send_outlined, "Send", onTap: () {
                                  // Add Send functionality if needed
                                }),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Tab Bar
                        ValueListenableBuilder<int>(
                          valueListenable: _selectedTabIndex,
                          builder: (context, selectedIndex, _) {
                            return Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: c.tabBg,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: WalletHelper.buildTabButton(
                                      context: context,
                                      text: "Transactions",
                                      isSelected: selectedIndex == 0,
                                      onTap: () => _selectedTabIndex.value = 0,
                                    ),
                                  ),
                                  Expanded(
                                    child: WalletHelper.buildTabButton(
                                      context: context,
                                      text: "Upcoming Bills",
                                      isSelected: selectedIndex == 1,
                                      onTap: () => _selectedTabIndex.value = 1,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Tab Content
                        ValueListenableBuilder<int>(
                          valueListenable: _selectedTabIndex,
                          builder: (context, selectedIndex, _) {
                            return selectedIndex == 0
                                ? _buildTransactionsList()
                                : _buildUpcomingBillsList();
                          },
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard() {
    final c = context.appColors;
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        double totalBalance = 0;
        if (state is TransactionLoaded) {
          for (var expense in state.transactions) {
            if (expense.isIncome) {
              totalBalance += expense.amount;
            } else {
              totalBalance -= expense.amount;
            }
          }
        }
        return Column(
          children: [
            Text(
              "Total Balance",
              style: AppTextStyles.bodyMedium
                  .copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              "₹ ${totalBalance.toStringAsFixed(2)}",
              style: AppTextStyles.heading1.copyWith(
                fontSize: 32,
                color: c.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionsList() {
    final c = context.appColors;
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TransactionFailure) {
          return Center(
            child: Text(
              state.message,
              style: TextStyle(color: c.textPrimary),
            ),
          );
        } else if (state is TransactionLoaded) {
          final expenses = state.transactions;
          if (expenses.isEmpty) {
            return Center(
              child: Text(
                "No transactions yet",
                style: TextStyle(color: c.textPrimary),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return TransactionTile(
                title: expense.title,
                category: expense.category,
                date: DateFormat('MMM dd, yyyy').format(expense.date),
                amount: expense.amount.toStringAsFixed(2),
                isIncome: expense.isIncome,
                onEdit: () {
                  context.push<bool>(
                    RoutePaths.addExpense,
                    extra: expense,
                  ).then((_) => _loadUser());
                },
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _markAsPaid(BillModel bill) async {
    // 1. Update bill status
    await sl<DatabaseHelper>().updateBill(bill.copyWith(isPaid: true));

    // 2. Auto-Expense: Create a transaction automatically
    final transaction = TransactionModel(
      title: "Paid: ${bill.title}",
      amount: bill.amount,
      date: DateTime.now(),
      category: bill.category,
      isIncome: false,
      userEmail: bill.userEmail,
    );
    await sl<DatabaseHelper>().insertExpense(transaction);

    // 3. Recurring Logic: Schedule next month's bill if enabled
    if (bill.isRecurring) {
      final nextDueDate = DateTime(
        bill.dueDate.year,
        bill.dueDate.month + 1,
        bill.dueDate.day,
      );

      final nextBill = bill.copyWith(
        id: null,
        dueDate: nextDueDate,
        isPaid: false,
      );
      await sl<DatabaseHelper>().insertBill(nextBill);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${bill.title} marked as paid & added to expenses!"),
          backgroundColor: Colors.green,
        ),
      );
      _loadUser();
    }
  }

  Widget _buildUpcomingBillsList() {
    final c = context.appColors;
    return ValueListenableBuilder<List<BillModel>>(
      valueListenable: sl<DatabaseHelper>().billsNotifier,
      builder: (context, bills, _) {
        final upcoming = bills.where((b) => !b.isPaid).toList();
        if (upcoming.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 48, color: c.textSecondary.withAlpha(80)),
                  const SizedBox(height: 12),
                  Text(
                    "No upcoming bills",
                    style: TextStyle(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: upcoming.length,
          itemBuilder: (context, index) {
            final bill = upcoming[index];
            return UpcomingBillTile(
              title: bill.title,
              date: DateFormat('MMM dd, yyyy').format(bill.dueDate),
              onPayTap: () => _markAsPaid(bill),
            );
          },
        );
      },
    );
  }
}
