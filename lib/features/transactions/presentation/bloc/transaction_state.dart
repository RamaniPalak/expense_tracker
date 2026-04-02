import 'package:equatable/equatable.dart';
import '../../data/models/transaction_model.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;

  const TransactionLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class TransactionOperationSuccess extends TransactionState {
  final String message;

  const TransactionOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TransactionFailure extends TransactionState {
  final String message;

  const TransactionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
