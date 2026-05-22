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
  Future<Either<String, List<TransactionEntity>>> getTransactions(String? email) async {
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
  Future<Either<String, void>> addTransaction(TransactionEntity transaction) async {
    try {
      // Save local first with remote ID null (Offline-first approach)
      final model = TransactionModel(
        title: transaction.title,
        amount: transaction.amount,
        date: transaction.date,
        category: transaction.category,
        isIncome: transaction.isIncome,
        userEmail: transaction.userEmail,
        remoteId: null,
      );

      final db = await databaseHelper.database;
      final localId = await db.insert('expenses', model.toMap());
      
      // Update local notifier cache immediately to refresh UI
      await databaseHelper.refreshExpenses(transaction.userEmail);

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
          // Update the local record with the remote ID
          final updatedModel = TransactionModel(
            id: localId,
            remoteId: savedRemote.id,
            title: transaction.title,
            amount: transaction.amount,
            date: transaction.date,
            category: transaction.category,
            isIncome: transaction.isIncome,
            userEmail: transaction.userEmail,
          );
          await db.update(
            'expenses',
            updatedModel.toMap(),
            where: 'id = ?',
            whereArgs: [localId],
          );
        }
      }).catchError((e) => debugPrint("Background addExpense remote sync failed: $e"));
      
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteTransaction(int id, String? email, int? remoteId) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Update local notifier cache immediately
      await databaseHelper.refreshExpenses(email);

      if (remoteId != null) {
        // Perform remote deletion in the background without blocking the UI
        remoteService.deleteExpense(remoteId).catchError(
            (e) => debugPrint("Background deleteExpense remote sync failed: $e"));
      }

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateTransaction(TransactionEntity transaction) async {
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

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

}
