import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/features/wallet/data/models/monthly_budget_model.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/notifications/data/models/app_notification_model.dart';

import 'database/daos/category_dao.dart';
import 'database/daos/expense_dao.dart';
import 'database/daos/budget_dao.dart';
import 'database/daos/bill_dao.dart';
import 'database/daos/goal_dao.dart';
import 'database/daos/notification_dao.dart';

/// [DatabaseHelper] manages the SQLite database lifecycle, schema migrations,
/// and acts as a central facade delegating domain-specific queries to dedicated DAOs.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // ── Dedicated DAOs ─────────────────────────────────────────────────────────
  late final CategoryDao categoryDao;
  late final ExpenseDao expenseDao;
  late final BudgetDao budgetDao;
  late final BillDao billDao;
  late final GoalDao goalDao;
  late final NotificationDao notificationDao;

  DatabaseHelper._init() {
    categoryDao = CategoryDao(getDatabase: () => database);
    budgetDao = BudgetDao(getDatabase: () => database);
    notificationDao = NotificationDao(getDatabase: () => database);

    expenseDao = ExpenseDao(
      getDatabase: () => database,
      onExpenseSaved: (expense) async {
        await budgetDao.checkAndTriggerBudgetAlert(
          expense: expense,
          getExpenses: (email) => expenseDao.getExpenses(email),
        );
      },
      onExpensesRefreshed: (email) async {
        await notificationDao.syncNotifications(email);
      },
    );

    billDao = BillDao(
      getDatabase: () => database,
      onBillsRefreshed: (email) async {
        await notificationDao.syncNotifications(email);
      },
    );

    goalDao = GoalDao(
      getDatabase: () => database,
      onGoalsRefreshed: (email) async {
        await notificationDao.syncNotifications(email);
      },
    );
  }

  // ── Backward-compatible ValueNotifiers ─────────────────────────────────────
  ValueNotifier<List<TransactionModel>> get expensesNotifier =>
      expenseDao.expensesNotifier;
  ValueNotifier<List<BudgetModel>> get budgetsNotifier =>
      budgetDao.budgetsNotifier;
  ValueNotifier<List<MonthlyBudgetModel>> get monthlyBudgetsNotifier =>
      budgetDao.monthlyBudgetsNotifier;
  ValueNotifier<List<BillModel>> get billsNotifier => billDao.billsNotifier;
  ValueNotifier<List<CategoryModel>> get categoriesNotifier =>
      categoryDao.categoriesNotifier;
  ValueNotifier<List<GoalModel>> get goalsNotifier => goalDao.goalsNotifier;
  ValueNotifier<List<AppNotificationModel>> get notificationsNotifier =>
      notificationDao.notificationsNotifier;

  // ── Database Lifecycle & Migrations ────────────────────────────────────────

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
      version: 14,
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
      await db.execute(
          "ALTER TABLE goals ADD COLUMN priority TEXT NOT NULL DEFAULT 'Medium'");
      await db.execute(
          "ALTER TABLE goals ADD COLUMN status TEXT NOT NULL DEFAULT 'Active'");
      await db.execute("ALTER TABLE goals ADD COLUMN productUrl TEXT");
      await db.execute(
          "ALTER TABLE goals ADD COLUMN autoDepositAmount REAL DEFAULT 0.0");
      await db.execute(
          "ALTER TABLE goals ADD COLUMN autoDepositDay INTEGER DEFAULT 1");
    }
    if (oldVersion < 11) {
      await db.execute("ALTER TABLE goals ADD COLUMN remoteId INTEGER");
      await db.execute(
          "ALTER TABLE goal_contributions ADD COLUMN remoteId INTEGER");
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
    if (oldVersion < 13) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS monthly_budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  remoteId INTEGER,
  amount REAL NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  userEmail TEXT NOT NULL
)
''');
    }
    if (oldVersion < 14) {
      await db.execute('ALTER TABLE bills ADD COLUMN remoteId INTEGER');
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
CREATE TABLE IF NOT EXISTS monthly_budgets (
  id $idType, 
  remoteId INTEGER,
  amount $realType,
  month $intType,
  year $intType,
  userEmail $textType
  )
''');

    await db.execute('''
CREATE TABLE bills (
  id $idType, 
  remoteId INTEGER,
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

  // ── Category Delegations ───────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategories(String? email,
          {required bool isIncome}) =>
      categoryDao.getCategories(email, isIncome: isIncome);

  Future<void> refreshCategories(String? email) =>
      categoryDao.refreshCategories(email);

  Future<void> insertCategory(CategoryModel category) =>
      categoryDao.insertCategory(category);

  Future<void> updateCategory(CategoryModel category) =>
      categoryDao.updateCategory(category);

  Future<void> deleteCategory(int id, String? email) =>
      categoryDao.deleteCategory(id, email);

  // ── Expense Delegations ────────────────────────────────────────────────────

  Future<int> insertExpense(TransactionModel expense) =>
      expenseDao.insertExpense(expense);

  Future<bool> isDuplicateTransaction({
    required double amount,
    required bool isIncome,
    required DateTime date,
    required String userEmail,
  }) =>
      expenseDao.isDuplicateTransaction(
        amount: amount,
        isIncome: isIncome,
        date: date,
        userEmail: userEmail,
      );

  Future<void> updateExpense(TransactionModel expense) =>
      expenseDao.updateExpense(expense);

  Future<void> updateExpenseRemoteId(int id, int remoteId) =>
      expenseDao.updateExpenseRemoteId(id, remoteId);

  Future<int?> getExpenseRemoteId(int id) => expenseDao.getExpenseRemoteId(id);

  Future<List<TransactionModel>> getExpenses(String? email) =>
      expenseDao.getExpenses(email);

  Future<void> refreshExpenses(String? email, {bool syncFromRemote = false}) =>
      expenseDao.refreshExpenses(email, syncFromRemote: syncFromRemote);

  Future<void> syncWithRemote(String email) => expenseDao.syncWithRemote(email);

  Future<void> deleteExpense(int id, String? email) =>
      expenseDao.deleteExpense(id, email);

  // ── Budget Delegations ─────────────────────────────────────────────────────

  Future<void> upsertBudget(BudgetModel budget) =>
      budgetDao.upsertBudget(budget);

  Future<List<BudgetModel>> getBudgets(String? email) =>
      budgetDao.getBudgets(email);

  Future<void> refreshBudgets(String? email, {bool syncFromRemote = false}) =>
      budgetDao.refreshBudgets(email, syncFromRemote: syncFromRemote);

  Future<void> syncBudgetsWithRemote(String email) =>
      budgetDao.syncBudgetsWithRemote(email);

  Future<void> deleteBudget(int id, String email) =>
      budgetDao.deleteBudget(id, email);

  Future<void> upsertMonthlyBudget(MonthlyBudgetModel budget) =>
      budgetDao.upsertMonthlyBudget(budget);

  Future<List<MonthlyBudgetModel>> getMonthlyBudgets(String? email) =>
      budgetDao.getMonthlyBudgets(email);

  Future<void> refreshMonthlyBudgets(String? email,
          {bool syncFromRemote = false}) =>
      budgetDao.refreshMonthlyBudgets(email, syncFromRemote: syncFromRemote);

  Future<void> syncMonthlyBudgetsWithRemote(String email) =>
      budgetDao.syncMonthlyBudgetsWithRemote(email);

  // ── Bill Delegations ───────────────────────────────────────────────────────

  Future<void> insertBill(BillModel bill) => billDao.insertBill(bill);

  Future<List<BillModel>> getBills(String? email) => billDao.getBills(email);

  Future<void> refreshBills(String? email, {bool syncFromRemote = false}) =>
      billDao.refreshBills(email, syncFromRemote: syncFromRemote);

  Future<void> deleteBill(int id, String? email) =>
      billDao.deleteBill(id, email);

  Future<void> updateBill(BillModel bill) => billDao.updateBill(bill);

  Future<void> syncBillsWithRemote(String email) =>
      billDao.syncBillsWithRemote(email);

  // ── Goal Delegations ───────────────────────────────────────────────────────

  Future<int> insertGoal(GoalModel goal) => goalDao.insertGoal(goal);

  Future<List<GoalModel>> getGoals(String? email) => goalDao.getGoals(email);

  Future<void> refreshGoals(String? email, {bool syncFromRemote = false}) =>
      goalDao.refreshGoals(email, syncFromRemote: syncFromRemote);

  Future<void> syncGoalsWithRemote(String email) =>
      goalDao.syncGoalsWithRemote(email);

  Future<void> updateGoal(GoalModel goal) => goalDao.updateGoal(goal);

  Future<void> deleteGoal(int id, String? email) =>
      goalDao.deleteGoal(id, email);

  Future<void> insertGoalContribution(GoalContributionModel contribution) =>
      goalDao.insertGoalContribution(contribution);

  Future<List<GoalContributionModel>> getGoalContributions(
          int goalId, String? email) =>
      goalDao.getGoalContributions(goalId, email);

  Future<void> deleteGoalContribution(int contributionId, int goalId,
          double amount, String type, String? email) =>
      goalDao.deleteGoalContribution(
          contributionId, goalId, amount, type, email);

  // ── Notification Delegations ───────────────────────────────────────────────

  Future<List<AppNotificationModel>> getNotifications(String? userEmail) =>
      notificationDao.getNotifications(userEmail);

  Future<void> refreshNotifications(String? userEmail) =>
      notificationDao.refreshNotifications(userEmail);

  Future<void> insertNotification(AppNotificationModel notification) =>
      notificationDao.insertNotification(notification);

  Future<void> markNotificationAsRead(String id, String? userEmail) =>
      notificationDao.markNotificationAsRead(id, userEmail);

  Future<void> markAllNotificationsAsRead(String? userEmail) =>
      notificationDao.markAllNotificationsAsRead(userEmail);

  Future<void> deleteNotification(String id, String? userEmail) =>
      notificationDao.deleteNotification(id, userEmail);

  Future<void> clearAllNotifications(String? userEmail) =>
      notificationDao.clearAllNotifications(userEmail);

  Future<void> syncNotifications(String? userEmail) =>
      notificationDao.syncNotifications(userEmail);

  // ── State Reset & Cleanup ──────────────────────────────────────────────────

  void clearLocalDataNotifiers() {
    expensesNotifier.value = [];
    budgetsNotifier.value = [];
    monthlyBudgetsNotifier.value = [];
    billsNotifier.value = [];
    categoriesNotifier.value = [];
    goalsNotifier.value = [];
    notificationsNotifier.value = [];
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
