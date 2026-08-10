import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'expense_service.dart';
import 'budget_service.dart';
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
      version: 10,
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
      await db.execute("ALTER TABLE goals ADD COLUMN priority TEXT NOT NULL DEFAULT 'Medium'");
      await db.execute("ALTER TABLE goals ADD COLUMN status TEXT NOT NULL DEFAULT 'Active'");
      await db.execute("ALTER TABLE goals ADD COLUMN productUrl TEXT");
      await db.execute("ALTER TABLE goals ADD COLUMN autoDepositAmount REAL DEFAULT 0.0");
      await db.execute("ALTER TABLE goals ADD COLUMN autoDepositDay INTEGER DEFAULT 1");
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
  goalId $intType,
  amount $realType,
  date $textType,
  note TEXT,
  type $textType,
  userEmail $textType
  )
''');
  }

  // ── Category Operations & Defaults Seeding ──────────────────────────────────

  static final List<Map<String, dynamic>> _defaultExpenseCategories = [
    {"name": "Automobile / Car", "emoji": "🚗", "iconCode": Icons.directions_car_filled_rounded.codePoint, "colorValue": 0xFFEF4444},
    {"name": "Bills / Utilities", "emoji": "🔌", "iconCode": Icons.electrical_services_rounded.codePoint, "colorValue": 0xFF06B6D4},
    {"name": "Charges / Fees", "emoji": "🏛️", "iconCode": Icons.account_balance_rounded.codePoint, "colorValue": 0xFF84CC16},
    {"name": "Education", "emoji": "📚", "iconCode": Icons.school_rounded.codePoint, "colorValue": 0xFFEC4899},
    {"name": "Entertainment", "emoji": "🎭", "iconCode": Icons.theater_comedy_rounded.codePoint, "colorValue": 0xFF10B981},
    {"name": "Food & Dining", "emoji": "🍔", "iconCode": Icons.fastfood_rounded.codePoint, "colorValue": 0xFFF59E0B},
    {"name": "Gifts & Similar", "emoji": "🎁", "iconCode": Icons.card_giftcard_rounded.codePoint, "colorValue": 0xFF0EA5E9},
    {"name": "Health & Fitness", "emoji": "💪", "iconCode": Icons.fitness_center_rounded.codePoint, "colorValue": 0xFF8B5CF6},
    {"name": "Housing", "emoji": "🏠", "iconCode": Icons.home_rounded.codePoint, "colorValue": 0xFFF97316},
    {"name": "Subscriptions", "emoji": "📱", "iconCode": Icons.phonelink_setup_rounded.codePoint, "colorValue": 0xFF3B82F6},
    {"name": "Travel", "emoji": "✈️", "iconCode": Icons.flight_takeoff_rounded.codePoint, "colorValue": 0xFF0EA5E9},
    {"name": "Other", "emoji": "🧩", "iconCode": Icons.category_rounded.codePoint, "colorValue": 0xFF64748B},
  ];

  static final List<Map<String, dynamic>> _defaultIncomeCategories = [
    {"name": "Bonus", "emoji": "🌈", "iconCode": Icons.celebration_rounded.codePoint, "colorValue": 0xFFF43F5E},
    {"name": "Commission", "emoji": "🎉", "iconCode": Icons.percent_rounded.codePoint, "colorValue": 0xFF06B6D4},
    {"name": "Interest", "emoji": "🌱", "iconCode": Icons.trending_up_rounded.codePoint, "colorValue": 0xFF22C55E},
    {"name": "Investments", "emoji": "🚀", "iconCode": Icons.rocket_launch_rounded.codePoint, "colorValue": 0xFFEAB308},
    {"name": "Received from Others", "emoji": "📦", "iconCode": Icons.inventory_2_rounded.codePoint, "colorValue": 0xFF6366F1},
    {"name": "Rental Income", "emoji": "🛏️", "iconCode": Icons.home_rounded.codePoint, "colorValue": 0xFFF97316},
    {"name": "Salary", "emoji": "💼", "iconCode": Icons.work_rounded.codePoint, "colorValue": 0xFF22C55E},
    {"name": "Selling Assets", "emoji": "💰", "iconCode": Icons.monetization_on_rounded.codePoint, "colorValue": 0xFF0EA5E9},
    {"name": "Other", "emoji": "🧩", "iconCode": Icons.category_rounded.codePoint, "colorValue": 0xFF64748B},
  ];

  Future<void> _ensureCategoriesSeeded(String email) async {
    final db = await instance.database;
    final existing = await db.query('categories', where: 'userEmail = ?', whereArgs: [email]);
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

  Future<List<CategoryModel>> getCategories(String? email, {required bool isIncome}) async {
    if (email == null) return [];
    await _ensureCategoriesSeeded(email);
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'userEmail = ? AND isIncome = ?',
      whereArgs: [email, isIncome ? 1 : 0],
      orderBy: 'isDefault DESC, id ASC',
    );
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<void> refreshCategories(String? email) async {
    if (email == null) return;
    await _ensureCategoriesSeeded(email);
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'userEmail = ?',
      whereArgs: [email],
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

    expensesNotifier.value = await getExpenses(email);

    if (syncFromRemote) {
      syncWithRemote(email).then((_) async {
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

  // ── Budget Operations ───────────────────────────────────────────────────────

  Future<void> upsertBudget(BudgetModel budget) async {
    final db = await instance.database;
    
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
      await db.update(
        'budgets',
        budget.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [localId],
      );
    } else {
      localId = await db.insert('budgets', budget.toMap());
    }

    await refreshBudgets(budget.userEmail);

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
    
    final budgets = await getBudgets(email);
    budgetsNotifier.value = budgets;

    if (syncFromRemote) {
      syncBudgetsWithRemote(email).then((_) async {
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

  // ── Bill Operations ─────────────────────────────────────────────────────────

  Future<void> insertBill(BillModel bill) async {
    final db = await instance.database;
    final id = await db.insert('bills', bill.toMap());

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

    if (bill.id != null) {
      await NotificationService.instance.cancelNotification(bill.id!);

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

  // ── Savings Goals Operations ───────────────────────────────────────────────

  Future<int> insertGoal(GoalModel goal) async {
    final db = await instance.database;
    final id = await db.insert('goals', goal.toMap());
    await refreshGoals(goal.userEmail);
    return id;
  }

  Future<List<GoalModel>> getGoals(String? email) async {
    if (email == null) return [];
    final db = await instance.database;
    final result = await db.query(
      'goals',
      where: 'userEmail = ?',
      whereArgs: [email],
      orderBy: 'targetDate ASC',
    );
    return result.map((json) => GoalModel.fromMap(json)).toList();
  }

  Future<void> refreshGoals(String? email) async {
    if (email == null) return;
    goalsNotifier.value = await getGoals(email);
  }

  Future<void> updateGoal(GoalModel goal) async {
    final db = await instance.database;
    await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    await refreshGoals(goal.userEmail);
  }

  Future<void> deleteGoal(int id, String? email) async {
    final db = await instance.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
    await db.delete('goal_contributions', where: 'goalId = ?', whereArgs: [id]);
    await refreshGoals(email);
  }

  Future<void> insertGoalContribution(GoalContributionModel contribution) async {
    final db = await instance.database;
    await db.insert('goal_contributions', contribution.toMap());

    // Update goal current amount & status
    final goalRows = await db.query('goals', where: 'id = ?', whereArgs: [contribution.goalId]);
    if (goalRows.isNotEmpty) {
      final goal = GoalModel.fromMap(goalRows.first);
      final newAmount = contribution.isDeposit
          ? goal.currentAmount + contribution.amount
          : (goal.currentAmount - contribution.amount).clamp(0.0, double.infinity);
      final isCompleted = newAmount >= goal.targetAmount && goal.targetAmount > 0;
      final newStatus = isCompleted ? 'Completed' : (goal.status == 'Completed' ? 'Active' : goal.status);
      await updateGoal(goal.copyWith(
        currentAmount: newAmount,
        status: newStatus,
      ));
    }
  }

  Future<List<GoalContributionModel>> getGoalContributions(int goalId, String? email) async {
    if (email == null) return [];
    final db = await instance.database;
    final result = await db.query(
      'goal_contributions',
      where: 'goalId = ? AND userEmail = ?',
      whereArgs: [goalId, email],
      orderBy: 'date DESC',
    );
    return result.map((json) => GoalContributionModel.fromMap(json)).toList();
  }

  Future<void> deleteGoalContribution(int contributionId, int goalId, double amount, String type, String? email) async {
    final db = await instance.database;
    await db.delete('goal_contributions', where: 'id = ?', whereArgs: [contributionId]);

    // Revert goal amount & status
    final goalRows = await db.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (goalRows.isNotEmpty) {
      final goal = GoalModel.fromMap(goalRows.first);
      final isDeposit = type == 'deposit';
      final newAmount = isDeposit
          ? (goal.currentAmount - amount).clamp(0.0, double.infinity)
          : goal.currentAmount + amount;
      final isCompleted = newAmount >= goal.targetAmount && goal.targetAmount > 0;
      final newStatus = isCompleted ? 'Completed' : (goal.status == 'Completed' ? 'Active' : goal.status);
      await updateGoal(goal.copyWith(
        currentAmount: newAmount,
        status: newStatus,
      ));
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
