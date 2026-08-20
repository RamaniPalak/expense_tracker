import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/add_contribution_dialog.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/routing/app_router.dart';

class GoalDetailScreen extends StatefulWidget {
  final GoalModel goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late GoalModel _goal;
  List<GoalContributionModel> _contributions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _loadGoalData();
  }

  Future<void> _loadGoalData() async {
    setState(() => _isLoading = true);
    try {
      final userEmail = await sl<IAuthRepository>().getUserEmail();
      if (_goal.id != null) {
        final goals = await DatabaseHelper.instance.getGoals(userEmail);
        final freshGoal = goals.firstWhere((g) => g.id == _goal.id, orElse: () => _goal);
        final logs = await DatabaseHelper.instance.getGoalContributions(_goal.id!, userEmail);

        setState(() {
          _goal = freshGoal;
          _contributions = logs;
        });
      }
    } catch (e) {
      debugPrint("Error loading goal detail: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCelebrationModal(GoalModel goal) {
    final c = context.appColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.incomeGreen.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Text('🎉', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 16),
            Text(
              'Goal Achieved!',
              style: AppTextStyles.heading1.copyWith(fontSize: 22, color: c.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Congratulations! You have saved ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(goal.targetAmount)} for "${goal.title}". Fantastic job!',
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.incomeGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Awesome! 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContribution({required bool isDeposit}) async {
    final wasCompleted = _goal.isCompleted;
    final result = await AddContributionDialog.show(context, goal: _goal, isDeposit: isDeposit);
    if (result == true) {
      await _loadGoalData();
      if (!wasCompleted && _goal.isCompleted && mounted) {
        _showCelebrationModal(_goal);
      }
    }
  }

  Future<void> _deleteContribution(GoalContributionModel log) async {
    final userEmail = await sl<IAuthRepository>().getUserEmail();
    if (log.id != null) {
      await DatabaseHelper.instance.deleteGoalContribution(
        log.id!,
        _goal.id!,
        log.amount,
        log.type,
        userEmail,
      );
      await _loadGoalData();
    }
  }

  Future<void> _togglePauseGoal() async {
    final newStatus = _goal.isPaused ? 'Active' : 'Paused';
    final updated = _goal.copyWith(status: newStatus);
    await DatabaseHelper.instance.updateGoal(updated);
    await _loadGoalData();
  }

  Future<void> _confirmDeleteGoal() async {
    final c = context.appColors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Goal?', style: AppTextStyles.heading2.copyWith(color: c.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${_goal.title}" and its contribution history?',
          style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: c.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userEmail = await sl<IAuthRepository>().getUserEmail();
      if (_goal.id != null) {
        await DatabaseHelper.instance.deleteGoal(_goal.id!, userEmail);
        if (mounted) {
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final color = Color(_goal.colorValue);
    // ignore: non_const_argument_for_const_parameter
    final iconData = IconData(_goal.iconCode, fontFamily: 'MaterialIcons');

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: c.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Goal Details', style: AppTextStyles.heading2.copyWith(fontSize: 20, color: c.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _goal.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: _goal.isPaused ? AppColors.incomeGreen : const Color(0xFFF59E0B),
            ),
            onPressed: _togglePauseGoal,
            tooltip: _goal.isPaused ? 'Resume Goal' : 'Pause Goal',
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: c.textPrimary),
            onPressed: () async {
              await context.push(RoutePaths.addEditGoal, extra: _goal);
              await _loadGoalData();
            },
            tooltip: 'Edit Goal',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed),
            onPressed: _confirmDeleteGoal,
            tooltip: 'Delete Goal',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
              children: [
                // Top Goal Summary Card with Progress Circle
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: color.withAlpha(80)),
                    boxShadow: [
                      BoxShadow(color: c.shadow, blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: color.withAlpha(35), borderRadius: BorderRadius.circular(16)),
                            child: Icon(iconData, color: color, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _goal.title.isNotEmpty
                                            ? _goal.title[0].toUpperCase() + _goal.title.substring(1)
                                            : '',
                                        style: AppTextStyles.heading2.copyWith(color: c.textPrimary, fontSize: 20),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_goal.priority == 'High')
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: AppColors.expenseRed.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('🚨 High', style: TextStyle(color: AppColors.expenseRed, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${_goal.category} • Due ${DateFormat('MMM dd, yyyy').format(_goal.targetDate)}',
                                    style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Progress Circle Stack
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value: _goal.progressPercentage,
                              strokeWidth: 12,
                              backgroundColor: c.border.withAlpha(80),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _goal.isCompleted ? AppColors.incomeGreen : color,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_goal.progressPercent100}%',
                                style: AppTextStyles.heading1.copyWith(fontSize: 28, color: c.textPrimary),
                              ),
                              Text(
                                _goal.isCompleted ? 'Goal Reached!' : '${_goal.daysRemaining} days left',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _goal.isCompleted ? AppColors.incomeGreen : c.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Balances Grid
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                              decoration: BoxDecoration(
                                color: c.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: c.border.withAlpha(60)),
                              ),
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Saved', style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary, fontSize: 12)),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(_goal.currentAmount),
                                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.incomeGreen),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                              decoration: BoxDecoration(
                                color: c.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: c.border.withAlpha(60)),
                              ),
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Remaining', style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary, fontSize: 12)),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(_goal.remainingAmount),
                                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                              decoration: BoxDecoration(
                                color: c.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: c.border.withAlpha(60)),
                              ),
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Target', style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary, fontSize: 12)),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(_goal.targetAmount),
                                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: c.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Monthly Pace Estimate Banner & Auto-deposit Info
                if (_goal.isPaused)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(25),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF59E0B).withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pause_circle_outline_rounded, color: Color(0xFFF59E0B), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Goal is currently paused. Resume to restart auto-deposits and pace tracking.',
                            style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!_goal.isCompleted && _goal.daysRemaining > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.speed_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recommended Saving Pace',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Save ₹${_goal.monthlyPace.toStringAsFixed(0)} / month to hit target on time.',
                                style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Auto-deposit settings indicator
                if (_goal.autoDepositAmount > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.incomeGreen.withAlpha(15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.incomeGreen.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.autorenew_rounded, color: AppColors.incomeGreen, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Auto-deposit active: ₹${_goal.autoDepositAmount.toStringAsFixed(0)} scheduled on day ${_goal.autoDepositDay} of every month.',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.incomeGreen, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_goal.productUrl != null && _goal.productUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _goal.productUrl!,
                            style: AppTextStyles.bodySmall.copyWith(color: c.primary, decoration: TextDecoration.underline),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          color: c.primary,
                          tooltip: 'Copy Link',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _goal.productUrl!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Product link copied to clipboard! 📋'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons (Deposit / Withdraw)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleContribution(isDeposit: true),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add Deposit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.incomeGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleContribution(isDeposit: false),
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.expenseRed),
                          label: Text('Withdraw', style: TextStyle(color: c.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.expenseRed),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Contribution Activity History
                Text('Contribution History', style: AppTextStyles.heading2.copyWith(fontSize: 18, color: c.textPrimary)),
                const SizedBox(height: 12),

                if (_contributions.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.border),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 40, color: c.textSecondary),
                          const SizedBox(height: 10),
                          Text('No deposit history yet', style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Tap "Add Deposit" above to add funds to this goal.', style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _contributions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = _contributions[index];
                      final isDeposit = log.isDeposit;

                      return Container(
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (isDeposit ? AppColors.incomeGreen : AppColors.expenseRed).withAlpha(30),
                            child: Icon(
                              isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isDeposit ? AppColors.incomeGreen : AppColors.expenseRed,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            '${isDeposit ? '+' : '-'} ₹${log.amount.toStringAsFixed(0)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDeposit ? AppColors.incomeGreen : AppColors.expenseRed,
                            ),
                          ),
                          subtitle: Text(
                            '${DateFormat('MMM dd, yyyy • hh:mm a').format(log.date)}${log.note != null ? ' • "${log.note}"' : ''}',
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: c.textSecondary),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, size: 18, color: c.textSecondary),
                            onPressed: () => _deleteContribution(log),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}
