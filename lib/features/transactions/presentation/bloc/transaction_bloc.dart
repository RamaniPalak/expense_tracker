import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/models/transaction_model.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final ITransactionRepository transactionRepository;

  TransactionBloc({required this.transactionRepository}) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await transactionRepository.getTransactions(event.userEmail);
    result.fold(
      (failure) => emit(TransactionFailure(failure)),
      (transactions) {
        // Convert entities back to models for UI if needed, or just use entities
        final models = transactions.map((e) => TransactionModel.fromEntity(e)).toList();
        emit(TransactionLoaded(models));
      },
    );
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await transactionRepository.addTransaction(event.transaction);
    result.fold(
      (failure) => emit(TransactionFailure(failure)),
      (_) {
        emit(const TransactionOperationSuccess("Transaction Added Successfully"));
        // After add, reload
        add(LoadTransactions(event.transaction.userEmail));
      },
    );
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await transactionRepository.updateTransaction(event.transaction);
    result.fold(
      (failure) => emit(TransactionFailure(failure)),
      (_) {
        emit(const TransactionOperationSuccess("Transaction Updated Successfully"));
        // After update, reload
        add(LoadTransactions(event.transaction.userEmail));
      },
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    // Convert String? remoteId to int? if repository expects int?
    // Looking at repository, it expects int? remoteId if the backend_client uses int for IDs.
    // Actually, backend_client ExpenseEntry usually has int id.
    int? rId;
    if (event.remoteId != null) {
      rId = int.tryParse(event.remoteId!);
    }
    
    final result = await transactionRepository.deleteTransaction(
      event.transactionId,
      event.userEmail,
      rId,
    );
    result.fold(
      (failure) => emit(TransactionFailure(failure)),
      (_) {
        emit(const TransactionOperationSuccess("Transaction Deleted Successfully"));
        // After delete, reload
        add(LoadTransactions(event.userEmail));
      },
    );
  }
}
