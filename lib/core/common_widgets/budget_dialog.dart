import 'package:flutter/material.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

class BudgetDialog extends StatefulWidget {
  final String? userEmail;
  final BudgetModel? initialBudget;

  const BudgetDialog({super.key, this.userEmail, this.initialBudget});

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
      category: AppStrings.total,
      amount: amount,
      month: now.month,
      year: now.year,
      userEmail: widget.userEmail!,
    );

    await sl<DatabaseHelper>().upsertBudget(budget);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.budgetPlanTitle, style: AppTextStyles.heading2),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(AppStrings.budgetPlanSub),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: AppStrings.monthlyLimit,
              hintText: AppStrings.hintLimit,
              prefixText: "₹ ",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _saveBudget,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text(AppStrings.save, style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
