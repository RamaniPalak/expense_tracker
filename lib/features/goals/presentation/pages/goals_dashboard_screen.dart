import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_card.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/add_contribution_dialog.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/routing/app_router.dart';

class GoalsDashboardScreen extends StatefulWidget {
  const GoalsDashboardScreen({super.key});

  @override
  State<GoalsDashboardScreen> createState() => _GoalsDashboardScreenState();
}

class _GoalsDashboardScreenState extends State<GoalsDashboardScreen> {
  String _activeFilter = 'All';
  final List<String> _filters = ['All', '🚨 High Priority', 'In Progress', 'Paused ⏸️', 'Completed'];
  bool _isLoading = false;
  bool _showGuide = true;

  @override
  void initState() {
    super.initState();
    _refreshGoals();
  }

  Future<void> _refreshGoals() async {
    setState(() => _isLoading = true);
    try {
      final userEmail = await sl<IAuthRepository>().getUserEmail();
      if (userEmail != null && userEmail.isNotEmpty) {
        await DatabaseHelper.instance.refreshGoals(userEmail, syncFromRemote: true);
      }
    } catch (e) {
      debugPrint("Error refreshing goals: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<GoalModel> _applyFilter(List<GoalModel> goals) {
    List<GoalModel> result = List.from(goals);

    // Auto-sort by priority (High -> Med -> Low), then deadline date
    result.sort((a, b) {
      final pComp = b.priorityWeight.compareTo(a.priorityWeight);
      if (pComp != 0) return pComp;
      return a.targetDate.compareTo(b.targetDate);
    });

    if (_activeFilter == '🚨 High Priority') {
      return result.where((g) => g.priority == 'High').toList();
    }
    if (_activeFilter == 'In Progress') {
      return result.where((g) => !g.isCompleted && !g.isPaused).toList();
    }
    if (_activeFilter == 'Paused ⏸️') {
      return result.where((g) => g.isPaused).toList();
    }
    if (_activeFilter == 'Completed') {
      return result.where((g) => g.isCompleted).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: c.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Savings Goals',
          style: AppTextStyles.heading2.copyWith(fontSize: 20, color: c.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: c.primary, size: 28),
            onPressed: () => context.push(RoutePaths.addEditGoal),
            tooltip: 'Add Goal',
          ),
        ],
      ),
      body: ValueListenableBuilder<List<GoalModel>>(
        valueListenable: DatabaseHelper.instance.goalsNotifier,
        builder: (context, goals, _) {
          if (_isLoading) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }

          final filteredGoals = _applyFilter(goals);
          final totalTarget = goals.fold<double>(0, (sum, g) => sum + g.targetAmount);
          final totalSaved = goals.fold<double>(0, (sum, g) => sum + g.currentAmount);
          final overallProgress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;
          final overallPercent = (overallProgress * 100).toInt();

          return RefreshIndicator(
            onRefresh: _refreshGoals,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
              children: [
                // Top Summary Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.cardGradientStart,
                        AppColors.cardGradientEnd,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(80),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Savings Target',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(totalSaved)} / ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(totalTarget)}',
                                    style: AppTextStyles.heading1.copyWith(
                                      color: Colors.white,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$overallPercent% Saved',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withAlpha(51),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${goals.length} Total Goals',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '${goals.where((g) => g.isCompleted).length} Completed',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_showGuide) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.primary.withAlpha(60)),
                      boxShadow: [
                        BoxShadow(color: c.shadow, blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '💡 How Savings Goals Work',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _showGuide = false),
                              child: Icon(Icons.close_rounded, size: 18, color: c.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '• Set deadlines & target amounts to get a live monthly saving recommendation.\n'
                          '• Prioritize goals (🚨 High Priority) to automatically allocate income when payday arrives.\n'
                          '• Track individual deposits and pause/resume goals anytime.',
                          style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary, height: 1.4, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final isSelected = f == _activeFilter;
                      return GestureDetector(
                        onTap: () => setState(() => _activeFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? c.primary : c.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? c.primary : c.border),
                          ),
                          child: Text(
                            f,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected ? Colors.white : c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Goals List / Empty State
                if (filteredGoals.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 40),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: c.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.savings_outlined, size: 54, color: c.primary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No Savings Goals Found',
                          style: AppTextStyles.heading2.copyWith(fontSize: 20, color: c.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Set financial targets like Emergency Fund, Buy a Car, or Vacation and track your progress easily.',
                          style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push(RoutePaths.addEditGoal),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Your First Goal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredGoals.length,
                    itemBuilder: (context, index) {
                      final goal = filteredGoals[index];
                      return GoalCard(
                        goal: goal,
                        onTap: () => context.push(RoutePaths.goalDetail, extra: goal),
                        onDepositTap: () async {
                          final res = await AddContributionDialog.show(context, goal: goal, isDeposit: true);
                          if (res == true) {
                            await _refreshGoals();
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.addEditGoal),
        backgroundColor: c.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Goal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
