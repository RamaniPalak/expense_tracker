import '../../domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    super.id,
    required super.category,
    required super.amount,
    required super.month,
    required super.year,
    required super.userEmail,
  });

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      category: entity.category,
      amount: entity.amount,
      month: entity.month,
      year: entity.year,
      userEmail: entity.userEmail,
    );
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
      userEmail: map['userEmail'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
      'userEmail': userEmail,
    };
  }
}
