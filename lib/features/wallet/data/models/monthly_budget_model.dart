import 'package:equatable/equatable.dart';

class MonthlyBudgetModel extends Equatable {
  final int? id;
  final int? remoteId;
  final double amount;
  final int month;
  final int year;
  final String userEmail;

  const MonthlyBudgetModel({
    this.id,
    this.remoteId,
    required this.amount,
    required this.month,
    required this.year,
    required this.userEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remoteId': remoteId,
      'amount': amount,
      'month': month,
      'year': year,
      'userEmail': userEmail,
    };
  }

  factory MonthlyBudgetModel.fromMap(Map<String, dynamic> map) {
    return MonthlyBudgetModel(
      id: map['id'] as int?,
      remoteId: map['remoteId'] as int?,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
      userEmail: map['userEmail'] as String,
    );
  }

  MonthlyBudgetModel copyWith({
    int? id,
    int? remoteId,
    double? amount,
    int? month,
    int? year,
    String? userEmail,
  }) {
    return MonthlyBudgetModel(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  @override
  List<Object?> get props => [id, remoteId, amount, month, year, userEmail];
}
