import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/features/wallet/data/models/monthly_budget_model.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/services/budget_service.dart';
import 'package:expense_tracker/services/api_client.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:backend_client/backend_client.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';

class BudgetDao {
  final Future<Database> Function() _getDatabase;
  final ValueNotifier<List<BudgetModel>> budgetsNotifier;
  final ValueNotifier<List<MonthlyBudgetModel>> monthlyBudgetsNotifier;

  BudgetDao({
    required Future<Database> Function() getDatabase,
    ValueNotifier<List<BudgetModel>>? budgetsNotifier,
    ValueNotifier<List<MonthlyBudgetModel>>? monthlyBudgetsNotifier,
  })  : _getDatabase = getDatabase,
        budgetsNotifier = budgetsNotifier ?? ValueNotifier([]),
        monthlyBudgetsNotifier = monthlyBudgetsNotifier ?? ValueNotifier([]);

  // ── Category Budget Operations ─────────────────────────────────────────────

  Future<void> upsertBudget(BudgetModel budget) async {
    final cleanEmail = budget.userEmail.trim().toLowerCase();
    final db = await _getDatabase();

    final existing = await db.query(
      'budgets',
      where:
          'LOWER(TRIM(category)) = LOWER(TRIM(?)) AND LOWER(TRIM(userEmail)) = ? AND month = ? AND year = ?',
      whereArgs: [budget.category, cleanEmail, budget.month, budget.year],
    );

    int? localId;
    int? currentRemoteId = budget.remoteId;

    final normalizedBudget = budget.copyWith(userEmail: cleanEmail);

    if (existing.isNotEmpty) {
      localId = existing.first['id'] as int;
      currentRemoteId = currentRemoteId ?? existing.first['remoteId'] as int?;
      await db.update(
        'budgets',
        normalizedBudget.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [localId],
      );
    } else {
      localId = await db.insert('budgets', normalizedBudget.toMap());
    }

    await refreshBudgets(cleanEmail);

    final remoteEntry = BudgetEntry(
      id: currentRemoteId,
      category: normalizedBudget.category,
      amount: normalizedBudget.amount,
      month: normalizedBudget.month,
      year: normalizedBudget.year,
      userEmail: cleanEmail,
    );

    if (currentRemoteId != null) {
      BudgetService().updateBudget(remoteEntry).catchError((e) {
        debugPrint("Background update budget remote failed: $e");
        return null;
      });
    } else {
      BudgetService().addBudget(remoteEntry).then((savedRemote) async {
        if (savedRemote != null && savedRemote.id != null) {
          await db.update(
            'budgets',
            {'remoteId': savedRemote.id},
            where: 'id = ?',
            whereArgs: [localId],
          );
        }
      }).catchError(
          (e) => debugPrint("Background add budget remote failed: $e"));
    }
  }

  Future<List<BudgetModel>> getBudgets(String? email) async {
    if (email == null || email.trim().isEmpty) return [];
    final cleanEmail = email.trim().toLowerCase();
    final db = await _getDatabase();
    final result = await db.query(
      'budgets',
      where: 'LOWER(TRIM(userEmail)) = ?',
      whereArgs: [cleanEmail],
    );
    return result.map((json) => BudgetModel.fromMap(json)).toList();
  }

  Future<void> refreshBudgets(String? email,
      {bool syncFromRemote = false}) async {
    if (email == null || email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();

    final budgets = await getBudgets(cleanEmail);
    budgetsNotifier.value = budgets;

    if (syncFromRemote) {
      syncBudgetsWithRemote(cleanEmail).then((_) async {
        budgetsNotifier.value = await getBudgets(cleanEmail);
      }).catchError((e) => debugPrint("Background budget sync error: $e"));
    }
  }

  Future<void> deleteBudget(int id, String email) async {
    final db = await _getDatabase();
    final cleanEmail = email.trim().toLowerCase();

    final existing = await db.query(
      'budgets',
      columns: ['remoteId'],
      where: 'id = ?',
      whereArgs: [id],
    );
    final remoteId =
        existing.isNotEmpty ? existing.first['remoteId'] as int? : null;

    await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );

    await refreshBudgets(cleanEmail);

    if (remoteId != null) {
      BudgetService().deleteBudget(remoteId).catchError(
            (e) => debugPrint("Background delete budget remote failed: $e"),
          );
    }
  }

