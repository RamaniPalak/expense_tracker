import 'package:equatable/equatable.dart';
import '../../data/models/transaction_model.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final String? userEmail;

  const LoadTransactions(this.userEmail);

  @override
  List<Object?> get props => [userEmail];
}

class AddTransaction extends TransactionEvent {
  final TransactionModel transaction;

  const AddTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class UpdateTransaction extends TransactionEvent {
  final TransactionModel transaction;

  const UpdateTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransaction extends TransactionEvent {
  final int transactionId;
  final String? remoteId;
  final String? userEmail;

  const DeleteTransaction({
    required this.transactionId,
    this.remoteId,
    this.userEmail,
  });

  @override
  List<Object?> get props => [transactionId, remoteId, userEmail];
}
