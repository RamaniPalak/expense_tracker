import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/routing/app_router.dart';

import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _userEmail = await sl<IAuthRepository>().getUserEmail();
    if (_userEmail != null) {
      await sl<DatabaseHelper>().refreshBills(_userEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      body: CustomScrollView(
        slivers: [
          const _BillsHeader(),
          _buildBillsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBillDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBillsList() {
    return ValueListenableBuilder<List<BillModel>>(
      valueListenable: sl<DatabaseHelper>().billsNotifier,
      builder: (context, bills, _) {
        if (bills.isEmpty) {
          return const _BillsEmptyState();
        }

        final upcoming = bills.where((b) => !b.isPaid).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final paid = bills.where((b) => b.isPaid).toList()
          ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

        return SliverList(
          delegate: SliverChildListDelegate([
            if (upcoming.isNotEmpty) ...[
              const _BillsSectionHeader(title: "Upcoming Payments"),
              ...upcoming.map((bill) => _BillCard(
                    bill: bill,
                    onMarkPaid: () => _markAsPaid(bill),
                    onTap: () => context.push(RoutePaths.billDetail, extra: bill),
                  )),
            ],
            if (paid.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _BillsSectionHeader(title: "Recently Paid"),
              ...paid.map((bill) => _BillCard(
                    bill: bill,
                    isPaid: true,
                    onTap: () => context.push(RoutePaths.billDetail, extra: bill),
                  )),
            ],
            const SizedBox(height: 80),
          ]),
        );
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
      // Use Duration-based addition to safely handle month overflow (e.g. Jan 31 + 1 month)
      final currentDue = bill.dueDate;
      final nextMonth = DateTime(currentDue.year, currentDue.month + 1, 1);
      final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
      final nextDueDate = DateTime(
        nextMonth.year,
        nextMonth.month,
        currentDue.day.clamp(1, lastDayOfNextMonth),
      );

      if (bill.endDate == null ||
          nextDueDate.isBefore(bill.endDate!) ||
          nextDueDate.isAtSameMomentAs(bill.endDate!)) {
        final nextBill = BillModel(
          title: bill.title,
          amount: bill.amount,
          dueDate: nextDueDate,
          endDate: bill.endDate,
          category: bill.category,
          isPaid: false,
          isRecurring: bill.isRecurring,
          userEmail: bill.userEmail,
        );
        await sl<DatabaseHelper>().insertBill(nextBill);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${bill.title} marked as paid & added to expenses!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showAddBillDialog(BuildContext context) async {
    final result = await context.push(
      RoutePaths.addEditBill,
      extra: {'userEmail': _userEmail ?? ''},
    );
    if (result == true && mounted) {
      _loadData();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Reusable Stateless Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BillsHeader extends StatelessWidget {
  const _BillsHeader();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.receipt_long, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(
                "Bill Management",
                style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 22),
              ),
              Text(
                "Never miss a payment again",
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }
}

class _BillsSectionHeader extends StatelessWidget {
  final String title;

  const _BillsSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
          color: c.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _BillsEmptyState extends StatelessWidget {
  const _BillsEmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64, color: c.textSecondary.withAlpha(50)),
            const SizedBox(height: 16),
            Text(
              "No upcoming bills",
              style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillModel bill;
  final bool isPaid;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onTap;

  const _BillCard({
    required this.bill,
    this.isPaid = false,
    this.onMarkPaid,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day);
    final diff = dueDay.difference(today).inDays;
    final isOverdue = !isPaid && diff < 0;
    final isUrgent = !isPaid && diff <= 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (isPaid ? Colors.green : (isUrgent ? Colors.red : AppColors.primary))
                        .withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPaid ? Icons.check_circle : Icons.calendar_today,
                color:
                    isPaid ? Colors.green : (isUrgent ? Colors.red : AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: AppTextStyles.heading2
                        .copyWith(fontSize: 16, color: c.textPrimary),
                  ),
                  Text(
                    isPaid
                        ? "Paid on ${DateFormat('MMM dd').format(bill.dueDate)}"
                        : isOverdue
                            ? "Overdue by ${diff.abs()} day${diff.abs() == 1 ? '' : 's'}"
                            : diff == 0
                                ? "Due today"
                                : "Due in $diff day${diff == 1 ? '' : 's'}",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: (isOverdue || (isUrgent && !isPaid))
                          ? Colors.red
                          : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹ ${bill.amount.toStringAsFixed(0)}",
                  style: AppTextStyles.heading2.copyWith(
                      color: isPaid ? Colors.green : c.textPrimary, fontSize: 18),
                ),
                if (!isPaid)
                  TextButton(
                    onPressed: onMarkPaid,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("Pay Now"),
                  ),
              ],
            ),
          ],
        ),
      ), // GestureDetector
    );
  }
}
