import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:backend_client/backend_client.dart';

class ExpenseDao {
  final Future<Database> Function() _getDatabase;
  final ValueNotifier<List<TransactionModel>> expensesNotifier;
  final Future<void> Function(TransactionModel expense)? onExpenseSaved;
  final Future<void> Function(String email)? onExpensesRefreshed;

  ExpenseDao({
    required Future<Database> Function() getDatabase,
    ValueNotifier<List<TransactionModel>>? notifier,
    this.onExpenseSaved,
    this.onExpensesRefreshed,
  })  : _getDatabase = getDatabase,
        expensesNotifier = notifier ?? ValueNotifier([]);

  Future<int> insertExpense(TransactionModel expense) async {
    final db = await _getDatabase();
    final id = await db.insert('expenses', expense.toMap());
    await refreshExpenses(expense.userEmail);
    if (onExpenseSaved != null) {
      await onExpenseSaved!(expense.copyWith(id: id));
    }
    return id;
  }

  /// Returns true if a transaction with the same [amount], [isIncome] flag,
  /// [userEmail], and a timestamp within ±60 seconds of [date] already exists
  /// in the local DB. Used by SMS and Email sync to skip re-importing duplicates.
  Future<bool> isDuplicateTransaction({
    required double amount,
    required bool isIncome,
    required DateTime date,
    required String userEmail,
  }) async {
    final db = await _getDatabase();
    final cleanEmail = userEmail.trim().toLowerCase();

    final lowerBound =
        date.subtract(const Duration(seconds: 60)).toIso8601String();
    final upperBound = date.add(const Duration(seconds: 60)).toIso8601String();

    final result = await db.query(
      'expenses',
      columns: ['id'],
      where: 'amount = ? AND isIncome = ? AND LOWER(TRIM(userEmail)) = ? '
          'AND date >= ? AND date <= ?',
      whereArgs: [
        amount,
        isIncome ? 1 : 0,
        cleanEmail,
        lowerBound,
        upperBound,
      ],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<void> updateExpense(TransactionModel expense) async {
    final db = await _getDatabase();
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    await refreshExpenses(expense.userEmail);
    if (onExpenseSaved != null) {
      await onExpenseSaved!(expense);
    }
  }

  Future<void> updateExpenseRemoteId(int id, int remoteId) async {
    final db = await _getDatabase();
    await db.update(
      'expenses',
      {'remoteId': remoteId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int?> getExpenseRemoteId(int id) async {
    final db = await _getDatabase();
    final result = await db.query(
      'expenses',
      columns: ['remoteId'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty && result.first['remoteId'] != null) {
      return result.first['remoteId'] as int?;
    }
    return null;
  }

  Future<List<TransactionModel>> getExpenses(String? email) async {
    if (email == null || email.trim().isEmpty) return [];
    final cleanEmail = email.trim().toLowerCase();
    final db = await _getDatabase();
    const orderBy = 'date DESC';
    final result = await db.query(
      'expenses',
      where: 'LOWER(TRIM(userEmail)) = ?',
      whereArgs: [cleanEmail],
      orderBy: orderBy,
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<void> refreshExpenses(String? email,
      {bool syncFromRemote = false}) async {
    if (email == null || email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();

    expensesNotifier.value = await getExpenses(cleanEmail);
    if (onExpensesRefreshed != null) {
      await onExpensesRefreshed!(cleanEmail);
    }

    if (syncFromRemote) {
      syncWithRemote(cleanEmail).then((_) async {
        expensesNotifier.value = await getExpenses(cleanEmail);
        if (onExpensesRefreshed != null) {
          await onExpensesRefreshed!(cleanEmail);
        }
      }).catchError((e) => debugPrint("Background sync error: $e"));
    }
  }

  Future<void> syncWithRemote(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final db = await _getDatabase();
      final expenseService = ExpenseService();

      // ── Phase 1: Push pending local expenses (offline retry queue) ───────
      final unsynced = await db.query(
        'expenses',
        where: 'remoteId IS NULL AND LOWER(TRIM(userEmail)) = ?',
        whereArgs: [cleanEmail],
      );

      for (final row in unsynced) {
        final localId = row['id'] as int;
        final dateStr = row['date'] as String;
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();

        final remoteEntry = ExpenseEntry(
          title: row['title'] as String,
          amount: (row['amount'] as num).toDouble(),
          date: date,
          category: row['category'] as String,
          isIncome: (row['isIncome'] as int) == 1,
          userEmail: row['userEmail'] as String,
        );

        final savedRemote = await expenseService.addExpense(remoteEntry);
        if (savedRemote != null && savedRemote.id != null) {
          await db.update(
            'expenses',
            {'remoteId': savedRemote.id},
            where: 'id = ?',
            whereArgs: [localId],
          );
        }
      }

      // ── Phase 2: Pull remote expenses missing from local SQLite ──────────
      final remoteEntries = await expenseService.getExpenses(cleanEmail);

      for (ExpenseEntry entry in remoteEntries) {
        if (entry.id == null) continue;

        final existing = await db.query(
          'expenses',
          where: 'remoteId = ?',
          whereArgs: [entry.id],
        );

        if (existing.isEmpty) {
          final expense = TransactionModel(
            remoteId: entry.id,
            title: entry.title,
            amount: entry.amount,
            date: entry.date,
            category: entry.category,
            userEmail: entry.userEmail,
            isIncome: entry.isIncome,
          );
          await db.insert('expenses', expense.toMap());
        }
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  Future<void> deleteExpense(int id, String? email) async {
    final db = await _getDatabase();
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshExpenses(email);
  }
}
