import 'package:equatable/equatable.dart';
import '../../data/models/budget_model.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final List<BudgetModel> budgets;

  const BudgetLoaded(this.budgets);

  @override
  List<Object?> get props => [budgets];
}

class BudgetOperationSuccess extends BudgetState {
  final String message;

  const BudgetOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BudgetFailure extends BudgetState {
  final String message;

  const BudgetFailure(this.message);

  @override
  List<Object?> get props => [message];
}
