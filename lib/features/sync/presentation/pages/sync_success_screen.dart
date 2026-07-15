import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class SyncSuccessScreen extends StatefulWidget {
  final int importedCount;
  const SyncSuccessScreen({super.key, required this.importedCount});

  @override
  State<SyncSuccessScreen> createState() => _SyncSuccessScreenState();
}

class _SyncSuccessScreenState extends State<SyncSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Demo breakdown
  int get _expenseCount => (widget.importedCount * 0.75).round();
  int get _incomeCount => widget.importedCount - _expenseCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated check circle
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.cardGradientStart,
                        AppColors.cardGradientEnd,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(100),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      '${widget.importedCount} Transactions Imported!',
                      style: AppTextStyles.heading2.copyWith(fontSize: 22, color: c.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your transactions have been saved successfully.',
                      style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Breakdown card
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: c.shadow,
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _BreakdownTile(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Expenses',
                          count: _expenseCount,
                          color: AppColors.expenseRed,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: c.divider,
                      ),
                      Expanded(
                        child: _BreakdownTile(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Income',
                          count: _incomeCount,
                          color: AppColors.incomeGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // View Transactions Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    context.go(RoutePaths.allTransactions);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'View Transactions',
                    style: AppTextStyles.buttonText.copyWith(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Back to home
              TextButton(
                onPressed: () => context.go(RoutePaths.home),
                child: Text(
                  'Back to Home',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: c.primary,
                    fontWeight: FontWeight.w600,
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

class _BreakdownTile extends StatelessWidget {
  const _BreakdownTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: AppTextStyles.bodyLarge.copyWith(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
      ],
    );
  }
}
