import 'package:equatable/equatable.dart';
import '../../data/models/budget_model.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgets extends BudgetEvent {
  final String? userEmail;

  const LoadBudgets(this.userEmail);

  @override
  List<Object?> get props => [userEmail];
}

class UpdateBudget extends BudgetEvent {
  final BudgetModel budget;

  const UpdateBudget(this.budget);

  @override
  List<Object?> get props => [budget];
}
