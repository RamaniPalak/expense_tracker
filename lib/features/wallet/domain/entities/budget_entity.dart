import 'package:equatable/equatable.dart';

class BudgetEntity extends Equatable {
  final int? id;
  final int? remoteId;
  final String category; // 'Total' for overall budget
  final double amount;
  final int month;
  final int year;
  final String userEmail;

  const BudgetEntity({
    this.id,
    this.remoteId,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    required this.userEmail,
  });

  @override
  List<Object?> get props => [
        id,
        remoteId,
        category,
        amount,
        month,
        year,
        userEmail,
      ];
}
