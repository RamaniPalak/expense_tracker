import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../../../../services/database_helper.dart';
import '../../../../services/expense_service.dart';
import 'package:backend_client/backend_client.dart';

class TransactionRepositoryImpl implements ITransactionRepository {
  final DatabaseHelper databaseHelper;
  final ExpenseService remoteService;

  TransactionRepositoryImpl({
    required this.databaseHelper,
    required this.remoteService,
  });

  @override
  Future<Either<String, List<TransactionEntity>>> getTransactions(
      String? email) async {
    if (email == null) return const Left("User email is null");

    try {
      // Load local data immediately for better UX
      final localData = await databaseHelper.getExpenses(email);

      // Perform sync in background
      databaseHelper.syncWithRemote(email).then((_) {
        // Data will be updated on next reload or via notifier
      }).catchError((e) => debugPrint("Background sync error: $e"));

      return Right(localData);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> addTransaction(
      TransactionEntity transaction) async {
    try {
      final model = TransactionModel(
        title: transaction.title,
        amount: transaction.amount,
        date: transaction.date,
        category: transaction.category,
        isIncome: transaction.isIncome,
        userEmail: transaction.userEmail,
        remoteId: null,
      );

      // Save locally via databaseHelper: triggers notifiers and budget alert checks
      final localId = await databaseHelper.insertExpense(model);

      // Perform remote sync in the background without blocking the UI
      final remoteEntry = ExpenseEntry(
        title: transaction.title,
        amount: transaction.amount,
        date: transaction.date,
        category: transaction.category,
        isIncome: transaction.isIncome,
        userEmail: transaction.userEmail,
      );

      remoteService.addExpense(remoteEntry).then((savedRemote) async {
        if (savedRemote != null && savedRemote.id != null) {
          await databaseHelper.updateExpenseRemoteId(localId, savedRemote.id!);
        }
      }).catchError(
          (e) => debugPrint("Background addExpense remote sync failed: $e"));

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, int>> addTransactions(
      List<TransactionEntity> transactions) async {
    if (transactions.isEmpty) return const Right(0);

    try {
      int importedCount = 0;
      for (final transaction in transactions) {
        final result = await addTransaction(transaction);
        if (result.isRight()) {
          importedCount++;
        }
      }
      return Right(importedCount);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<bool> isDuplicateTransaction({
    required double amount,
    required bool isIncome,
    required DateTime date,
    required String userEmail,
  }) async {
    return await databaseHelper.isDuplicateTransaction(
      amount: amount,
      isIncome: isIncome,
      date: date,
      userEmail: userEmail,
    );
  }

  @override
  Future<Either<String, void>> deleteTransaction(
      int id, String? email, int? remoteId) async {
    try {
      // If remoteId was not provided by caller, look it up before deleting locally
      int? effectiveRemoteId = remoteId;
      effectiveRemoteId ??= await databaseHelper.getExpenseRemoteId(id);

      await databaseHelper.deleteExpense(id, email);

      if (effectiveRemoteId != null) {
        // Perform remote deletion in the background without blocking the UI
        remoteService.deleteExpense(effectiveRemoteId).catchError((e) =>
            debugPrint("Background deleteExpense remote sync failed: $e"));
      }

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateTransaction(
      TransactionEntity transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      final db = await databaseHelper.database;
      await db.update(
        'expenses',
        model.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      // Update local notifier cache
      await databaseHelper.refreshExpenses(transaction.userEmail);

      // Perform remote update in the background — only if this record was
      // previously synced and we have a valid remote ID.
      if (transaction.remoteId != null) {
        final remoteEntry = ExpenseEntry(
          id: transaction.remoteId,
          title: transaction.title,
          amount: transaction.amount,
          date: transaction.date,
          category: transaction.category,
          isIncome: transaction.isIncome,
          userEmail: transaction.userEmail,
        );

        remoteService.updateExpense(remoteEntry).catchError(
              (e) =>
                  debugPrint('Background updateExpense remote sync failed: $e'),
            );
      }

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
