import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'expense_service.dart';
import 'package:backend_client/backend_client.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // ValueNotifier to notify listeners of database changes
  final ValueNotifier<List<TransactionModel>> expensesNotifier = ValueNotifier([]);
  final ValueNotifier<List<BudgetModel>> budgetsNotifier = ValueNotifier([]);

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE expenses ADD COLUMN userEmail TEXT NOT NULL DEFAULT ""');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE expenses ADD COLUMN remoteId INTEGER');
    }
    if (oldVersion < 4) {
      await db.execute('''
CREATE TABLE budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  amount REAL NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  userEmail TEXT NOT NULL
)
''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE expenses ( 
  id $idType, 
  remoteId INTEGER,
  title $textType,
  amount $realType,
  date $textType,
  category $textType,
  isIncome $intType,
  userEmail $textType
  )
''');

    await db.execute('''
CREATE TABLE budgets (
  id $idType,
  category $textType,
  amount $realType,
  month $intType,
  year $intType,
  userEmail $textType
  )
''');
  }

  Future<void> insertExpense(TransactionModel expense) async {
    final db = await instance.database;
    await db.insert('expenses', expense.toMap());
    await refreshExpenses(expense.userEmail); // Update notifier
  }

  Future<List<TransactionModel>> getExpenses(String? email) async {
    if (email == null) return [];
    final db = await instance.database;
    const orderBy = 'date DESC';
    final result = await db.query(
      'expenses',
      where: 'userEmail = ?',
      whereArgs: [email],
      orderBy: orderBy,
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<void> refreshExpenses(String? email,
      {bool syncFromRemote = false}) async {
    if (email == null) return;

    if (syncFromRemote) {
      await syncWithRemote(email);
    }

    expensesNotifier.value = await getExpenses(email);
  }

  Future<void> syncWithRemote(String email) async {
    try {
      final remoteEntries = await ExpenseService().getExpenses(email);
      final db = await instance.database;

      for (ExpenseEntry entry in remoteEntries) {
        if (entry.id == null) continue;

        // Check if this remote entry already exists locally
        final existing = await db.query(
          'expenses',
          where: 'remoteId = ?',
          whereArgs: [entry.id],
        );

        if (existing.isEmpty) {
          // Insert missing remote entry into local DB
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
    final db = await instance.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshExpenses(email);
  }

  Future<void> updateExpense(TransactionModel expense) async {
    final db = await instance.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    await refreshExpenses(expense.userEmail);
  }

  // Budget Operations
  Future<void> upsertBudget(BudgetModel budget) async {
    final db = await instance.database;
    // For recurring budgets, we treat category+user as the unique key
    final existing = await db.query(
      'budgets',
      where: 'category = ? AND userEmail = ?',
      whereArgs: [budget.category, budget.userEmail],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'budgets',
        budget.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('budgets', budget.toMap());
    }
    await refreshBudgets(budget.userEmail);
  }

  Future<List<BudgetModel>> getBudgets(String? email) async {
    if (email == null) return [];
    final db = await instance.database;
    // Get all budgets for this user (each category has one master budget)
    final result = await db.query(
      'budgets',
      where: 'userEmail = ?',
      whereArgs: [email],
    );
    return result.map((json) => BudgetModel.fromMap(json)).toList();
  }

  Future<void> refreshBudgets(String? email) async {
    if (email == null) return;
    budgetsNotifier.value = await getBudgets(email);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
