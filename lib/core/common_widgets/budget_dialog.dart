import 'package:flutter/material.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class BudgetDialog extends StatefulWidget {
  final String? userEmail;
  final BudgetModel? initialBudget;
  final int? month;
  final int? year;
  final String category;

  const BudgetDialog({
    super.key,
    this.userEmail,
    this.initialBudget,
    this.month,
    this.year,
    this.category = AppStrings.total,
  });

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialBudget != null) {
      _amountController.text = widget.initialBudget!.amount.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (widget.userEmail == null) return;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    final now = DateTime.now();
    final budget = BudgetModel(
      category: widget.category,
      amount: amount,
      month: widget.month ?? now.month,
      year: widget.year ?? now.year,
      userEmail: widget.userEmail!,
    );

    await sl<DatabaseHelper>().upsertBudget(budget);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteBudget() async {
    if (widget.initialBudget?.id == null || widget.userEmail == null) return;
    await sl<DatabaseHelper>().deleteBudget(widget.initialBudget!.id!, widget.userEmail!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isTotal = widget.category == AppStrings.total;

    return AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isTotal ? AppStrings.budgetPlanTitle : "${widget.category} Budget",
        style: AppTextStyles.heading2.copyWith(color: c.textPrimary, fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTotal
                ? AppStrings.budgetPlanSub
                : "Set a spending limit for the ${widget.category} category this month to track your expenses.",
            style: TextStyle(color: c.textSecondary, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              labelText: isTotal ? AppStrings.monthlyLimit : "Category Limit",
              labelStyle: TextStyle(color: c.textSecondary),
              hintText: AppStrings.hintLimit,
              hintStyle: TextStyle(color: c.textSecondary.withAlpha(120)),
              prefixText: "₹ ",
              prefixStyle: TextStyle(color: c.textPrimary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: c.border),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        if (widget.initialBudget != null && !isTotal)
          TextButton(
            onPressed: _deleteBudget,
            child: const Text(
              "Delete",
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppStrings.cancel,
            style: TextStyle(color: c.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _saveBudget,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text(AppStrings.save, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
