class ParsedFileTransaction {
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final bool isIncome;
  final String? bankName;
  final String? rawLine;
  bool selected;

  ParsedFileTransaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isIncome,
    this.bankName,
    this.rawLine,
    this.selected = true,
  });

  ParsedFileTransaction copyWith({
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    bool? isIncome,
    String? bankName,
    String? rawLine,
    bool? selected,
  }) {
    return ParsedFileTransaction(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      isIncome: isIncome ?? this.isIncome,
      bankName: bankName ?? this.bankName,
      rawLine: rawLine ?? this.rawLine,
      selected: selected ?? this.selected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ParsedFileTransaction) return false;
    return other.title == title &&
        other.amount == amount &&
        other.isIncome == isIncome &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day &&
        other.date.hour == date.hour &&
        other.date.minute == date.minute;
  }

  @override
  int get hashCode {
    return Object.hash(
      title,
      amount,
      isIncome,
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
    );
  }
}
