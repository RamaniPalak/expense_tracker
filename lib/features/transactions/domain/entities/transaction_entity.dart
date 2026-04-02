import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final int? id;
  final int? remoteId;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final bool isIncome;
  final String userEmail;

  const TransactionEntity({
    this.id,
    this.remoteId,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isIncome,
    required this.userEmail,
  });

  @override
  List<Object?> get props => [
        id,
        remoteId,
        title,
        amount,
        date,
        category,
        isIncome,
        userEmail,
      ];
}
