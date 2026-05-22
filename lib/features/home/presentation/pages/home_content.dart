import 'package:flutter/material.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/common_widgets/glass_container.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
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
      // Initial sync from remote on load
      sl<DatabaseHelper>().refreshExpenses(_userEmail, syncFromRemote: true);
      sl<DatabaseHelper>().refreshBills(_userEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      color: c.background,
      child: Stack(
      children: [
        Column(
          children: [

            // Header Stack (Fixed)
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Curved Background
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: AppColors.mainGradient,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -50,
                          left: -50,
                          child: CircleAvatar(
                            radius: 100,
                            backgroundColor: Colors.white.withAlpha(13),
                          ),
                        ),
                        Positioned(
                          right: -30,
                          top: 50,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white.withAlpha(13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.goodAfternoon,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userEmail?.split('@')[0] ?? "User",
                                style: AppTextStyles.heading2.copyWith(
                                    color: Colors.white, fontSize: 20),
                              ),
                            ],
                          ),
                          GlassContainer(
                            padding: const EdgeInsets.all(8),
                            borderRadius: 12,
                            opacity: 0.1,
                            child: Stack(
                              children: [
                                const Icon(Icons.notifications_none,
                                    color: Colors.white),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.expenseRed,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Balance Card
                      ValueListenableBuilder<List<TransactionModel>>(
                        valueListenable: sl<DatabaseHelper>().expensesNotifier,
                        builder: (context, expenses, _) {
                          double totalBalance = 0;
                          double totalIncome = 0;
                          double totalExpenses = 0;

                          for (var expense in expenses) {
                            if (expense.isIncome) {
                              totalIncome += expense.amount;
                              totalBalance += expense.amount;
                            } else {
                              totalExpenses += expense.amount;
                              totalBalance -= expense.amount;
                            }
                          }

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 24),
                            decoration: BoxDecoration(
                              gradient: AppColors.cardGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          AppStrings.totalBalance,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(color: Colors.white70),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.keyboard_arrow_up,
                                            color: Colors.white70, size: 20)
                                      ],
                                    ),
                                    const Icon(Icons.more_horiz,
                                        color: Colors.white70),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: totalBalance),
                                  duration: const Duration(milliseconds: 1500),
                                  curve: Curves.fastOutSlowIn,
                                  builder: (context, value, child) {
                                    return Text(
                                      "₹ ${value.toStringAsFixed(2)}",
                                      style: AppTextStyles.heading1.copyWith(
                                          color: Colors.white, fontSize: 30),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white24,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Icon(
                                                    Icons.arrow_downward,
                                                    color: Colors.white,
                                                    size: 16),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(AppStrings.income,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                          color:
                                                              Colors.white70)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                              "₹ ${totalIncome.toStringAsFixed(2)}",
                                              style: AppTextStyles.bodyLarge
                                                  .copyWith(
                                                      color: Colors.white,
                                                      fontSize: 18)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white24,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Icon(
                                                    Icons.arrow_upward,
                                                    color: Colors.white,
                                                    size: 16),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(AppStrings.expenses,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                          color:
                                                              Colors.white70)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                              "₹ ${totalExpenses.toStringAsFixed(2)}",
                                              style: AppTextStyles.bodyLarge
                                                  .copyWith(
                                                      color: Colors.white,
                                                      fontSize: 18)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Scrollable part
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  color: c.background,
                  child: Column(
                    children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppStrings.transactionsHistory,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary)),
                          GestureDetector(
                            onTap: () {
                              context
                                  .push(RoutePaths.allTransactions)
                                  .then((_) => _loadUserAndData());
                            },
                            child: Text(AppStrings.seeAll,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: c.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ValueListenableBuilder<List<TransactionModel>>(
                        valueListenable: sl<DatabaseHelper>().expensesNotifier,
                        builder: (context, expenses, _) {
                          if (expenses.isEmpty) {
                            return const Center(
                                child: Text(AppStrings.noTransactions));
                          }
                          final displayList = expenses.take(5).toList();
                          return Column(
                            children: displayList.map((expense) {
                              return TransactionTile(
                                title: expense.title,
                                category: expense.category,
                                date: DateFormat('MMM dd, yyyy', 'en_US')
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
                                onDelete: () async {
                                  if (expense.id != null) {
                                    if (expense.remoteId != null) {
                                      await sl<ExpenseService>()
                                          .deleteExpense(expense.remoteId!);
                                    }
                                    await sl<DatabaseHelper>().deleteExpense(
                                        expense.id!, _userEmail);
                                    _loadUserAndData();
                                  }
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Bill Management Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Upcoming Bills",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary)),
                          GestureDetector(
                            onTap: () => context.push(RoutePaths.bills),
                            child: Text(AppStrings.seeAll,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: c.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ValueListenableBuilder<List<BillModel>>(
                        valueListenable: sl<DatabaseHelper>().billsNotifier,
                        builder: (context, bills, _) {
                          final upcoming = bills.where((b) => !b.isPaid).take(2).toList();
                          if (upcoming.isEmpty) {
                            return _buildEmptyBillsCard(context);
                          }
                          return Column(
                            children: upcoming.map((bill) {
                              return _buildBillSummaryTile(context, bill);
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Chatbot Floating Entry Point
        Positioned(
          bottom: 100,
          right: 24,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'chatbot_fab',
            onPressed: () => context.push(RoutePaths.chatbot),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildEmptyBillsCard(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: () => context.push(RoutePaths.bills),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border.withAlpha(127)),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Text("Add your first bill reminder",
                style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSummaryTile(BuildContext context, BillModel bill) {
    final c = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold, color: c.textPrimary)),
                Text("Due ${DateFormat('MMM dd').format(bill.dueDate)}",
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 12, color: c.textSecondary)),
              ],
            ),
          ),
          Flexible(
            child: Text(
              "₹${bill.amount.toStringAsFixed(0)}",
              style: AppTextStyles.bodyLarge
                  .copyWith(fontSize: 16, color: c.textPrimary),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
