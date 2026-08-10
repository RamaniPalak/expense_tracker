class GoalContributionModel {
  final int? id;
  final int? remoteId;
  final int goalId;
  final double amount;
  final DateTime date;
  final String? note;
  final String type; // 'deposit' or 'withdrawal'
  final String userEmail;

  GoalContributionModel({
    this.id,
    this.remoteId,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
    this.type = 'deposit',
    required this.userEmail,
  });

  bool get isDeposit => type == 'deposit';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (remoteId != null) 'remoteId': remoteId,
      'goalId': goalId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'type': type,
      'userEmail': userEmail,
    };
  }

  factory GoalContributionModel.fromMap(Map<String, dynamic> map) {
    return GoalContributionModel(
      id: map['id'] as int?,
      remoteId: map['remoteId'] as int?,
      goalId: map['goalId'] as int,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      type: map['type'] as String? ?? 'deposit',
      userEmail: map['userEmail'] as String,
    );
  }
}
