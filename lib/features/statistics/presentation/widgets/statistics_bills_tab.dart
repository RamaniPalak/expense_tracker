import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/services/database_helper.dart';

/// Upcoming & recently paid bills tab displayed inside Statistics.
class StatisticsBillsTab extends StatelessWidget {
  final String? userEmail;

  const StatisticsBillsTab({super.key, this.userEmail});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return ValueListenableBuilder<List<BillModel>>(
      valueListenable: sl<DatabaseHelper>().billsNotifier,
      builder: (context, bills, _) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final upcoming = bills.where((b) => !b.isPaid).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        final paid = bills.where((b) => b.isPaid).toList()
          ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

        final overdueCount = upcoming
            .where((b) =>
                DateTime(b.dueDate.year, b.dueDate.month, b.dueDate.day)
                    .isBefore(today))
            .length;

        final totalDue = upcoming.fold(0.0, (sum, b) => sum + b.amount);

        return Column(
          children: [
            // Summary card
            if (upcoming.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: overdueCount > 0
                      ? const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (overdueCount > 0
                              ? const Color(0xFFE53935)
                              : AppColors.secondary)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${upcoming.length} Upcoming Bill${upcoming.length == 1 ? '' : 's'}",
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            "₹ ${totalDue.toStringAsFixed(0)}",
                            style: AppTextStyles.heading1
                                .copyWith(color: Colors.white, fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                    if (overdueCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "$overdueCount Overdue",
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Bills list
            Expanded(
              child: upcoming.isEmpty && paid.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.green.withOpacity(0.6)),
                          const SizedBox(height: 16),
                          Text("All caught up!",
                              style: AppTextStyles.heading2
                                  .copyWith(color: c.textPrimary)),
                          const SizedBox(height: 8),
                          Text("No upcoming bills",
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: c.textSecondary)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push(RoutePaths.bills),
                            icon: const Icon(Icons.add),
                            label: const Text("Add Bill"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        if (upcoming.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                              child: Text(
                                "Upcoming Payments",
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: c.textSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildBillCard(
                                    context, upcoming[index], today, false);
                              },
                              childCount: upcoming.length,
                            ),
                          ),
                        ],
                        if (paid.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                              child: Text(
                                "Recently Paid",
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: c.textSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildBillCard(
                                    context, paid[index], today, true);
                              },
                              childCount: paid.length,
                            ),
                          ),
                        ],
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                            child: OutlinedButton.icon(
                              onPressed: () => context.push(RoutePaths.bills),
                              icon: const Icon(Icons.receipt_long),
                              label: const Text("Manage All Bills"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side:
                                    const BorderSide(color: AppColors.primary),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBillCard(
      BuildContext context, BillModel bill, DateTime today, bool isPaid) {
    final c = context.appColors;
    final dueDay =
        DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day);
    final diff = dueDay.difference(today).inDays;
    final isOverdue = !isPaid && diff < 0;
    final isUrgent = !isPaid && diff <= 3;

    Color statusColor = isPaid
        ? Colors.green
        : isOverdue
            ? Colors.red
            : isUrgent
                ? Colors.orange
                : AppColors.primary;

    String dueLabel = isPaid
        ? "Paid"
        : isOverdue
            ? "Overdue by ${diff.abs()} day${diff.abs() == 1 ? '' : 's'}"
            : diff == 0
                ? "Due today"
                : "Due in $diff day${diff == 1 ? '' : 's'}";

    return GestureDetector(
      onTap: () => context.push(RoutePaths.billDetail, extra: bill),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: isOverdue
              ? Border.all(color: Colors.red.withOpacity(0.4))
              : isUrgent
                  ? Border.all(color: Colors.orange.withOpacity(0.4))
                  : null,
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPaid
                    ? Icons.check_circle
                    : isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.calendar_today,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(isPaid ? Icons.check : Icons.schedule,
                          size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        dueLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: isOverdue || isUrgent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(bill.dueDate),
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 11, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹ ${bill.amount.toStringAsFixed(0)}",
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                    fontSize: 16,
                  ),
                ),
                if (bill.isRecurring)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat, size: 11, color: c.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        "Monthly",
                        style: AppTextStyles.bodySmall
                            .copyWith(fontSize: 11, color: c.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
