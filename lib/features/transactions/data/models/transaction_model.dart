import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    super.id,
    super.remoteId,
    required super.title,
    required super.amount,
    required super.date,
    required super.category,
    required super.isIncome,
    required super.userEmail,
  });

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      remoteId: entity.remoteId,
      title: entity.title,
      amount: entity.amount,
      date: entity.date,
      category: entity.category,
      isIncome: entity.isIncome,
      userEmail: entity.userEmail,
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      remoteId: map['remoteId'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      isIncome: map['isIncome'] == 1,
      userEmail: map['userEmail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remoteId': remoteId,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'isIncome': isIncome ? 1 : 0,
      'userEmail': userEmail,
    };
  }
}
