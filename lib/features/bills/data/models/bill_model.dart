import 'package:equatable/equatable.dart';

class BillModel extends Equatable {
  final int? id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String category;
  final bool isPaid;
  final bool isRecurring;
  final String userEmail;

  const BillModel({
    this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    this.isPaid = false,
    this.isRecurring = false,
    required this.userEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'category': category,
      'isPaid': isPaid ? 1 : 0,
      'isRecurring': isRecurring ? 1 : 0,
      'userEmail': userEmail,
    };
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'],
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate']),
      category: map['category'],
      isPaid: map['isPaid'] == 1,
      isRecurring: map['isRecurring'] == 1,
      userEmail: map['userEmail'],
    );
  }

  BillModel copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? category,
    bool? isPaid,
    bool? isRecurring,
    String? userEmail,
  }) {
    return BillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      isPaid: isPaid ?? this.isPaid,
      isRecurring: isRecurring ?? this.isRecurring,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        dueDate,
        category,
        isPaid,
        isRecurring,
        userEmail,
      ];
}
