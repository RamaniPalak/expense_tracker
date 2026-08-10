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
}