  Future<void> syncBudgetsWithRemote(String email) async {
    if (email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();
    try {
      final remoteEntries = await BudgetService().getBudgets(cleanEmail);
      final db = await _getDatabase();

      for (BudgetEntry entry in remoteEntries) {
        if (entry.id == null) continue;

        final existing = await db.query(
          'budgets',
          where:
              'remoteId = ? OR (LOWER(TRIM(category)) = LOWER(TRIM(?)) AND LOWER(TRIM(userEmail)) = ? AND month = ? AND year = ?)',
          whereArgs: [
            entry.id,
            entry.category,
            cleanEmail,
            entry.month,
            entry.year
          ],
        );

        if (existing.isEmpty) {
          final budget = BudgetModel(
            remoteId: entry.id,
            category: entry.category,
            amount: entry.amount,
            month: entry.month,
            year: entry.year,
            userEmail: cleanEmail,
          );
          await db.insert('budgets', budget.toMap());
        } else {
          final localId = existing.first['id'] as int;
          final budget = BudgetModel(
            id: localId,
            remoteId: entry.id,
            category: entry.category,
            amount: entry.amount,
            month: entry.month,
            year: entry.year,
            userEmail: cleanEmail,
          );
          await db.update(
            'budgets',
            budget.toMap(),
            where: 'id = ?',
            whereArgs: [localId],
          );
        }
      }
    } catch (e) {
      debugPrint('Budget Sync failed: $e');
    }
  }

  // ── Whole Month Budget Operations ──────────────────────────────────────────

  Future<void> upsertMonthlyBudget(MonthlyBudgetModel budget) async {
    final cleanEmail = budget.userEmail.trim().toLowerCase();
    final db = await _getDatabase();

    final existing = await db.query(
      'monthly_budgets',
      where: 'LOWER(TRIM(userEmail)) = ? AND month = ? AND year = ?',
      whereArgs: [cleanEmail, budget.month, budget.year],
    );

    int? localId;
    int? currentRemoteId = budget.remoteId;
    final normalizedBudget = budget.copyWith(userEmail: cleanEmail);

    if (existing.isNotEmpty) {
      localId = existing.first['id'] as int;
      currentRemoteId = currentRemoteId ?? existing.first['remoteId'] as int?;
      await db.update(
        'monthly_budgets',
        normalizedBudget.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [localId],
      );
    } else {
      localId = await db.insert('monthly_budgets', normalizedBudget.toMap());
    }

    await refreshMonthlyBudgets(cleanEmail);

    try {
      final String? resJson =
          await apiClient.client.budgetEntry.addMonthlyBudgetEntry(
        cleanEmail,
        normalizedBudget.amount,
        normalizedBudget.month,
        normalizedBudget.year,
      );
      if (resJson != null && resJson.isNotEmpty) {
        final Map<String, dynamic> res =
            jsonDecode(resJson) as Map<String, dynamic>;
        if (res['id'] != null) {
          await db.update(
            'monthly_budgets',
            {'remoteId': res['id'] as int},
            where: 'id = ?',
            whereArgs: [localId],
          );
          await refreshMonthlyBudgets(cleanEmail);
        }
      }
    } catch (e) {
      debugPrint("Background add monthly budget remote failed: $e");
    }
  }

  Future<List<MonthlyBudgetModel>> getMonthlyBudgets(String? email) async {
    if (email == null || email.trim().isEmpty) return [];
    final cleanEmail = email.trim().toLowerCase();
    final db = await _getDatabase();
    final result = await db.query(
      'monthly_budgets',
      where: 'LOWER(TRIM(userEmail)) = ?',
      whereArgs: [cleanEmail],
    );
    return result.map((json) => MonthlyBudgetModel.fromMap(json)).toList();
  }

  Future<void> refreshMonthlyBudgets(String? email,
      {bool syncFromRemote = false}) async {
    if (email == null || email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();

    final budgets = await getMonthlyBudgets(cleanEmail);
    monthlyBudgetsNotifier.value = budgets;

    if (syncFromRemote) {
      syncMonthlyBudgetsWithRemote(cleanEmail).then((_) async {
        monthlyBudgetsNotifier.value = await getMonthlyBudgets(cleanEmail);
      }).catchError(
          (e) => debugPrint("Background monthly budget sync error: $e"));
    }
  }

  Future<void> syncMonthlyBudgetsWithRemote(String email) async {
    if (email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();
    try {
      final String? jsonString = await apiClient.client.budgetEntry
          .getMonthlyBudgetEntries(cleanEmail);
      if (jsonString == null || jsonString.isEmpty) return;

      final List<dynamic> remoteEntries =
          jsonDecode(jsonString) as List<dynamic>;
      final db = await _getDatabase();

      for (var entry in remoteEntries) {
        final Map<String, dynamic> map =
            Map<String, dynamic>.from(entry as Map);
        final remoteId = map['id'] as int?;
        if (remoteId == null) continue;

        final month = (map['month'] as num).toInt();
        final year = (map['year'] as num).toInt();
        final amount = (map['amount'] as num).toDouble();

        final existing = await db.query(
          'monthly_budgets',
          where:
              'remoteId = ? OR (LOWER(TRIM(userEmail)) = ? AND month = ? AND year = ?)',
          whereArgs: [remoteId, cleanEmail, month, year],
        );

        if (existing.isEmpty) {
          final model = MonthlyBudgetModel(
            remoteId: remoteId,
            amount: amount,
            month: month,
            year: year,
            userEmail: cleanEmail,
          );
          await db.insert('monthly_budgets', model.toMap());
        } else {
          final localId = existing.first['id'] as int;
          await db.update(
            'monthly_budgets',
            {
              'remoteId': remoteId,
              'amount': amount,
            },
            where: 'id = ?',
            whereArgs: [localId],
          );
        }
      }
    } catch (e) {
      debugPrint('Monthly Budget Sync failed: $e');
    }
  }

  /// Evaluates whether the newly saved or updated expense causes the user to
  /// reach 80% or 100% of their category or overall monthly budget.
  Future<void> checkAndTriggerBudgetAlert({
    required TransactionModel expense,
    required Future<List<TransactionModel>> Function(String) getExpenses,
  }) async {
    if (expense.isIncome) return;
    try {
      final cleanEmail = expense.userEmail.trim().toLowerCase();
      final month = expense.date.month;
      final year = expense.date.year;
      final category = expense.category;

      final allBudgets = await getBudgets(cleanEmail);
      final catBudget = allBudgets.firstWhere(
        (b) => b.category == category && b.month == month && b.year == year,
        orElse: () => BudgetModel(
            category: '',
            amount: 0,
            month: month,
            year: year,
            userEmail: cleanEmail),
      );

      final totalBudget = allBudgets.firstWhere(
        (b) =>
            b.category == AppStrings.total &&
            b.month == month &&
            b.year == year,
        orElse: () => BudgetModel(
            category: '',
            amount: 0,
            month: month,
            year: year,
            userEmail: cleanEmail),
      );

      final allExpenses = await getExpenses(cleanEmail);

      // Check Category-specific budget alert
      if (catBudget.amount > 0) {
        final catSpent = allExpenses
            .where((e) =>
                !e.isIncome &&
                e.category == category &&
                e.date.month == month &&
                e.date.year == year)
            .fold(0.0, (sum, e) => sum + e.amount);

        final pct = catSpent / catBudget.amount;
        if (pct >= 1.0) {
          final title = "🚨 $category Budget Exceeded!";
          final body =
              "You spent ₹${NumberFormat('#,##0').format(catSpent)} of your ₹${NumberFormat('#,##0').format(catBudget.amount)} budget for $category.";
          await NotificationService.instance.showBudgetAlertNotification(
              title: title, body: body, userEmail: cleanEmail);
        } else if (pct >= 0.8) {
          final title =
              "⚠️ $category Budget Warning (${(pct * 100).toStringAsFixed(0)}%)";
          final body =
              "You have used ${(pct * 100).toStringAsFixed(0)}% of your $category budget (₹${NumberFormat('#,##0').format(catSpent)} / ₹${NumberFormat('#,##0').format(catBudget.amount)}).";
          await NotificationService.instance.showBudgetAlertNotification(
              title: title, body: body, userEmail: cleanEmail);
        }
      }

      // Check Overall Total Monthly budget alert
      if (totalBudget.amount > 0) {
        final totalSpent = allExpenses
            .where((e) =>
                !e.isIncome && e.date.month == month && e.date.year == year)
            .fold(0.0, (sum, e) => sum + e.amount);

        final pct = totalSpent / totalBudget.amount;
        if (pct >= 1.0) {
          final title = "🚨 Overall Monthly Budget Exceeded!";
          final body =
              "Total spending (₹${NumberFormat('#,##0').format(totalSpent)}) has exceeded your monthly limit of ₹${NumberFormat('#,##0').format(totalBudget.amount)}.";
          await NotificationService.instance.showBudgetAlertNotification(
              title: title, body: body, userEmail: cleanEmail);
        } else if (pct >= 0.8) {
          final title =
              "⚠️ Monthly Budget Warning (${(pct * 100).toStringAsFixed(0)}%)";
          final body =
              "You have reached ${(pct * 100).toStringAsFixed(0)}% of your overall monthly limit (₹${NumberFormat('#,##0').format(totalSpent)} / ₹${NumberFormat('#,##0').format(totalBudget.amount)}).";
          await NotificationService.instance.showBudgetAlertNotification(
              title: title, body: body, userEmail: cleanEmail);
        }
      }
    } catch (e) {
      debugPrint("Error checking budget alert: $e");
    }
  }
}
