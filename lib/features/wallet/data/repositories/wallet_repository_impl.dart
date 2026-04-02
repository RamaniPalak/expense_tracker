import 'package:dartz/dartz.dart';
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
      final db = await databaseHelper.database;

      // Category + userEmail as unique key for budgets
      final existing = await db.query(
        'budgets',
        where: 'category = ? AND userEmail = ?',
        whereArgs: [model.category, model.userEmail],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'budgets',
          model.toMap()..remove('id'),
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await db.insert('budgets', model.toMap());
      }

      // Trigger refresh on the helper's notifier for backward compatibility during migration
      databaseHelper.refreshBudgets(model.userEmail);

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<BudgetEntity>>> getBudgets(String? email) async {
    if (email == null) return const Left("User email is null");

    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        'budgets',
        where: 'userEmail = ?',
        whereArgs: [email],
      );

      final budgets = result.map((json) => BudgetModel.fromMap(json)).toList();
      return Right(budgets);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
