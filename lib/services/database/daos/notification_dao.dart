import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/notifications/data/models/app_notification_model.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/features/wallet/data/models/monthly_budget_model.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';

class NotificationDao {
  final Future<Database> Function() _getDatabase;
  final ValueNotifier<List<AppNotificationModel>> notificationsNotifier;

  NotificationDao({
    required Future<Database> Function() getDatabase,
    ValueNotifier<List<AppNotificationModel>>? notifier,
  })  : _getDatabase = getDatabase,
        notificationsNotifier = notifier ?? ValueNotifier([]);

  Future<List<AppNotificationModel>> getNotifications(String? userEmail) async {
    final db = await _getDatabase();
    final email = userEmail ?? '';
    final result = await db.query(
      'notifications',
      where: 'userEmail = ? OR userEmail = ""',
      whereArgs: [email],
      orderBy: 'timestamp DESC',
    );
    final list =
        result.map((json) => AppNotificationModel.fromMap(json)).toList();
    notificationsNotifier.value = list;
    return list;
  }

  Future<void> refreshNotifications(String? userEmail) async {
    await getNotifications(userEmail);
  }

  Future<void> insertNotification(AppNotificationModel notification) async {
    final db = await _getDatabase();
    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await refreshNotifications(notification.userEmail);
  }

  Future<void> markNotificationAsRead(String id, String? userEmail) async {
    final db = await _getDatabase();
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshNotifications(userEmail);
  }

