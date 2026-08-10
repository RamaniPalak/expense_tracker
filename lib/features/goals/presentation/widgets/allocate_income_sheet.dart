import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:intl/intl.dart';

class AllocateIncomeSheet extends StatefulWidget {
  final double incomeAmount;
  final String incomeTitle;
  final List<GoalModel> activeGoals;

  const AllocateIncomeSheet({
    super.key,
    required this.incomeAmount,
    required this.incomeTitle,
    required this.activeGoals,
  });

  static Future<bool?> show(
    BuildContext context, {
    required double incomeAmount,
    required String incomeTitle,
    required List<GoalModel> activeGoals,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AllocateIncomeSheet(
        incomeAmount: incomeAmount,
        incomeTitle: incomeTitle,
        activeGoals: activeGoals,
      ),
    );
  }

  @override
  State<AllocateIncomeSheet> createState() => _AllocateIncomeSheetState();
}

class _AllocateIncomeSheetState extends State<AllocateIncomeSheet> {
  late GoalModel _selectedGoal;
  final _amountController = TextEditingController();
  bool _isLoading = false;
  double? _selectedPercentage;

  @override
  void initState() {
    super.initState();
    // Default to first active goal, preferably highest priority
    final sortedGoals = List<GoalModel>.from(widget.activeGoals)
      ..sort((a, b) => b.priorityWeight.compareTo(a.priorityWeight));
    _selectedGoal = sortedGoals.first;
    // Default suggestion: 10%
    _setPercentage(0.10);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setPercentage(double pct) {
    setState(() {
      _selectedPercentage = pct;
      final allocated = (widget.incomeAmount * pct);
      _amountController.text = allocated.toStringAsFixed(0);
    });
  }

  Future<void> _submitAllocation() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid allocation amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userEmail = await sl<IAuthRepository>().getUserEmail() ?? '';
      final contribution = GoalContributionModel(
        goalId: _selectedGoal.id!,
        amount: amount,
        date: DateTime.now(),
        note: 'Payday allocation from ${widget.incomeTitle}',
        type: 'deposit',
        userEmail: userEmail,
      );

      await DatabaseHelper.instance.insertGoalContribution(contribution);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully allocated ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(amount)} to "${_selectedGoal.title}"! 🎉',
            ),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
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
    final formattedIncome = NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(widget.incomeAmount);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.incomeGreen.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings_rounded, color: AppColors.incomeGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income Added! Allocate Savings?',
                      style: AppTextStyles.heading2.copyWith(fontSize: 18, color: c.textPrimary),
                    ),
                    Text(
                      'Logged $formattedIncome (${widget.incomeTitle})',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.incomeGreen, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Target Goal Selector
          Text(
            'Select Target Goal',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(16),
              color: c.background,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<GoalModel>(
                value: _selectedGoal,
                isExpanded: true,
                dropdownColor: c.surface,
                icon: Icon(Icons.arrow_drop_down_rounded, color: c.primary),
                items: widget.activeGoals.map((goal) {
                  return DropdownMenuItem<GoalModel>(
                    value: goal,
                    child: Row(
                      children: [
                        Icon(
                          // ignore: non_const_argument_for_const_parameter
                          IconData(goal.iconCode, fontFamily: 'MaterialIcons'),
                          color: Color(goal.colorValue),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            goal.title,
                            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (goal.priority == 'High')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.expenseRed.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                            child: const Text('🚨 High', style: TextStyle(color: AppColors.expenseRed, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGoal = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Quick Percentage Allocation Chips
          Text(
            'Quick Allocation Percentage',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPercentageChip(0.10, '10%'),
              const SizedBox(width: 8),
              _buildPercentageChip(0.20, '20%'),
              const SizedBox(width: 8),
              _buildPercentageChip(0.30, '30%'),
              const SizedBox(width: 8),
              _buildPercentageChip(0.50, '50%'),
            ],
          ),

          const SizedBox(height: 16),

          // Custom Amount Input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.heading1.copyWith(fontSize: 22, color: c.textPrimary),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: AppTextStyles.heading1.copyWith(fontSize: 22, color: AppColors.incomeGreen),
              hintText: '0',
              labelText: 'Allocation Amount',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onChanged: (val) {
              setState(() => _selectedPercentage = null);
            },
          ),

          const SizedBox(height: 24),

          // Buttons: Skip & Allocate
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                  child: Text('Skip for Now', style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAllocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.incomeGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Confirm Allocation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageChip(double pct, String label) {
    final c = context.appColors;
    final isSelected = _selectedPercentage == pct;
    final calcVal = NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(widget.incomeAmount * pct);

    return Expanded(
      child: GestureDetector(
        onTap: () => _setPercentage(pct),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.incomeGreen : c.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.incomeGreen : c.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : c.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  calcVal,
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : c.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
