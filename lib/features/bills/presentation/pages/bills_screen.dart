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
          _buildHeader(context),
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

  Widget _buildHeader(BuildContext context) {
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
                style: AppTextStyles.heading1.copyWith(color: Colors.white),
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

  Widget _buildBillsList() {
    final c = context.appColors;
    return ValueListenableBuilder<List<BillModel>>(
      valueListenable: sl<DatabaseHelper>().billsNotifier,
      builder: (context, bills, _) {
        if (bills.isEmpty) {
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

        final upcoming = bills.where((b) => !b.isPaid).toList();
        final paid = bills.where((b) => b.isPaid).toList();

        return SliverList(
          delegate: SliverChildListDelegate([
            if (upcoming.isNotEmpty) ...[
              _buildSectionHeader(context, "Upcoming Payments"),
              ...upcoming.map((bill) =>
                  _BillCard(bill: bill, onMarkPaid: () => _markAsPaid(bill))),
            ],
            if (paid.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionHeader(context, "Recently Paid"),
              ...paid.map((bill) => _BillCard(bill: bill, isPaid: true)),
            ],
            const SizedBox(height: 80),
          ]),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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
    }
  }

  void _showAddBillDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddBillSheet(userEmail: _userEmail ?? ''),
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillModel bill;
  final bool isPaid;
  final VoidCallback? onMarkPaid;

  const _BillCard({required this.bill, this.isPaid = false, this.onMarkPaid});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final diff = bill.dueDate.difference(DateTime.now()).inDays;
    final isUrgent = !isPaid && diff <= 3;

    return Container(
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
              color: (isPaid
                      ? Colors.green
                      : (isUrgent ? Colors.red : AppColors.primary))
                  .withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.calendar_today,
              color: isPaid
                  ? Colors.green
                  : (isUrgent ? Colors.red : AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  style: AppTextStyles.heading2.copyWith(fontSize: 16, color: c.textPrimary),
                ),
                Text(
                  isPaid
                      ? "Paid on ${DateFormat('MMM dd').format(bill.dueDate)}"
                      : "Due in $diff days",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isUrgent && !isPaid
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
                  color: isPaid ? Colors.green : c.textPrimary,
                ),
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
    );
  }
}

class _AddBillSheet extends StatefulWidget {
  final String userEmail;
  const _AddBillSheet({required this.userEmail});

  @override
  State<_AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends State<_AddBillSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  final String _selectedCategory = 'Utility';
  bool _isRecurring = false;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Add New Bill",
            style: AppTextStyles.heading1.copyWith(color: c.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: "Bill Name (e.g. Netflix)",
              hintStyle: TextStyle(color: c.textSecondary),
              filled: true,
              fillColor: c.inputFill,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: "Amount",
              hintStyle: TextStyle(color: c.textSecondary),
              prefixText: "₹ ",
              prefixStyle: TextStyle(color: c.textPrimary),
              filled: true,
              fillColor: c.inputFill,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(
              "Due Date",
              style: TextStyle(color: c.textPrimary),
            ),
            subtitle: Text(
              DateFormat('MMM dd, yyyy').format(_selectedDate),
              style: TextStyle(color: c.textSecondary),
            ),
            trailing: Icon(
              Icons.calendar_month,
              color: c.textSecondary,
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          SwitchListTile(
            title: Text(
              "Recurring Monthly",
              style: TextStyle(color: c.textPrimary),
            ),
            subtitle: Text(
              "Automatically schedules next month's bill",
              style: TextStyle(color: c.textSecondary),
            ),
            value: _isRecurring,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _isRecurring = val),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveBill,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Add Bill Reminder"),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _saveBill() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;

    final bill = BillModel(
      title: _titleController.text,
      amount: double.tryParse(_amountController.text) ?? 0,
      dueDate: _selectedDate,
      category: _selectedCategory,
      isRecurring: _isRecurring,
      userEmail: widget.userEmail,
    );

    await sl<DatabaseHelper>().insertBill(bill);
    if (mounted) Navigator.pop(context);
  }
}
