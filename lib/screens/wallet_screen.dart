import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../utils/text_styles.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/upcoming_bill_tile.dart';
import '../widgets/wallet_helper.dart';
import 'connect_wallet_screen.dart';
import '../models/expense_model.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import 'add_expense_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedTabIndex = 0; // 0 for Transactions, 1 for Upcoming Bills
  String? _userEmail;

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
      DatabaseHelper.instance.refreshExpenses(_userEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            WalletHelper.buildHeader(context),

            // Content Body starting overlapping the header
            Transform.translate(
              offset: const Offset(0, -60), // Pull up to overlap
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      ValueListenableBuilder<List<Expense>>(
                        valueListenable:
                            DatabaseHelper.instance.expensesNotifier,
                        builder: (context, expenses, _) {
                          final total = expenses.fold(0.0, (sum, item) {
                            return item.isIncome
                                ? sum + item.amount
                                : sum - item.amount;
                          });
                          return Column(
                            children: [
                              Text(
                                "Total Balance",
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "₹ ${total.toStringAsFixed(2)}",
                                style: AppTextStyles.heading1
                                    .copyWith(fontSize: 32),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          WalletHelper.buildActionButton(
                            Icons.add,
                            "Add",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ConnectWalletScreen(),
                                ),
                              );
                            },
                          ),
                          WalletHelper.buildActionButton(
                              Icons.qr_code_scanner, "Pay"),
                          WalletHelper.buildActionButton(Icons.send, "Send"),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Tab Switcher
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.tabBackground, // Light grey bg
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: WalletHelper.buildTabButton(
                                text: "Transactions",
                                isSelected: _selectedTabIndex == 0,
                                onTap: () =>
                                    setState(() => _selectedTabIndex = 0),
                              ),
                            ),
                            Expanded(
                              child: WalletHelper.buildTabButton(
                                text: "Upcoming Bills",
                                isSelected: _selectedTabIndex == 1,
                                onTap: () =>
                                    setState(() => _selectedTabIndex = 1),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Transactions / Bills List
                      _selectedTabIndex == 0
                          ? _buildTransactionsList()
                          : _buildUpcomingBillsList(),

                      const SizedBox(height: 80), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ValueListenableBuilder<List<Expense>>(
      valueListenable: DatabaseHelper.instance.expensesNotifier,
      builder: (context, expenses, _) {
        if (expenses.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No transactions yet"),
            ),
          );
        }

        return Column(
          children: expenses.map((expense) {
            return TransactionTile(
              title: expense.title,
              category: expense.category,
              date: DateFormat('MMM dd, yyyy', 'en_US').format(expense.date),
              amount: expense.amount.toStringAsFixed(2),
              isIncome: expense.isIncome,
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpenseScreen(expense: expense),
                  ),
                ).then((_) => _loadUserAndData());
              },
              onDelete: () {
                if (expense.id != null) {
                  DatabaseHelper.instance
                      .deleteExpense(expense.id!, _userEmail);
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUpcomingBillsList() {
    return Column(
      children: [
        UpcomingBillTile(
          title: "Youtube",
          date: "Feb 28, 2022",
          onPayTap: () {},
        ),
        UpcomingBillTile(
          title: "Electricity",
          date: "Mar 28, 2022",
          onPayTap: () {},
        ),
        UpcomingBillTile(
          title: "House Rent",
          date: "Mar 31, 2022",
          onPayTap: () {},
        ),
        UpcomingBillTile(
          title: "Spotify",
          date: "Feb 28, 2022",
          onPayTap: () {},
        ),
      ],
    );
  }
}
