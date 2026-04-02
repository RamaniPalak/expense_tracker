import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_wallet_repository.dart';
import '../../data/models/budget_model.dart';
import 'budget_event.dart';
import 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final IWalletRepository walletRepository;

  BudgetBloc({required this.walletRepository}) : super(BudgetInitial()) {
    on<LoadBudgets>(_onLoadBudgets);
    on<UpdateBudget>(_onUpdateBudget);
  }

  Future<void> _onLoadBudgets(
    LoadBudgets event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    final result = await walletRepository.getBudgets(event.userEmail);
    result.fold(
      (failure) => emit(BudgetFailure(failure)),
      (budgets) {
        final models = budgets.map((e) => BudgetModel.fromEntity(e)).toList();
        emit(BudgetLoaded(models));
      },
    );
  }

  Future<void> _onUpdateBudget(
    UpdateBudget event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    final result = await walletRepository.upsertBudget(event.budget);
    result.fold(
      (failure) => emit(BudgetFailure(failure)),
      (_) {
        emit(const BudgetOperationSuccess("Budget Updated Successfully"));
        add(LoadBudgets(event.budget.userEmail));
      },
    );
  }
}
