import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
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
      _userEmail = email;
      context.read<TransactionBloc>().add(LoadTransactions(_userEmail));
    }
  }

  @override
  void dispose() {
    _selectedTabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
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
                                Icons.add, "Add", onTap: () {
                              context.push(RoutePaths.addExpense).then((_) => _loadUser());
                            }),
                            WalletHelper.buildActionButton(
                                Icons.qr_code_scanner, "Pay", onTap: () {
                                  // Add Pay functionality if needed
                                }),
                            WalletHelper.buildActionButton(
                                Icons.send_outlined, "Send", onTap: () {
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
                                color: AppColors.greyLight.withAlpha(76),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: WalletHelper.buildTabButton(
                                      text: "Transactions",
                                      isSelected: selectedIndex == 0,
                                      onTap: () => _selectedTabIndex.value = 0,
                                    ),
                                  ),
                                  Expanded(
                                    child: WalletHelper.buildTabButton(
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
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              "₹ ${totalBalance.toStringAsFixed(2)}",
              style: AppTextStyles.heading1.copyWith(fontSize: 32),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionsList() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TransactionFailure) {
          return Center(child: Text(state.message));
        } else if (state is TransactionLoaded) {
          final expenses = state.transactions;
          if (expenses.isEmpty) {
            return const Center(child: Text("No transactions yet"));
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

  Widget _buildUpcomingBillsList() {
    return Column(
      children: [
        UpcomingBillTile(
          title: "House Rent",
          date: "Mar 01, 2025",
          onPayTap: () {},
        ),
        UpcomingBillTile(
          title: "Electricity",
          date: "Mar 05, 2025",
          onPayTap: () {},
        ),
        UpcomingBillTile(
          title: "Spotify",
          date: "Mar 12, 2025",
          onPayTap: () {},
        ),
      ],
    );
  }
}
