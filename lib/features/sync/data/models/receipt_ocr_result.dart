
class ReceiptOcrResult {
  final String category;
  final double amount;
  final DateTime date;
  final String title;

  ReceiptOcrResult({
    required this.category,
    required this.amount,
    required this.date,
    required this.title,
  });

  factory ReceiptOcrResult.fromJson(Map<String, dynamic> json) {
    return ReceiptOcrResult(
      category: json['category'] ?? 'Other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      title: json['title'] ?? 'Receipt',
    );
  }
}
