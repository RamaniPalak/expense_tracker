class Expense {
  final int? id;
  final int? remoteId;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final bool isIncome;
  final String userEmail;

  Expense({
    this.id,
    this.remoteId,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.userEmail,
    this.isIncome = false,
  });

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

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      remoteId: map['remoteId'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      isIncome: map['isIncome'] == 1,
      userEmail: map['userEmail'] ?? '',
    );
  }
}
