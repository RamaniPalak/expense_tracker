import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/i_wallet_repository.dart';
import '../models/budget_model.dart';
import '../../../../services/database_helper.dart';

class WalletRepositoryImpl implements IWalletRepository {
  final DatabaseHelper databaseHelper;

  WalletRepositoryImpl({required this.databaseHelper});

  @override
  Future<Either<String, void>> upsertBudget(BudgetEntity budget) async {
    try {
      final model = BudgetModel.fromEntity(budget);
      await databaseHelper.upsertBudget(model);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<BudgetEntity>>> getBudgets(String? email) async {
    if (email == null) return const Left("User email is null");

    try {
      final localData = await databaseHelper.getBudgets(email);
      
      // Perform background sync from remote server
      databaseHelper.refreshBudgets(email, syncFromRemote: true).catchError(
        (e) => debugPrint("Background budget load sync failed: $e"),
      );

      return Right(localData);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
