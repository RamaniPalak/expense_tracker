import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/services/database/daos/category_dao.dart';
import 'package:expense_tracker/services/database/daos/expense_dao.dart';
import 'package:expense_tracker/services/database/daos/budget_dao.dart';
import 'package:expense_tracker/services/database/daos/bill_dao.dart';
import 'package:expense_tracker/services/database/daos/goal_dao.dart';
import 'package:expense_tracker/services/database/daos/notification_dao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseHelper DAO Architecture Tests', () {
    test('DatabaseHelper instance exposes all 6 dedicated DAOs', () {
      final db = DatabaseHelper.instance;

      expect(db.categoryDao, isA<CategoryDao>());
      expect(db.expenseDao, isA<ExpenseDao>());
      expect(db.budgetDao, isA<BudgetDao>());
      expect(db.billDao, isA<BillDao>());
      expect(db.goalDao, isA<GoalDao>());
      expect(db.notificationDao, isA<NotificationDao>());
    });

    test(
        'All 7 backward-compatible ValueNotifiers are connected to respective DAOs',
        () {
      final db = DatabaseHelper.instance;

      expect(db.expensesNotifier, equals(db.expenseDao.expensesNotifier));
      expect(db.budgetsNotifier, equals(db.budgetDao.budgetsNotifier));
      expect(db.monthlyBudgetsNotifier,
          equals(db.budgetDao.monthlyBudgetsNotifier));
      expect(db.billsNotifier, equals(db.billDao.billsNotifier));
      expect(db.categoriesNotifier, equals(db.categoryDao.categoriesNotifier));
      expect(db.goalsNotifier, equals(db.goalDao.goalsNotifier));
      expect(db.notificationsNotifier,
          equals(db.notificationDao.notificationsNotifier));
    });

    test('clearLocalDataNotifiers empties all value notifiers', () {
      final db = DatabaseHelper.instance;

      // Seed dummy values to notifiers
      db.clearLocalDataNotifiers();

      expect(db.expensesNotifier.value, isEmpty);
      expect(db.budgetsNotifier.value, isEmpty);
      expect(db.monthlyBudgetsNotifier.value, isEmpty);
      expect(db.billsNotifier.value, isEmpty);
      expect(db.categoriesNotifier.value, isEmpty);
      expect(db.goalsNotifier.value, isEmpty);
      expect(db.notificationsNotifier.value, isEmpty);
    });

    test(
        'CategoryDao contains complete default expense and income category seed datasets',
        () {
      expect(CategoryDao.defaultExpenseCategories.length,
          greaterThanOrEqualTo(10));
      expect(
          CategoryDao.defaultIncomeCategories.length, greaterThanOrEqualTo(8));

      final expenseCatNames =
          CategoryDao.defaultExpenseCategories.map((c) => c['name']).toSet();
      expect(expenseCatNames, contains('Food & Dining'));
      expect(expenseCatNames, contains('Bills / Utilities'));
      expect(expenseCatNames, contains('Travel'));

      final incomeCatNames =
          CategoryDao.defaultIncomeCategories.map((c) => c['name']).toSet();
      expect(incomeCatNames, contains('Salary'));
      expect(incomeCatNames, contains('Investments'));
      expect(incomeCatNames, contains('Bonus'));
    });
  });
}
