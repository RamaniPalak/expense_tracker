import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/notifications/data/models/app_notification_model.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'expense_service.dart';
import 'budget_service.dart';
import 'goal_service.dart';
import 'package:backend_client/backend_client.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // ValueNotifiers to notify listeners of database changes
  final ValueNotifier<List<TransactionModel>> expensesNotifier = ValueNotifier([]);
  final ValueNotifier<List<BudgetModel>> budgetsNotifier = ValueNotifier([]);
  final ValueNotifier<List<BillModel>> billsNotifier = ValueNotifier([]);
  final ValueNotifier<List<CategoryModel>> categoriesNotifier = ValueNotifier([]);
  final ValueNotifier<List<GoalModel>> goalsNotifier = ValueNotifier([]);
  final ValueNotifier<List<AppNotificationModel>> notificationsNotifier = ValueNotifier([]);

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
      version: 12,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db
          .execute('ALTER TABLE expenses ADD COLUMN userEmail TEXT NOT NULL DEFAULT ""');
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
    if (oldVersion < 8) {
      await db.execute('''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  emoji TEXT NOT NULL,
  iconCode INTEGER NOT NULL,
  colorValue INTEGER NOT NULL,
  isIncome INTEGER NOT NULL,
  isDefault INTEGER NOT NULL,
  userEmail TEXT NOT NULL
)
''');
    }
    if (oldVersion < 9) {
      await db.execute('''
CREATE TABLE goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  targetAmount REAL NOT NULL,
  currentAmount REAL NOT NULL DEFAULT 0.0,
  targetDate TEXT NOT NULL,
  iconCode INTEGER NOT NULL,
  colorValue INTEGER NOT NULL,
  category TEXT NOT NULL,
  userEmail TEXT NOT NULL
)
''');
      await db.execute('''
CREATE TABLE goal_contributions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  goalId INTEGER NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  note TEXT,
  type TEXT NOT NULL,
  userEmail TEXT NOT NULL
)
''');
    }
    if (oldVersion < 10) {
      await db.execute(
          "ALTER TABLE goals ADD COLUMN priority TEXT NOT NULL DEFAULT 'Medium'");
      await db
          .execute("ALTER TABLE goals ADD COLUMN status TEXT NOT NULL DEFAULT 'Active'");
      await db.execute("ALTER TABLE goals ADD COLUMN productUrl TEXT");
      await db.execute("ALTER TABLE goals ADD COLUMN autoDepositAmount REAL DEFAULT 0.0");
      await db.execute("ALTER TABLE goals ADD COLUMN autoDepositDay INTEGER DEFAULT 1");
    }
    if (oldVersion < 11) {
      await db.execute("ALTER TABLE goals ADD COLUMN remoteId INTEGER");
      await db.execute("ALTER TABLE goal_contributions ADD COLUMN remoteId INTEGER");
    }
    if (oldVersion < 12) {
      await db.execute('''
CREATE TABLE notifications (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  type TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  isRead INTEGER NOT NULL DEFAULT 0,
  actionRoute TEXT,
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

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  emoji $textType,
  iconCode $intType,
  colorValue $intType,
  isIncome $intType,
  isDefault $intType,
  userEmail $textType
  )
''');

    await db.execute('''
CREATE TABLE goals (
  id $idType,
  remoteId INTEGER,
  title $textType,
  targetAmount $realType,
  currentAmount REAL NOT NULL DEFAULT 0.0,
  targetDate $textType,
  iconCode $intType,
  colorValue $intType,
  category $textType,
  userEmail $textType,
  priority TEXT NOT NULL DEFAULT 'Medium',
  status TEXT NOT NULL DEFAULT 'Active',
  productUrl TEXT,
  autoDepositAmount REAL DEFAULT 0.0,
  autoDepositDay INTEGER DEFAULT 1
  )
''');

    await db.execute('''
CREATE TABLE goal_contributions (
  id $idType,
  remoteId INTEGER,
  goalId $intType,
  amount $realType,
  date $textType,
  note TEXT,
  type $textType,
  userEmail $textType
  )
''');

    await db.execute('''
CREATE TABLE notifications (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  type TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  isRead INTEGER NOT NULL DEFAULT 0,
  actionRoute TEXT,
  userEmail TEXT NOT NULL
  )
''');
  }

  // ── Category Operations & Defaults Seeding ──────────────────────────────────

  static final List<Map<String, dynamic>> _defaultExpenseCategories = [
    {
      "name": "Automobile / Car",
      "emoji": "🚗",
      "iconCode": Icons.directions_car_filled_rounded.codePoint,
      "colorValue": 0xFFEF4444
    },
    {
      "name": "Bills / Utilities",
      "emoji": "🔌",
      "iconCode": Icons.electrical_services_rounded.codePoint,
      "colorValue": 0xFF06B6D4
    },
    {
      "name": "Charges / Fees",
      "emoji": "🏛️",
      "iconCode": Icons.account_balance_rounded.codePoint,
      "colorValue": 0xFF84CC16
    },
    {
      "name": "Education",
      "emoji": "📚",
      "iconCode": Icons.school_rounded.codePoint,
      "colorValue": 0xFFEC4899
    },
    {
      "name": "Entertainment",
      "emoji": "🎭",
      "iconCode": Icons.theater_comedy_rounded.codePoint,
      "colorValue": 0xFF10B981
    },
    {
      "name": "Food & Dining",
      "emoji": "🍔",
      "iconCode": Icons.fastfood_rounded.codePoint,
      "colorValue": 0xFFF59E0B
    },
    {
      "name": "Gifts & Similar",
      "emoji": "🎁",
      "iconCode": Icons.card_giftcard_rounded.codePoint,
      "colorValue": 0xFF0EA5E9
    },
    {
      "name": "Health & Fitness",
      "emoji": "💪",
      "iconCode": Icons.fitness_center_rounded.codePoint,
      "colorValue": 0xFF8B5CF6
    },
    {
      "name": "Housing",
      "emoji": "🏠",
      "iconCode": Icons.home_rounded.codePoint,
      "colorValue": 0xFFF97316
    },
    {
      "name": "Subscriptions",
      "emoji": "📱",
      "iconCode": Icons.phonelink_setup_rounded.codePoint,
      "colorValue": 0xFF3B82F6
    },
    {
      "name": "Travel",
      "emoji": "✈️",
      "iconCode": Icons.flight_takeoff_rounded.codePoint,
      "colorValue": 0xFF0EA5E9
    },
    {
      "name": "Other",
      "emoji": "🧩",
      "iconCode": Icons.category_rounded.codePoint,
      "colorValue": 0xFF64748B
    },
  ];

  static final List<Map<String, dynamic>> _defaultIncomeCategories = [
    {
      "name": "Bonus",
      "emoji": "🌈",
      "iconCode": Icons.celebration_rounded.codePoint,
      "colorValue": 0xFFF43F5E
    },
    {
      "name": "Commission",
      "emoji": "🎉",
      "iconCode": Icons.percent_rounded.codePoint,
      "colorValue": 0xFF06B6D4
    },
    {
      "name": "Interest",
      "emoji": "🌱",
      "iconCode": Icons.trending_up_rounded.codePoint,
      "colorValue": 0xFF22C55E
    },
    {
      "name": "Investments",
      "emoji": "🚀",
      "iconCode": Icons.rocket_launch_rounded.codePoint,
      "colorValue": 0xFFEAB308
    },
    {
      "name": "Received from Others",
      "emoji": "📦",
      "iconCode": Icons.inventory_2_rounded.codePoint,
      "colorValue": 0xFF6366F1
    },
    {
      "name": "Rental Income",
      "emoji": "🛏️",
      "iconCode": Icons.home_rounded.codePoint,
      "colorValue": 0xFFF97316
    },
    {
      "name": "Salary",
      "emoji": "💼",
      "iconCode": Icons.work_rounded.codePoint,
      "colorValue": 0xFF22C55E
    },
    {
      "name": "Selling Assets",
      "emoji": "💰",
      "iconCode": Icons.monetization_on_rounded.codePoint,
      "colorValue": 0xFF0EA5E9
    },
    {
      "name": "Other",
      "emoji": "🧩",
      "iconCode": Icons.category_rounded.codePoint,
      "colorValue": 0xFF64748B
    },
  ];

  Future<void> _ensureCategoriesSeeded(String email) async {
    final db = await instance.database;
    final existing =
        await db.query('categories', where: 'userEmail = ?', whereArgs: [email]);
    if (existing.isEmpty) {
      // Seed expense default categories
      for (var cat in _defaultExpenseCategories) {
        await db.insert('categories', {
          'name': cat['name'],
          'emoji': cat['emoji'],
          'iconCode': cat['iconCode'],
          'colorValue': cat['colorValue'],
          'isIncome': 0,
          'isDefault': 1,
          'userEmail': email,
        });
      }
      // Seed income default categories
      for (var cat in _defaultIncomeCategories) {
        await db.insert('categories', {
          'name': cat['name'],
          'emoji': cat['emoji'],
          'iconCode': cat['iconCode'],
          'colorValue': cat['colorValue'],
          'isIncome': 1,
          'isDefault': 1,
          'userEmail': email,
        });
      }
    }
  }

  Future<List<CategoryModel>> getCategories(String? email,
      {required bool isIncome}) async {
    if (email == null || email.trim().isEmpty) return [];
    final cleanEmail = email.trim().toLowerCase();
    await _ensureCategoriesSeeded(cleanEmail);
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'LOWER(TRIM(userEmail)) = ? AND isIncome = ?',
      whereArgs: [cleanEmail, isIncome ? 1 : 0],
      orderBy: 'isDefault DESC, id ASC',
    );
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<void> refreshCategories(String? email) async {
    if (email == null || email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();
    await _ensureCategoriesSeeded(cleanEmail);
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'LOWER(TRIM(userEmail)) = ?',
      whereArgs: [cleanEmail],
      orderBy: 'isDefault DESC, id ASC',
    );
    categoriesNotifier.value = result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<void> insertCategory(CategoryModel category) async {
    final db = await instance.database;
    await db.insert('categories', category.toMap());
    await refreshCategories(category.userEmail);
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await instance.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    await refreshCategories(category.userEmail);
  }

  Future<void> deleteCategory(int id, String? email) async {
    final db = await instance.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshCategories(email);
  }

  // ── Expense Operations ──────────────────────────────────────────────────────

  Future<void> insertExpense(TransactionModel expense) async {
    final db = await instance.database;
    await db.insert('expenses', expense.toMap());
    await refreshExpenses(expense.userEmail);
    await _checkAndTriggerBudgetAlert(expense);
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
    await _checkAndTriggerBudgetAlert(expense);
  }

  Future<void> _checkAndTriggerBudgetAlert(TransactionModel expense) async {
    if (expense.isIncome) return;
    try {
      final cleanEmail = expense.userEmail.trim().toLowerCase();
      final month = expense.date.month;
      final year = expense.date.year;
      final category = expense.category;

      final allBudgets = await getBudgets(cleanEmail);
      final catBudget = allBudgets.firstWhere(
        (b) => b.category == category && b.month == month && b.year == year,
        orElse: () => BudgetModel(category: '', amount: 0, month: month, year: year, userEmail: cleanEmail),
      );

      final totalBudget = allBudgets.firstWhere(
        (b) => b.category == AppStrings.total && b.month == month && b.year == year,
        orElse: () => BudgetModel(category: '', amount: 0, month: month, year: year, userEmail: cleanEmail),
      );

      final allExpenses = await getExpenses(cleanEmail);

      // Check Category-specific budget alert
      if (catBudget.amount > 0) {
        final catSpent = allExpenses
            .where((e) => !e.isIncome && e.category == category && e.date.month == month && e.date.year == year)
            .fold(0.0, (sum, e) => sum + e.amount);

        final pct = catSpent / catBudget.amount;
        if (pct >= 1.0) {
          final title = "🚨 $category Budget Exceeded!";
          final body = "You spent ₹${NumberFormat('#,##0').format(catSpent)} of your ₹${NumberFormat('#,##0').format(catBudget.amount)} budget for $category.";
          await NotificationService().showBudgetAlertNotification(title: title, body: body, userEmail: cleanEmail);
        } else if (pct >= 0.8) {
          final title = "⚠️ $category Budget Warning (${(pct * 100).toStringAsFixed(0)}%)";
          final body = "You have used ${(pct * 100).toStringAsFixed(0)}% of your $category budget (₹${NumberFormat('#,##0').format(catSpent)} / ₹${NumberFormat('#,##0').format(catBudget.amount)}).";
          await NotificationService().showBudgetAlertNotification(title: title, body: body, userEmail: cleanEmail);
        }
      }

      // Check Overall Total Monthly budget alert
      if (totalBudget.amount > 0) {
        final totalSpent = allExpenses
            .where((e) => !e.isIncome && e.date.month == month && e.date.year == year)
            .fold(0.0, (sum, e) => sum + e.amount);

        final pct = totalSpent / totalBudget.amount;
        if (pct >= 1.0) {
          final title = "🚨 Overall Monthly Budget Exceeded!";
          final body = "Total spending (₹${NumberFormat('#,##0').format(totalSpent)}) has exceeded your monthly limit of ₹${NumberFormat('#,##0').format(totalBudget.amount)}.";
          await NotificationService().showBudgetAlertNotification(title: title, body: body, userEmail: cleanEmail);
        } else if (pct >= 0.8) {
          final title = "⚠️ Monthly Budget Warning (${(pct * 100).toStringAsFixed(0)}%)";
          final body = "You have reached ${(pct * 100).toStringAsFixed(0)}% of your overall monthly limit (₹${NumberFormat('#,##0').format(totalSpent)} / ₹${NumberFormat('#,##0').format(totalBudget.amount)}).";
          await NotificationService().showBudgetAlertNotification(title: title, body: body, userEmail: cleanEmail);
        }
      }
    } catch (e) {
      debugPrint("Error checking budget alert: $e");
    }
  }

  Future<List<TransactionModel>> getExpenses(String? email) async {
    if (email == null || email.trim().isEmpty) return [];
    final cleanEmail = email.trim().toLowerCase();
    final db = await instance.database;
    const orderBy = 'date DESC';
    final result = await db.query(
      'expenses',
      where: 'LOWER(TRIM(userEmail)) = ?',
      whereArgs: [cleanEmail],
      orderBy: orderBy,
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<void> refreshExpenses(String? email, {bool syncFromRemote = false}) async {
    if (email == null || email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();

    expensesNotifier.value = await getExpenses(cleanEmail);
    await syncNotifications(cleanEmail);

    if (syncFromRemote) {
      syncWithRemote(cleanEmail).then((_) async {
        expensesNotifier.value = await getExpenses(cleanEmail);
        await syncNotifications(cleanEmail);
      }).catchError((e) => debugPrint("Background sync error: $e"));
    }
  }

  Future<void> syncWithRemote(String email) async {
    try {
      final remoteEntries = await ExpenseService().getExpenses(email);
      final db = await instance.database;

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
    final db = await instance.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshExpenses(email);
  }

  // ── Budget Operations ───────────────────────────────────────────────────────

  Future<void> upsertBudget(BudgetModel budget) async {
    final cleanEmail = budget.userEmail.trim().toLowerCase();
    final db = await instance.database;

    final existing = await db.query(
      'budgets',
      where: 'LOWER(TRIM(category)) = LOWER(TRIM(?)) AND LOWER(TRIM(userEmail)) = ? AND month = ? AND year = ?',
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
          await refreshBudgets(cleanEmail);
        }
      }).catchError((e) {
        debugPrint("Background add budget remote failed: $e");
      });
    }
  }

  Future<List<BudgetModel>> getBudgets(String? email) async {
    if (email == null || email.trim().isEmpty) return [];
    final cleanEmail = email.trim().toLowerCase();
    final db = await instance.database;
    final result = await db.query(
      'budgets',
      where: 'LOWER(TRIM(userEmail)) = ?',
      whereArgs: [cleanEmail],
    );
    return result.map((json) => BudgetModel.fromMap(json)).toList();
  }

  Future<void> refreshBudgets(String? email, {bool syncFromRemote = false}) async {
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

  Future<void> syncBudgetsWithRemote(String email) async {
    if (email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();
    try {
      final remoteEntries = await BudgetService().getBudgets(cleanEmail);
      final db = await instance.database;

      for (BudgetEntry entry in remoteEntries) {
        if (entry.id == null) continue;

        final existing = await db.query(
          'budgets',
          where:
              'remoteId = ? OR (LOWER(TRIM(category)) = LOWER(TRIM(?)) AND LOWER(TRIM(userEmail)) = ? AND month = ? AND year = ?)',
          whereArgs: [entry.id, entry.category, cleanEmail, entry.month, entry.year],
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

  // ── Bill Operations ─────────────────────────────────────────────────────────

  Future<void> insertBill(BillModel bill) async {
    final db = await instance.database;
    final id = await db.insert('bills', bill.toMap());

    final dueDate = bill.dueDate;
    final reminderDate = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
      0,
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
    await syncNotifications(email);
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

    if (bill.id != null) {
      await NotificationService.instance.cancelNotification(bill.id!);

      if (!bill.isPaid) {
        final dueDate = bill.dueDate;
        final reminderDate = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          9,
          0,
        ).subtract(const Duration(days: 1));

        await NotificationService.instance.scheduleBillReminder(
          id: bill.id!,
          title: 'Upcoming Bill: ${bill.title}',
          body: 'Your bill of ₹${bill.amount.toStringAsFixed(2)} is due tomorrow.',
          scheduledDate: reminderDate,
        );
      }
    }

    await refreshBills(bill.userEmail);
  }

  // ── Savings Goals Operations ───────────────────────────────────────────────

  Future<int> insertGoal(GoalModel goal) async {
    final db = await instance.database;

    // Save locally first for instant UI response (Offline-first approach)
    final localId = await db.insert('goals', goal.toMap());
    await refreshGoals(goal.userEmail);

    // Perform remote sync in background without blocking UI
    GoalService()
        .addGoal(GoalEntry(
      title: goal.title,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      targetDate: goal.targetDate,
      iconCode: goal.iconCode,
      colorValue: goal.colorValue,
      category: goal.category,
      userEmail: goal.userEmail,
      priority: goal.priority,
      status: goal.status,
      productUrl: goal.productUrl,
      autoDepositAmount: goal.autoDepositAmount,
      autoDepositDay: goal.autoDepositDay,
    ))
        .then((remoteEntry) async {
      if (remoteEntry != null && remoteEntry.id != null) {
        final updatedGoal = goal.copyWith(id: localId, remoteId: remoteEntry.id);
        await db
            .update('goals', updatedGoal.toMap(), where: 'id = ?', whereArgs: [localId]);
      }
    }).catchError((e) => debugPrint("Background addGoal remote sync failed: $e"));

    return localId;
  }

  Future<List<GoalModel>> getGoals(String? email) async {
    if (email == null || email.trim().isEmpty) return [];
    final cleanEmail = email.trim().toLowerCase();
    final db = await instance.database;
    final result = await db.query(
      'goals',
      where: 'LOWER(TRIM(userEmail)) = ?',
      whereArgs: [cleanEmail],
      orderBy: 'targetDate ASC',
    );
    return result.map((json) => GoalModel.fromMap(json)).toList();
  }

  Future<void> refreshGoals(String? email, {bool syncFromRemote = false}) async {
    if (email == null || email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();
    goalsNotifier.value = await getGoals(cleanEmail);
    await syncNotifications(cleanEmail);

    if (syncFromRemote) {
      try {
        await syncGoalsWithRemote(cleanEmail);
        goalsNotifier.value = await getGoals(cleanEmail);
        await syncNotifications(cleanEmail);
      } catch (e) {
        debugPrint("Background goals sync error: $e");
      }
    }
  }

  Future<void> syncGoalsWithRemote(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final remoteGoals = await GoalService().getGoals(cleanEmail);
      final remoteContributions = await GoalService().getGoalContributions(cleanEmail);
      final db = await instance.database;

      for (GoalEntry entry in remoteGoals) {
        if (entry.id == null) continue;

        final existing = await db.query(
          'goals',
          where: 'remoteId = ? OR (LOWER(TRIM(userEmail)) = ? AND LOWER(TRIM(title)) = ?)',
          whereArgs: [entry.id, cleanEmail, entry.title.trim().toLowerCase()],
        );

        if (existing.isEmpty) {
          final goal = GoalModel(
            remoteId: entry.id,
            title: entry.title,
            targetAmount: entry.targetAmount,
            currentAmount: entry.currentAmount,
            targetDate: entry.targetDate,
            iconCode: entry.iconCode,
            colorValue: entry.colorValue,
            category: entry.category,
            userEmail: cleanEmail,
            priority: entry.priority,
            status: entry.status,
            productUrl: entry.productUrl,
            autoDepositAmount: entry.autoDepositAmount,
            autoDepositDay: entry.autoDepositDay,
          );
          await db.insert('goals', goal.toMap());
        } else {
          final localId = existing.first['id'] as int;
          final updatedGoal = GoalModel(
            id: localId,
            remoteId: entry.id,
            title: entry.title,
            targetAmount: entry.targetAmount,
            currentAmount: entry.currentAmount,
            targetDate: entry.targetDate,
            iconCode: entry.iconCode,
            colorValue: entry.colorValue,
            category: entry.category,
            userEmail: cleanEmail,
            priority: entry.priority,
            status: entry.status,
            productUrl: entry.productUrl,
            autoDepositAmount: entry.autoDepositAmount,
            autoDepositDay: entry.autoDepositDay,
          );
          await db.update('goals', updatedGoal.toMap(),
              where: 'id = ?', whereArgs: [localId]);
        }
      }

      for (GoalContributionEntry contrib in remoteContributions) {
        if (contrib.id == null) continue;

        final matchingGoals = await db.query(
          'goals',
          where: 'remoteId = ?',
          whereArgs: [contrib.goalId],
        );
        final localGoalId = matchingGoals.isNotEmpty ? (matchingGoals.first['id'] as int) : contrib.goalId;

        final existing = await db.query(
          'goal_contributions',
          where: 'remoteId = ?',
          whereArgs: [contrib.id],
        );

        if (existing.isEmpty) {
          final contribution = GoalContributionModel(
            remoteId: contrib.id,
            goalId: localGoalId,
            amount: contrib.amount,
            date: contrib.date,
            note: contrib.note,
            type: contrib.type,
            userEmail: cleanEmail,
          );
          await db.insert('goal_contributions', contribution.toMap());
        }
      }
    } catch (e) {
      debugPrint('Goals sync failed: $e');
    }
  }

  Future<void> updateGoal(GoalModel goal) async {
    final db = await instance.database;
    await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );

    // Refresh UI immediately
    await refreshGoals(goal.userEmail);

    // Perform remote update in background
    if (goal.remoteId != null) {
      GoalService()
          .updateGoal(GoalEntry(
            id: goal.remoteId,
            title: goal.title,
            targetAmount: goal.targetAmount,
            currentAmount: goal.currentAmount,
            targetDate: goal.targetDate,
            iconCode: goal.iconCode,
            colorValue: goal.colorValue,
            category: goal.category,
            userEmail: goal.userEmail,
            priority: goal.priority,
            status: goal.status,
            productUrl: goal.productUrl,
            autoDepositAmount: goal.autoDepositAmount,
            autoDepositDay: goal.autoDepositDay,
          ))
          .catchError((e) => debugPrint("Background updateGoal remote sync failed: $e"));
    }
  }

  Future<void> deleteGoal(int id, String? email) async {
    final db = await instance.database;

    final rows = await db.query('goals', where: 'id = ?', whereArgs: [id]);
    final GoalModel? goal = rows.isNotEmpty ? GoalModel.fromMap(rows.first) : null;

    // Delete local records first
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
    await db.delete('goal_contributions', where: 'goalId = ?', whereArgs: [id]);
    await refreshGoals(email);

    // Perform remote deletion in background
    if (goal != null && goal.remoteId != null) {
      GoalService().deleteGoal(goal.remoteId!).catchError(
            (e) => debugPrint("Background deleteGoal remote sync failed: $e"),
          );
    }
  }

  Future<void> insertGoalContribution(GoalContributionModel contribution) async {
    final db = await instance.database;

    // Insert contribution locally first
    final localId = await db.insert('goal_contributions', contribution.toMap());

    // Perform remote sync in background
    GoalService()
        .addGoalContribution(GoalContributionEntry(
      goalId: contribution.goalId,
      amount: contribution.amount,
      date: contribution.date,
      note: contribution.note,
      type: contribution.type,
      userEmail: contribution.userEmail,
    ))
        .then((remoteContrib) async {
      if (remoteContrib != null && remoteContrib.id != null) {
        final updatedContrib = GoalContributionModel(
          id: localId,
          remoteId: remoteContrib.id,
          goalId: contribution.goalId,
          amount: contribution.amount,
          date: contribution.date,
          note: contribution.note,
          type: contribution.type,
          userEmail: contribution.userEmail,
        );
        await db.update('goal_contributions', updatedContrib.toMap(),
            where: 'id = ?', whereArgs: [localId]);
      }
    }).catchError(
            (e) => debugPrint("Background addGoalContribution remote sync failed: $e"));

    // Update goal current amount & status locally
    final goalRows =
        await db.query('goals', where: 'id = ?', whereArgs: [contribution.goalId]);
    if (goalRows.isNotEmpty) {
      final goal = GoalModel.fromMap(goalRows.first);
      final newAmount = contribution.isDeposit
          ? goal.currentAmount + contribution.amount
          : (goal.currentAmount - contribution.amount).clamp(0.0, double.infinity);
      final isCompleted = newAmount >= goal.targetAmount && goal.targetAmount > 0;
      final newStatus = isCompleted
          ? 'Completed'
          : (goal.status == 'Completed' ? 'Active' : goal.status);
      await updateGoal(goal.copyWith(
        currentAmount: newAmount,
        status: newStatus,
      ));
    }
  }

  Future<List<GoalContributionModel>> getGoalContributions(
      int goalId, String? email) async {
    if (email == null || email.trim().isEmpty) return [];
    final cleanEmail = email.trim().toLowerCase();
    final db = await instance.database;
    final result = await db.query(
      'goal_contributions',
      where: 'goalId = ? AND LOWER(TRIM(userEmail)) = ?',
      whereArgs: [goalId, cleanEmail],
      orderBy: 'date DESC',
    );
    return result.map((json) => GoalContributionModel.fromMap(json)).toList();
  }

  void clearLocalDataNotifiers() {
    expensesNotifier.value = [];
    budgetsNotifier.value = [];
    billsNotifier.value = [];
    categoriesNotifier.value = [];
    goalsNotifier.value = [];
    notificationsNotifier.value = [];
  }

  Future<void> deleteGoalContribution(
      int contributionId, int goalId, double amount, String type, String? email) async {
    final db = await instance.database;

    final rows = await db
        .query('goal_contributions', where: 'id = ?', whereArgs: [contributionId]);
    final GoalContributionModel? contrib =
        rows.isNotEmpty ? GoalContributionModel.fromMap(rows.first) : null;

    // Delete local record first
    await db.delete('goal_contributions', where: 'id = ?', whereArgs: [contributionId]);

    // Perform remote deletion in background
    if (contrib != null && contrib.remoteId != null) {
      GoalService().deleteGoalContribution(contrib.remoteId!).catchError(
            (e) => debugPrint("Background deleteGoalContribution remote sync failed: $e"),
          );
    }

    // Revert goal amount & status
    final goalRows = await db.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (goalRows.isNotEmpty) {
      final goal = GoalModel.fromMap(goalRows.first);
      final isDeposit = type == 'deposit';
      final newAmount = isDeposit
          ? (goal.currentAmount - amount).clamp(0.0, double.infinity)
          : goal.currentAmount + amount;
      final isCompleted = newAmount >= goal.targetAmount && goal.targetAmount > 0;
      final newStatus = isCompleted
          ? 'Completed'
          : (goal.status == 'Completed' ? 'Active' : goal.status);
      await updateGoal(goal.copyWith(
        currentAmount: newAmount,
        status: newStatus,
      ));
    }
  }

  // ── Notification Operations & Smart Sync ────────────────────────────────────

  Future<List<AppNotificationModel>> getNotifications(String? userEmail) async {
    final db = await instance.database;
    final email = userEmail ?? '';
    final result = await db.query(
      'notifications',
      where: 'userEmail = ? OR userEmail = ""',
      whereArgs: [email],
      orderBy: 'timestamp DESC',
    );
    final list = result.map((json) => AppNotificationModel.fromMap(json)).toList();
    notificationsNotifier.value = list;
    return list;
  }

  Future<void> refreshNotifications(String? userEmail) async {
    await getNotifications(userEmail);
  }

  Future<void> insertNotification(AppNotificationModel notification) async {
    final db = await instance.database;
    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await refreshNotifications(notification.userEmail);
  }

  Future<void> markNotificationAsRead(String id, String? userEmail) async {
    final db = await instance.database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshNotifications(userEmail);
  }

  Future<void> markAllNotificationsAsRead(String? userEmail) async {
    final db = await instance.database;
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
    final db = await instance.database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshNotifications(userEmail);
  }

  Future<void> clearAllNotifications(String? userEmail) async {
    final db = await instance.database;
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
    final db = await instance.database;

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
        final notifId = 'bill_${bill.id}_${bill.dueDate.year}_${bill.dueDate.month}_${bill.dueDate.day}';
        final existing = await db.query('notifications', where: 'id = ?', whereArgs: [notifId]);

        final status = diff < 0
            ? 'Overdue'
            : (diff == 0 ? 'Due Today' : 'Due in $diff day${diff > 1 ? "s" : ""}');
        final title = 'Bill Reminder: ${bill.title}';
        final desc = 'Your ${bill.category} bill of ₹${NumberFormat('#,##0').format(bill.amount)} is $status (${bill.dueDate.day}/${bill.dueDate.month}/${bill.dueDate.year}).';

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

    // 2. Check Budget Thresholds (Spending vs Monthly Budget)
    final month = now.month;
    final year = now.year;
    final budgetResult = await db.query(
      'budgets',
      where: '(LOWER(TRIM(userEmail)) = ? OR userEmail = "") AND month = ? AND year = ?',
      whereArgs: [email, month, year],
    );
    final budgets = budgetResult.map((m) => BudgetModel.fromMap(m)).toList();

    if (budgets.isNotEmpty) {
      final expResult = await db.query(
        'expenses',
        where: 'LOWER(TRIM(userEmail)) = ? OR userEmail = ""',
        whereArgs: [email],
      );
      final expenses = expResult.map((m) => TransactionModel.fromMap(m)).toList();

      for (var budget in budgets) {
        double spent = 0.0;
        for (var e in expenses) {
          if (!e.isIncome && e.category.trim().toLowerCase() == budget.category.trim().toLowerCase() && e.date.month == month && e.date.year == year) {
            spent += e.amount;
          }
        }
        if (budget.amount > 0) {
          final pct = (spent / budget.amount) * 100;
          if (pct >= 80) {
            final notifId = 'budget_${budget.category}_${year}_$month';
            final existing = await db.query('notifications', where: 'id = ?', whereArgs: [notifId]);
            final isExceeded = pct >= 100;
            final title = isExceeded ? '🚨 Budget Exceeded: ${budget.category}' : '⚠️ Budget Warning: ${budget.category}';
            final desc = isExceeded
                ? 'You spent ₹${NumberFormat('#,##0').format(spent)}, exceeding your ${budget.category} budget of ₹${NumberFormat('#,##0').format(budget.amount)} by ₹${NumberFormat('#,##0').format(spent - budget.amount)}.'
                : 'You have used ${pct.toStringAsFixed(0)}% of your ₹${NumberFormat('#,##0').format(budget.amount)} budget for ${budget.category}.';

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
          String desc = 'Strong start! You reached ${pct.toStringAsFixed(0)}% of your savings goal of ₹${NumberFormat('#,##0').format(goal.targetAmount)}.';

          if (pct >= 100) {
            milestoneKey = '100';
            title = 'Goal Achieved 🎉: ${goal.title}';
            desc = 'Congratulations! You reached 100% of your savings goal of ₹${NumberFormat('#,##0').format(goal.targetAmount)}!';
          } else if (pct >= 75) {
            milestoneKey = '75';
            title = 'Goal Milestone 🔥: ${goal.title}';
            desc = 'You are ${pct.toStringAsFixed(0)}% of the way to achieving your goal of ₹${NumberFormat('#,##0').format(goal.targetAmount)}!';
          } else if (pct >= 50) {
            milestoneKey = '50';
            title = 'Goal Milestone 🎯: ${goal.title}';
            desc = 'Great job! You reached ${pct.toStringAsFixed(0)}% of your savings goal of ₹${NumberFormat('#,##0').format(goal.targetAmount)}.';
          }

          final notifId = 'goal_${goal.id}_$milestoneKey';
          final existing = await db.query('notifications', where: 'id = ?', whereArgs: [notifId]);

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
      // Seed Welcome Notification
      await db.insert(
        'notifications',
        AppNotificationModel(
          id: 'welcome_1',
          title: 'Welcome to Expense Tracker 👋',
          description: 'Track your spending, manage bills, and hit your savings goals effortlessly. Tap the notification bell anytime to review your alerts!',
          timestamp: now.subtract(const Duration(minutes: 5)),
          type: NotificationType.system,
          userEmail: email,
        ).toMap(),
      );

      await db.insert(
        'notifications',
        AppNotificationModel(
          id: 'daily_checkin_1',
          title: 'Daily Expense Check-In 💰',
          description: 'Don\'t forget to log today\'s expenses to keep your monthly budget and reports accurate!',
          timestamp: now,
          type: NotificationType.reminder,
          actionRoute: '/add-expense',
          userEmail: email,
        ).toMap(),
      );
    }

    await getNotifications(email);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
