import 'package:dartz/dartz.dart';
import '../entities/budget_entity.dart';

abstract class IWalletRepository {
  Future<Either<String, void>> upsertBudget(BudgetEntity budget);
  Future<Either<String, List<BudgetEntity>>> getBudgets(String? email);
}
