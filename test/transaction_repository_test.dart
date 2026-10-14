import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:backend_client/backend_client.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/services/database/daos/bill_dao.dart';
import 'package:expense_tracker/services/database/daos/budget_dao.dart';
import 'package:expense_tracker/services/database/daos/category_dao.dart';
import 'package:expense_tracker/services/database/daos/expense_dao.dart';
import 'package:expense_tracker/services/database/daos/goal_dao.dart';
import 'package:expense_tracker/services/database/daos/notification_dao.dart';
import 'package:expense_tracker/features/wallet/data/models/budget_model.dart';
import 'package:expense_tracker/features/wallet/data/models/monthly_budget_model.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/notifications/data/models/app_notification_model.dart';

class FakeExpenseService implements ExpenseService {
  final List<ExpenseEntry> addedEntries = [];
  final List<int> deletedIds = [];
  final List<ExpenseEntry> updatedEntries = [];
  List<ExpenseEntry> entriesToReturn = [];

  FakeExpenseService();

  @override
  Future<ExpenseEntry?> addExpense(ExpenseEntry entry) async {
    final withId = ExpenseEntry(
      id: addedEntries.length + 101,
      title: entry.title,
      amount: entry.amount,
      date: entry.date,
      category: entry.category,
      isIncome: entry.isIncome,
      userEmail: entry.userEmail,
    );
    addedEntries.add(withId);
    return withId;
  }

  @override
  Future<bool> deleteExpense(int id) async {
    deletedIds.add(id);
    return true;
  }

  @override
  Future<ExpenseEntry?> updateExpense(ExpenseEntry entry) async {
    updatedEntries.add(entry);
    return entry;
  }

  @override
  Future<List<ExpenseEntry>> getExpenses(String email) async {
    return entriesToReturn;
  }
}

class FakeDatabaseHelper implements DatabaseHelper {
  final List<TransactionModel> localExpenses = [];
  final List<int> deletedLocalIds = [];
  bool duplicateCheckResult = false;
  int nextId = 1;

  @override
  late CategoryDao categoryDao;
  @override
  late ExpenseDao expenseDao;
  @override
  late BudgetDao budgetDao;
  @override
  late BillDao billDao;
  @override
  late GoalDao goalDao;
  @override
  late NotificationDao notificationDao;

  @override
  ValueNotifier<List<TransactionModel>> expensesNotifier = ValueNotifier([]);
  @override
  ValueNotifier<List<BudgetModel>> budgetsNotifier = ValueNotifier([]);
  @override
  ValueNotifier<List<MonthlyBudgetModel>> monthlyBudgetsNotifier =
      ValueNotifier([]);
  @override
  ValueNotifier<List<BillModel>> billsNotifier = ValueNotifier([]);
  @override
  ValueNotifier<List<CategoryModel>> categoriesNotifier = ValueNotifier([]);
  @override
  ValueNotifier<List<GoalModel>> goalsNotifier = ValueNotifier([]);
  @override
  ValueNotifier<List<AppNotificationModel>> notificationsNotifier =
      ValueNotifier([]);

  @override
  Future<int> insertExpense(TransactionModel expense) async {
    final id = nextId++;
    final stored = expense.copyWith(id: id);
    localExpenses.add(stored);
    expensesNotifier.value = List.from(localExpenses);
    return id;
  }

  @override
  Future<bool> isDuplicateTransaction({
    required double amount,
    required bool isIncome,
    required DateTime date,
    required String userEmail,
  }) async {
    return duplicateCheckResult;
  }

  @override
  Future<void> refreshExpenses(String? email,
      {bool syncFromRemote = false}) async {
    expensesNotifier.value = List.from(localExpenses);
  }

  @override
  Future<List<TransactionModel>> getExpenses(String? email) async {
    return localExpenses;
  }

  @override
  Future<void> updateExpenseRemoteId(int id, int remoteId) async {
    final idx = localExpenses.indexWhere((e) => e.id == id);
    if (idx != -1) {
      localExpenses[idx] = localExpenses[idx].copyWith(remoteId: remoteId);
      expensesNotifier.value = List.from(localExpenses);
    }
  }

  @override
  Future<int?> getExpenseRemoteId(int id) async {
    final match = localExpenses.where((e) => e.id == id);
    if (match.isNotEmpty) {
      return match.first.remoteId;
    }
    return null;
  }

  @override
  Future<void> deleteExpense(int id, String? email) async {
    deletedLocalIds.add(id);
    localExpenses.removeWhere((e) => e.id == id);
    expensesNotifier.value = List.from(localExpenses);
  }

