import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

class AddContributionDialog extends StatefulWidget {
  final GoalModel goal;
  final bool isDeposit;

  const AddContributionDialog({
    super.key,
    required this.goal,
    this.isDeposit = true,
  });

  static Future<bool?> show(BuildContext context, {required GoalModel goal, bool isDeposit = true}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AddContributionDialog(goal: goal, isDeposit: isDeposit),
    );
  }

  @override
  State<AddContributionDialog> createState() => _AddContributionDialogState();
}

class _AddContributionDialogState extends State<AddContributionDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildPresetChip(String amountVal, {String? label}) {
    final isDeposit = widget.isDeposit;
    final color = isDeposit ? AppColors.incomeGreen : AppColors.expenseRed;
    final displayLabel = label ?? (isDeposit ? '+₹$amountVal' : '-₹$amountVal');

    return ActionChip(
      label: Text(
        displayLabel,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      backgroundColor: color.withAlpha(20),
      side: BorderSide(color: color.withAlpha(80)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: () {
        setState(() {
          _amountController.text = amountVal;
        });
      },
    );
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount')),
      );
      return;
    }

    if (!widget.isDeposit && amount > widget.goal.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot withdraw ₹${amount.toStringAsFixed(0)}. Current saved balance is ₹${widget.goal.currentAmount.toStringAsFixed(0)}.',
          ),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userEmail = await sl<IAuthRepository>().getUserEmail() ?? '';
      final contribution = GoalContributionModel(
        goalId: widget.goal.id!,
        amount: amount,
        date: DateTime.now(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        type: widget.isDeposit ? 'deposit' : 'withdrawal',
        userEmail: userEmail,
      );

      await DatabaseHelper.instance.insertGoalContribution(contribution);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDeposit = widget.isDeposit;

    return AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDeposit ? AppColors.incomeGreen : AppColors.expenseRed).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDeposit ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isDeposit ? AppColors.incomeGreen : AppColors.expenseRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isDeposit ? 'Deposit to Goal' : 'Withdraw from Goal',
              style: AppTextStyles.heading2.copyWith(fontSize: 18, color: c.textPrimary),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.goal.title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: AppTextStyles.heading1.copyWith(fontSize: 24, color: c.textPrimary),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: AppTextStyles.heading1.copyWith(fontSize: 24, color: c.primary),
              hintText: '0.00',
              labelText: 'Amount',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 10),
          // Quick Preset Deposit Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip('500'),
                const SizedBox(width: 6),
                _buildPresetChip('1000'),
                const SizedBox(width: 6),
                _buildPresetChip('5000'),
                const SizedBox(width: 6),
                _buildPresetChip('10000'),
                if (isDeposit && widget.goal.remainingAmount > 0) ...[
                  const SizedBox(width: 6),
                  _buildPresetChip(
                    widget.goal.remainingAmount.toStringAsFixed(0),
                    label: 'Remaining (₹${widget.goal.remainingAmount.toStringAsFixed(0)})',
                  ),
                ],
                if (!isDeposit && widget.goal.currentAmount > 0) ...[
                  const SizedBox(width: 6),
                  _buildPresetChip(
                    widget.goal.currentAmount.toStringAsFixed(0),
                    label: 'Withdraw All (₹${widget.goal.currentAmount.toStringAsFixed(0)})',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              hintText: isDeposit ? 'e.g. Monthly savings bonus' : 'e.g. Emergency expense',
              prefixIcon: const Icon(Icons.note_alt_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDeposit ? AppColors.incomeGreen : AppColors.expenseRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(isDeposit ? 'Add Deposit' : 'Withdraw'),
        ),
      ],
    );
  }
}
