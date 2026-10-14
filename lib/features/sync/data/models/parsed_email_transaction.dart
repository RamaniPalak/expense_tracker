class ParsedEmailTransaction {
  final String merchant;
  final double amount;
  final bool isCredit;
  final DateTime date;
  final String bank;
  final String category;
  final String emailSubject;
  final String snippet;
  final String senderEmail;
  bool selected;

  ParsedEmailTransaction({
    required this.merchant,
    required this.amount,
    required this.isCredit,
    required this.date,
    required this.bank,
    required this.category,
    required this.emailSubject,
    required this.snippet,
    required this.senderEmail,
    this.selected = true,
  });

  /// Two transactions are equal when they share the same [amount], [isCredit]
  /// type, and date truncated to the minute.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ParsedEmailTransaction) return false;
    return amount == other.amount &&
        isCredit == other.isCredit &&
        _minuteDate == other._minuteDate;
  }

  @override
  int get hashCode => Object.hash(amount, isCredit, _minuteDate);

  DateTime get _minuteDate =>
      DateTime(date.year, date.month, date.day, date.hour, date.minute);
}
