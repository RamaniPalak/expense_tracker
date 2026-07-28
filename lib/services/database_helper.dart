import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'expense_service.dart';
import 'budget_service.dart';
import 'package:backend_client/backend_client.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // ValueNotifier to notify listeners of database changes
  final ValueNotifier<List<TransactionModel>> expensesNotifier = ValueNotifier([]);
  final ValueNotifier<List<BudgetModel>> budgetsNotifier = ValueNotifier([]);
  final ValueNotifier<List<BillModel>> billsNotifier = ValueNotifier([]);

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
      version: 7,
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
    if (oldVersion < 5) {
      await db.execute('''
CREATE TABLE bills (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  dueDate TEXT NOT NULL,
  endDate TEXT,
  category TEXT NOT NULL,
  isPaid INTEGER NOT NULL,
  isRecurring INTEGER NOT NULL,
  userEmail TEXT NOT NULL
)
''');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE bills ADD COLUMN endDate TEXT');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE budgets ADD COLUMN remoteId INTEGER');
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
  remoteId INTEGER,
  category $textType,
  amount $realType,
  month $intType,
  year $intType,
  userEmail $textType
  )
''');

    await db.execute('''
CREATE TABLE bills (
  id $idType,
  title $textType,
  amount $realType,
  dueDate $textType,
  endDate TEXT,
  category $textType,
  isPaid $intType,
  isRecurring $intType,
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

    // 1. Load local data immediately (Instant Load)
    expensesNotifier.value = await getExpenses(email);

    if (syncFromRemote) {
      // 2. Sync in background to avoid blocking the UI
      syncWithRemote(email).then((_) async {
        // 3. Refresh with any new remote data
        expensesNotifier.value = await getExpenses(email);
      }).catchError((e) => debugPrint("Background sync error: $e"));
    }
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
    debugPrint('DatabaseHelper: Upserting budget - Category: ${budget.category}, Amount: ${budget.amount}, Month: ${budget.month}/${budget.year}, Email: ${budget.userEmail}');
    
    final existing = await db.query(
      'budgets',
      where: 'category = ? AND userEmail = ? AND month = ? AND year = ?',
      whereArgs: [budget.category, budget.userEmail, budget.month, budget.year],
    );

    int? localId;
    int? currentRemoteId = budget.remoteId;

    if (existing.isNotEmpty) {
      localId = existing.first['id'] as int;
      currentRemoteId = currentRemoteId ?? existing.first['remoteId'] as int?;
      debugPrint('DatabaseHelper: Found existing budget row with ID: $localId. Updating...');
      await db.update(
        'budgets',
        budget.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [localId],
      );
    } else {
      debugPrint('DatabaseHelper: No existing budget row. Inserting new row...');
      localId = await db.insert('budgets', budget.toMap());
      debugPrint('DatabaseHelper: Inserted new budget row with ID: $localId');
    }

    await refreshBudgets(budget.userEmail);

    // Sync to remote in background
    final remoteEntry = BudgetEntry(
      id: currentRemoteId,
      category: budget.category,
      amount: budget.amount,
      month: budget.month,
      year: budget.year,
      userEmail: budget.userEmail,
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
          await refreshBudgets(budget.userEmail);
        }
      }).catchError((e) {
        debugPrint("Background add budget remote failed: $e");
      });
    }
  }

  Future<List<BudgetModel>> getBudgets(String? email) async {
    if (email == null) return [];
    final db = await instance.database;
    final result = await db.query(
      'budgets',
      where: 'userEmail = ?',
      whereArgs: [email],
    );
    return result.map((json) => BudgetModel.fromMap(json)).toList();
  }

  Future<void> refreshBudgets(String? email, {bool syncFromRemote = false}) async {
    if (email == null) return;
    
    // 1. Load local data immediately (Instant Load)
    final budgets = await getBudgets(email);
    debugPrint('DatabaseHelper: Loaded ${budgets.length} budgets for $email');
    for (var b in budgets) {
      debugPrint('  Budget - Category: ${b.category}, Amount: ${b.amount}, Month: ${b.month}/${b.year}, ID: ${b.id}, RemoteID: ${b.remoteId}');
    }
    budgetsNotifier.value = budgets;

    if (syncFromRemote) {
      // 2. Sync in background to avoid blocking the UI
      syncBudgetsWithRemote(email).then((_) async {
        // 3. Refresh with any new remote data
        budgetsNotifier.value = await getBudgets(email);
      }).catchError((e) => debugPrint("Background budget sync error: $e"));
    }
  }

  Future<void> syncBudgetsWithRemote(String email) async {
    try {
      final remoteEntries = await BudgetService().getBudgets(email);
      final db = await instance.database;

      for (BudgetEntry entry in remoteEntries) {
        if (entry.id == null) continue;

        // Check if this remote entry already exists locally (by remoteId or matching key)
        final existing = await db.query(
          'budgets',
          where: 'remoteId = ? OR (category = ? AND userEmail = ? AND month = ? AND year = ?)',
          whereArgs: [entry.id, entry.category, entry.userEmail, entry.month, entry.year],
        );

        if (existing.isEmpty) {
          final budget = BudgetModel(
            remoteId: entry.id,
            category: entry.category,
            amount: entry.amount,
            month: entry.month,
            year: entry.year,
            userEmail: entry.userEmail,
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
            userEmail: entry.userEmail,
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

  Future<void> deleteBudget(int id, String email) async {
    final db = await instance.database;
    
    final existing = await db.query(
      'budgets',
      columns: ['remoteId'],
      where: 'id = ?',
      whereArgs: [id],
    );
    
    int? remoteId;
    if (existing.isNotEmpty) {
      remoteId = existing.first['remoteId'] as int?;
    }

    await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshBudgets(email);

    if (remoteId != null) {
      BudgetService().deleteBudget(remoteId).catchError((e) {
        debugPrint("Background delete budget remote failed: $e");
        return false;
      });
    }
  }

  // Bill Operations
  Future<void> insertBill(BillModel bill) async {
    final db = await instance.database;
    final id = await db.insert('bills', bill.toMap());

    // Schedule notification 1 day before due date at 9 AM
    // NotificationService.scheduleBillReminder internally checks the
    // bill-reminder toggle and skips if disabled, so no extra guard needed.
    final dueDate = bill.dueDate;
    final reminderDate = DateTime(
      dueDate.year, dueDate.month, dueDate.day, 9, 0,
    ).subtract(const Duration(days: 1));

    await NotificationService.instance.scheduleBillReminder(
      id: id,
      title: 'Upcoming Bill: ${bill.title}',
      body: 'Your bill of ₹${bill.amount.toStringAsFixed(2)} is due tomorrow.',
      scheduledDate: reminderDate,
    );

    await refreshBills(bill.userEmail);
  }

  Future<List<BillModel>> getBills(String? email) async {
    if (email == null) return [];
    final db = await instance.database;
    const orderBy = 'dueDate ASC';
    final result = await db.query(
      'bills',
      where: 'userEmail = ?',
      whereArgs: [email],
      orderBy: orderBy,
    );

    return result.map((json) => BillModel.fromMap(json)).toList();
  }

  Future<void> refreshBills(String? email) async {
    if (email == null) return;
    billsNotifier.value = await getBills(email);
  }

  Future<void> deleteBill(int id, String? email) async {
    final db = await instance.database;
    await db.delete(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
    );
    await NotificationService.instance.cancelNotification(id);
    await refreshBills(email);
  }

  Future<void> updateBill(BillModel bill) async {
    final db = await instance.database;
    await db.update(
      'bills',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );

    // Reschedule the bill reminder after an edit.
    // Cancel the old one first (safe even if it never existed).
    if (bill.id != null) {
      await NotificationService.instance.cancelNotification(bill.id!);

      // Only reschedule if the bill is still unpaid
      if (!bill.isPaid) {
        final dueDate = bill.dueDate;
        final reminderDate = DateTime(
          dueDate.year, dueDate.month, dueDate.day, 9, 0,
        ).subtract(const Duration(days: 1));

        await NotificationService.instance.scheduleBillReminder(
          id: bill.id!,
          title: 'Upcoming Bill: ${bill.title}',
          body:
              'Your bill of ₹${bill.amount.toStringAsFixed(2)} is due tomorrow.',
          scheduledDate: reminderDate,
        );
      }
    }

    await refreshBills(bill.userEmail);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
