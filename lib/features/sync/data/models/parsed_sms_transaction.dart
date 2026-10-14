class ParsedSmsTransaction {
  final String merchant;
  final double amount;
  final bool isCredit;
  final DateTime date;
  final String bank;
  final String category;

  // Mutable flag for UI selection — excluded from equality intentionally.
  bool selected;

  ParsedSmsTransaction({
    required this.merchant,
    required this.amount,
    required this.isCredit,
    required this.date,
    required this.bank,
    required this.category,
    this.selected = true,
  });

  /// Two transactions are equal when they share the same [amount], [isCredit]
  /// type, and date truncated to the minute. This reliably identifies the same
  /// physical transaction across multiple SMS re-scans without relying on
  /// Equatable (which requires an immutable class).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ParsedSmsTransaction) return false;
    return amount == other.amount &&
        isCredit == other.isCredit &&
        _minuteDate == other._minuteDate;
  }

  @override
  int get hashCode => Object.hash(amount, isCredit, _minuteDate);

  /// Date truncated to minute precision — tolerates sub-minute SMS timestamp
  /// drift that can occur across re-scans.
  DateTime get _minuteDate =>
      DateTime(date.year, date.month, date.day, date.hour, date.minute);
}