  // Unused interface stubs
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDatabaseHelper fakeDb;
  late FakeExpenseService fakeRemote;
  late TransactionRepositoryImpl repository;

  setUp(() {
    fakeDb = FakeDatabaseHelper();
    fakeRemote = FakeExpenseService();
    repository = TransactionRepositoryImpl(
      databaseHelper: fakeDb,
      remoteService: fakeRemote,
    );
  });

  group('TransactionRepositoryImpl - Sync Integrity Tests', () {
    test('addTransaction inserts locally and triggers remote sync', () async {
      final now = DateTime(2026, 9, 21, 12, 0);
      final entity = TransactionEntity(
        title: 'Electricity Bill',
        amount: 1250.0,
        date: now,
        category: 'Bills / Utilities',
        isIncome: false,
        userEmail: 'user@example.com',
      );

      final result = await repository.addTransaction(entity);

      expect(result.isRight(), isTrue);
      // Local database was populated
      expect(fakeDb.localExpenses.length, 1);
      expect(fakeDb.localExpenses.first.title, 'Electricity Bill');
      expect(fakeDb.localExpenses.first.amount, 1250.0);

      // Notifier was notified
      expect(fakeDb.expensesNotifier.value.length, 1);

      // Remote service received the add request
      await Future.delayed(const Duration(milliseconds: 10));
      expect(fakeRemote.addedEntries.length, 1);
      expect(fakeRemote.addedEntries.first.title, 'Electricity Bill');
      expect(fakeRemote.addedEntries.first.amount, 1250.0);
    });

    test(
        'addTransactions batch imports multiple items and syncs each to remote',
        () async {
      final now = DateTime(2026, 9, 21, 14, 30);
      final items = [
        TransactionEntity(
          title: 'Swiggy',
          amount: 350.0,
          date: now,
          category: 'Food & Dining',
          isIncome: false,
          userEmail: 'user@example.com',
        ),
        TransactionEntity(
          title: 'Salary Deposit',
          amount: 50000.0,
          date: now,
          category: 'Salary',
          isIncome: true,
          userEmail: 'user@example.com',
        ),
      ];

      final result = await repository.addTransactions(items);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success but got: $failure'),
        (count) => expect(count, 2),
      );

      expect(fakeDb.localExpenses.length, 2);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(fakeRemote.addedEntries.length, 2);
    });

    test('isDuplicateTransaction forwards check to databaseHelper', () async {
      fakeDb.duplicateCheckResult = true;
      final isDup = await repository.isDuplicateTransaction(
        amount: 200.0,
        isIncome: false,
        date: DateTime.now(),
        userEmail: 'user@example.com',
      );
      expect(isDup, isTrue);

      fakeDb.duplicateCheckResult = false;
      final isNotDup = await repository.isDuplicateTransaction(
        amount: 999.0,
        isIncome: true,
        date: DateTime.now(),
        userEmail: 'user@example.com',
      );
      expect(isNotDup, isFalse);
    });

    test(
        'deleteTransaction with remoteId removes from local DB and triggers remote delete',
        () async {
      final now = DateTime.now();
      // Seed a local transaction
      final insertedId = await fakeDb.insertExpense(TransactionModel(
        remoteId: 55,
        title: 'Dinner',
        amount: 600.0,
        date: now,
        category: 'Food & Dining',
        userEmail: 'user@example.com',
        isIncome: false,
      ));

      final result = await repository.deleteTransaction(
          insertedId, 'user@example.com', 55);

      expect(result.isRight(), isTrue);
      expect(fakeDb.deletedLocalIds, contains(insertedId));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(fakeRemote.deletedIds, contains(55));
    });

    test(
        'deleteTransaction looks up remoteId from DB when remoteId argument is null',
        () async {
      final now = DateTime.now();
      // Seed a local transaction that has a remoteId
      final insertedId = await fakeDb.insertExpense(TransactionModel(
        remoteId: 88,
        title: 'Grocery',
        amount: 1200.0,
        date: now,
        category: 'Food & Dining',
        userEmail: 'user@example.com',
        isIncome: false,
      ));

      // Caller does not pass remoteId (e.g. from calendar screen)
      final result = await repository.deleteTransaction(
          insertedId, 'user@example.com', null);

      expect(result.isRight(), isTrue);
      expect(fakeDb.deletedLocalIds, contains(insertedId));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(fakeRemote.deletedIds, contains(88));
    });
  });
}
