import 'package:dartz/dartz.dart';
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
      // Sync with remote first (Senior recommendation: Offline-first with background sync)
      // For now, keeping the current pull-sync logic inside the repository
      await _syncWithRemote(email);
      
      final db = await databaseHelper.database;
      final result = await db.query(
        'expenses',
        where: 'userEmail = ?',
        whereArgs: [email],
        orderBy: 'date DESC',
      );

      final transactions = result.map((json) => TransactionModel.fromMap(json)).toList();
      return Right(transactions);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> addTransaction(TransactionEntity transaction) async {
    try {
      // Sync to remote first to get the remote ID (Senior pattern: Distributed ID management)
      final remoteEntry = ExpenseEntry(
        title: transaction.title,
        amount: transaction.amount,
        date: transaction.date,
        category: transaction.category,
        isIncome: transaction.isIncome,
        userEmail: transaction.userEmail,
      );

      final savedRemote = await remoteService.addExpense(remoteEntry);

      // Save local with remote ID if available
      final model = TransactionModel(
        title: transaction.title,
        amount: transaction.amount,
        date: transaction.date,
        category: transaction.category,
        isIncome: transaction.isIncome,
        userEmail: transaction.userEmail,
        remoteId: savedRemote?.id,
      );

      final db = await databaseHelper.database;
      await db.insert('expenses', model.toMap());
      
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteTransaction(int id, String? email, int? remoteId) async {
    try {
      if (remoteId != null) {
        await remoteService.deleteExpense(remoteId);
      }
      
      final db = await databaseHelper.database;
      await db.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
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
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<void> _syncWithRemote(String email) async {
    try {
      final remoteEntries = await remoteService.getExpenses(email);
      final db = await databaseHelper.database;

      for (ExpenseEntry entry in remoteEntries) {
        if (entry.id == null) continue;

        final existing = await db.query(
          'expenses',
          where: 'remoteId = ?',
          whereArgs: [entry.id],
        );

        if (existing.isEmpty) {
          final model = TransactionModel(
            remoteId: entry.id,
            title: entry.title,
            amount: entry.amount,
            date: entry.date,
            category: entry.category,
            userEmail: entry.userEmail,
            isIncome: entry.isIncome,
          );
          await db.insert('expenses', model.toMap());
        }
      }
    } catch (e) {
      // Repository handles its own sync failures silently or via logging
      print('Sync Error: $e');
    }
  }
}
