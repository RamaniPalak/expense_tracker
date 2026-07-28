class ReceiptOcrResult {
  final String category;
  final double amount;
  final DateTime date;
  final String title;

  /// True if the AI determined this is an income receipt (salary, refund, etc.)
  final bool isIncome;

  /// AI confidence score (0.0–1.0). Values below 0.75 should prompt the user to review.
  final double confidence;

  ReceiptOcrResult({
    required this.category,
    required this.amount,
    required this.date,
    required this.title,
    this.isIncome = false,
    this.confidence = 1.0,
  });

  factory ReceiptOcrResult.fromJson(Map<String, dynamic> json) {
    // ── Robust Amount Parsing ────────────────────────────────────────────────
    double parsedAmount = 0.0;
    final rawAmount = json['amount'];
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      // Remove currency symbols (₹, $, etc.), commas, '/-', and whitespace
      final cleaned = rawAmount.replaceAll(RegExp(r'[₹$\s,/\-]'), '').trim();
      parsedAmount = double.tryParse(cleaned) ?? 0.0;
    }

    // ── Robust Confidence Parsing ───────────────────────────────────────────
    double parsedConfidence = 1.0;
    final rawConf = json['confidence'];
    if (rawConf is num) {
      parsedConfidence = rawConf.toDouble();
    } else if (rawConf is String) {
      final cleaned = rawConf.replaceAll('%', '').trim();
      final val = double.tryParse(cleaned);
      if (val != null) {
        parsedConfidence = val > 1.0 ? val / 100.0 : val;
      }
    }

    // ── Robust Date Parsing ────────────────────────────────────────────────
    final rawDate = json['date'] as String?;
    final parsedDate = _parseDate(rawDate);

    return ReceiptOcrResult(
      category: json['category'] as String? ?? 'Other',
      amount: parsedAmount.abs(),
      date: parsedDate,
      title: json['merchantName'] as String? ??
          json['title'] as String? ??
          'Receipt',
      isIncome: json['isIncome'] as bool? ?? false,
      confidence: parsedConfidence.clamp(0.0, 1.0),
    );
  }

  static DateTime _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return DateTime.now();
    final trimmed = raw.trim();

    // 1. Try standard ISO-8601 (YYYY-MM-DD)
    final isoParsed = DateTime.tryParse(trimmed);
    if (isoParsed != null) return isoParsed;

    // 2. Try DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final dmyMatch = RegExp(r'^(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})')
        .firstMatch(trimmed);
    if (dmyMatch != null) {
      final day = int.parse(dmyMatch.group(1)!);
      final month = int.parse(dmyMatch.group(2)!);
      final year = int.parse(dmyMatch.group(3)!);
      return DateTime(year, month, day);
    }

    // 3. Try YYYY/MM/DD or YYYY.MM.DD
    final ymdMatch = RegExp(r'^(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})')
        .firstMatch(trimmed);
    if (ymdMatch != null) {
      final year = int.parse(ymdMatch.group(1)!);
      final month = int.parse(ymdMatch.group(2)!);
      final day = int.parse(ymdMatch.group(3)!);
      return DateTime(year, month, day);
    }

    return DateTime.now();
  }
}
