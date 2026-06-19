class ParsedSmsTransaction {
  final String merchant;
  final double amount;
  final bool isCredit;
  final DateTime date;
  final String bank;
  final String category;
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
}