  Future<void> markAllNotificationsAsRead(String? userEmail) async {
    final db = await _getDatabase();
    final email = userEmail ?? '';
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'userEmail = ? OR userEmail = ""',
      whereArgs: [email],
    );
    await refreshNotifications(userEmail);
  }

  Future<void> deleteNotification(String id, String? userEmail) async {
    final db = await _getDatabase();
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshNotifications(userEmail);
  }

  Future<void> clearAllNotifications(String? userEmail) async {
    final db = await _getDatabase();
    final email = userEmail ?? '';
    await db.delete(
      'notifications',
      where: 'userEmail = ? OR userEmail = ""',
      whereArgs: [email],
    );
    await refreshNotifications(userEmail);
  }

  /// Automatically syncs/evaluates app state (upcoming bills, budget warnings, goal achievements, check-ins)
  /// and updates the notification list so the user always has up-to-date notification insights and system tray alerts.
  Future<void> syncNotifications(String? userEmail) async {
    if (userEmail == null || userEmail.trim().isEmpty) return;
    final email = userEmail.trim().toLowerCase();
    final now = DateTime.now();
    final db = await _getDatabase();

    // 1. Check Unpaid Upcoming / Overdue Bills
    final billsResult = await db.query(
      'bills',
      where: 'LOWER(TRIM(userEmail)) = ? OR userEmail = "" AND isPaid = 0',
      whereArgs: [email],
    );
    final bills = billsResult.map((m) => BillModel.fromMap(m)).toList();
    for (var bill in bills) {
      final diff = bill.dueDate.difference(now).inDays;
      if (diff <= 7 && diff >= -30) {
        final notifId =
            'bill_${bill.id}_${bill.dueDate.year}_${bill.dueDate.month}_${bill.dueDate.day}';
        final existing = await db
            .query('notifications', where: 'id = ?', whereArgs: [notifId]);

        final status = diff < 0
            ? 'Overdue'
            : (diff == 0
                ? 'Due Today'
                : 'Due in $diff day${diff > 1 ? "s" : ""}');
        final title = 'Bill Reminder: ${bill.title}';
        final desc =
            'Your ${bill.category} bill of ₹${NumberFormat('#,##0').format(bill.amount)} is $status (${bill.dueDate.day}/${bill.dueDate.month}/${bill.dueDate.year}).';

        await db.insert(
          'notifications',
          AppNotificationModel(
            id: notifId,
            title: title,
            description: desc,
            timestamp: bill.dueDate.isBefore(now) ? now : bill.dueDate,
            type: NotificationType.bill,
            actionRoute: '/bills',
            userEmail: email,
          ).toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        if (existing.isEmpty) {
          NotificationService.instance.showBudgetAlertNotification(
            title: title,
            body: desc,
            userEmail: email,
          );
        }
      }
    }

    // 2. Per-Category Budget Threshold Alerts
    final month = now.month;
    final year = now.year;
    final budgetResult = await db.query(
      'budgets',
      where:
          '(LOWER(TRIM(userEmail)) = ? OR userEmail = "") AND month = ? AND year = ?',
      whereArgs: [email, month, year],
    );
    final budgets = budgetResult.map((m) => BudgetModel.fromMap(m)).toList();

    if (budgets.isNotEmpty) {
      final expResult = await db.query(
        'expenses',
        where: 'LOWER(TRIM(userEmail)) = ? OR userEmail = ""',
        whereArgs: [email],
      );
      final expenses =
          expResult.map((m) => TransactionModel.fromMap(m)).toList();

      for (var budget in budgets) {
        if (budget.category.trim().toLowerCase() ==
            AppStrings.total.toLowerCase()) {
          continue;
        }
        if (budget.amount <= 0) {
          continue;
        }

        final catSpent = expenses
            .where((e) =>
                !e.isIncome &&
                e.category.trim().toLowerCase() ==
                    budget.category.trim().toLowerCase() &&
                e.date.month == month &&
                e.date.year == year)
            .fold(0.0, (sum, e) => sum + e.amount);

        final pct = (catSpent / budget.amount) * 100;

        if (pct >= 100) {
          final notifId = 'budget_exceeded_${budget.category}_${year}_$month';
          final title = '🚨 Budget Exceeded: ${budget.category}';
          final desc =
              'You spent ₹${NumberFormat('#,##0').format(catSpent)}, exceeding your '
              '${budget.category} budget of ₹${NumberFormat('#,##0').format(budget.amount)} '
              'by ₹${NumberFormat('#,##0').format(catSpent - budget.amount)}.';

          final existing = await db
              .query('notifications', where: 'id = ?', whereArgs: [notifId]);

          await db.insert(
            'notifications',
            AppNotificationModel(
              id: notifId,
              title: title,
              description: desc,
              timestamp: now,
              type: NotificationType.budget,
              actionRoute: '/statistics',
              userEmail: email,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          if (existing.isEmpty) {
            NotificationService.instance.showBudgetAlertNotification(
              title: title,
              body: desc,
              userEmail: email,
            );
          }
        } else if (pct >= 80) {
          final notifId = 'budget_warn_${budget.category}_${year}_$month';
          final title =
              '⚠️ Budget Warning: ${budget.category} (${pct.toStringAsFixed(0)}%)';
          final desc = 'You have used ${pct.toStringAsFixed(0)}% of your '
              '₹${NumberFormat('#,##0').format(budget.amount)} ${budget.category} budget '
              '(₹${NumberFormat('#,##0').format(catSpent)} spent).';

          final existing = await db
              .query('notifications', where: 'id = ?', whereArgs: [notifId]);

          await db.insert(
            'notifications',
            AppNotificationModel(
              id: notifId,
              title: title,
              description: desc,
              timestamp: now,
              type: NotificationType.budget,
              actionRoute: '/statistics',
              userEmail: email,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          if (existing.isEmpty) {
            NotificationService.instance.showBudgetAlertNotification(
              title: title,
              body: desc,
              userEmail: email,
            );
          }
        }
      }
    }

    // 2b. Overall Monthly Budget Threshold Alert (from monthly_budgets table)
    final monthlyBudgetResult = await db.query(
      'monthly_budgets',
      where:
          '(LOWER(TRIM(userEmail)) = ? OR userEmail = "") AND month = ? AND year = ?',
      whereArgs: [email, month, year],
    );
    if (monthlyBudgetResult.isNotEmpty) {
      final monthlyBudget =
          MonthlyBudgetModel.fromMap(monthlyBudgetResult.first);
      if (monthlyBudget.amount > 0) {
        final expResult = await db.query(
          'expenses',
          where: 'LOWER(TRIM(userEmail)) = ? OR userEmail = ""',
          whereArgs: [email],
        );
        final totalSpent = expResult
            .map((m) => TransactionModel.fromMap(m))
            .where((e) =>
                !e.isIncome && e.date.month == month && e.date.year == year)
            .fold(0.0, (sum, e) => sum + e.amount);

        final pct = (totalSpent / monthlyBudget.amount) * 100;

        if (pct >= 100) {
          final notifId = 'monthly_budget_exceeded_${year}_$month';
          final title = '🚨 Monthly Budget Exceeded!';
          final desc =
              'Total spending ₹${NumberFormat('#,##0').format(totalSpent)} has exceeded '
              'your monthly limit of ₹${NumberFormat('#,##0').format(monthlyBudget.amount)} '
              'by ₹${NumberFormat('#,##0').format(totalSpent - monthlyBudget.amount)}.';

          final existing = await db
              .query('notifications', where: 'id = ?', whereArgs: [notifId]);

          await db.insert(
            'notifications',
            AppNotificationModel(
              id: notifId,
              title: title,
              description: desc,
              timestamp: now,
              type: NotificationType.budget,
              actionRoute: '/statistics',
              userEmail: email,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          if (existing.isEmpty) {
            NotificationService.instance.showBudgetAlertNotification(
              title: title,
              body: desc,
              userEmail: email,
            );
          }
        } else if (pct >= 80) {
          final notifId = 'monthly_budget_warn_${year}_$month';
          final title =
              '⚠️ Monthly Budget Warning (${pct.toStringAsFixed(0)}%)';
          final desc =
              'You have used ${pct.toStringAsFixed(0)}% of your monthly budget. '
              '₹${NumberFormat('#,##0').format(totalSpent)} spent of '
              '₹${NumberFormat('#,##0').format(monthlyBudget.amount)}.';

          final existing = await db
              .query('notifications', where: 'id = ?', whereArgs: [notifId]);

          await db.insert(
            'notifications',
            AppNotificationModel(
              id: notifId,
              title: title,
              description: desc,
              timestamp: now,
              type: NotificationType.budget,
              actionRoute: '/statistics',
              userEmail: email,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          if (existing.isEmpty) {
            NotificationService.instance.showBudgetAlertNotification(
              title: title,
              body: desc,
              userEmail: email,
            );
          }
        }
      }
    }

    // 3. Check Goals Progress
    final goalsResult = await db.query(
      'goals',
      where: 'LOWER(TRIM(userEmail)) = ? OR userEmail = ""',
      whereArgs: [email],
    );
    final goals = goalsResult.map((m) => GoalModel.fromMap(m)).toList();
    for (var goal in goals) {
      if (goal.targetAmount > 0) {
        final pct = (goal.currentAmount / goal.targetAmount) * 100;
        if (pct >= 25) {
          String milestoneKey = '25';
          String title = 'Goal Milestone 🌱: ${goal.title}';
          String desc =
              'Strong start! You reached ${pct.toStringAsFixed(0)}% of your savings goal of ₹${NumberFormat('#,##0').format(goal.targetAmount)}.';

          if (pct >= 100) {
            milestoneKey = '100';
            title = 'Goal Achieved 🎉: ${goal.title}';
            desc =
                'Congratulations! You reached 100% of your savings goal of ₹${NumberFormat('#,##0').format(goal.targetAmount)}!';
          } else if (pct >= 75) {
            milestoneKey = '75';
            title = 'Goal Milestone 🔥: ${goal.title}';
            desc =
                'You are ${pct.toStringAsFixed(0)}% of the way to achieving your goal of ₹${NumberFormat('#,##0').format(goal.targetAmount)}!';
          } else if (pct >= 50) {
            milestoneKey = '50';
            title = 'Goal Milestone 🎯: ${goal.title}';
            desc =
                'Great job! You reached ${pct.toStringAsFixed(0)}% of your savings goal of ₹${NumberFormat('#,##0').format(goal.targetAmount)}.';
          }

          final notifId = 'goal_${goal.id}_$milestoneKey';
          final existing = await db
              .query('notifications', where: 'id = ?', whereArgs: [notifId]);

          final notifModel = AppNotificationModel(
            id: notifId,
            title: title,
            description: desc,
            timestamp: now,
            type: NotificationType.goal,
            actionRoute: '/goals',
            userEmail: email,
          );

          await db.insert(
            'notifications',
            notifModel.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          if (existing.isEmpty) {
            NotificationService.instance.showBudgetAlertNotification(
              title: title,
              body: desc,
              userEmail: email,
            );
          }
        }
      }
    }

    // 4. Daily Reminder & Welcome Check
    final existingNotifs = await db.query(
      'notifications',
      where: 'userEmail = ? OR userEmail = ""',
      whereArgs: [email],
    );

    if (existingNotifs.isEmpty) {
      final safeEmailPrefix = email.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      // Seed Welcome Notification
      await db.insert(
        'notifications',
        AppNotificationModel(
          id: 'welcome_$safeEmailPrefix',
          title: 'Welcome to Expense Tracker 👋',
          description:
              'Track your spending, manage bills, and hit your savings goals effortlessly. Tap the notification bell anytime to review your alerts!',
          timestamp: now.subtract(const Duration(minutes: 5)),
          type: NotificationType.system,
          userEmail: email,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await db.insert(
        'notifications',
        AppNotificationModel(
          id: 'daily_checkin_$safeEmailPrefix',
          title: 'Daily Expense Check-In 💰',
          description:
              'Don\'t forget to log today\'s expenses to keep your monthly budget and reports accurate!',
          timestamp: now,
          type: NotificationType.reminder,
          actionRoute: '/add-expense',
          userEmail: email,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await getNotifications(email);
  }
}
