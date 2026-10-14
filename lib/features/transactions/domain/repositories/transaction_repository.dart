import 'package:dartz/dartz.dart';
import '../entities/transaction_entity.dart';

abstract class ITransactionRepository {
  Future<Either<String, List<TransactionEntity>>> getTransactions(
      String? email);
  Future<Either<String, void>> addTransaction(TransactionEntity transaction);
  Future<Either<String, int>> addTransactions(
      List<TransactionEntity> transactions);
  Future<Either<String, void>> deleteTransaction(
      int id, String? email, int? remoteId);
  Future<Either<String, void>> updateTransaction(TransactionEntity transaction);
  Future<bool> isDuplicateTransaction({
    required double amount,
    required bool isIncome,
    required DateTime date,
    required String userEmail,
  });
}
