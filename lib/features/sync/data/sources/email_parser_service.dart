import '../models/parsed_email_transaction.dart';

class EmailParserService {
  // Regex to extract amount (e.g., Rs. 500, Rs 500.50, INR 1,200.00, $45.00, USD 99)
  static final RegExp _amountRegex = RegExp(
    r'(?:Rs\.?|INR|\$|USD)\s*([0-9,]+(?:\.[0-9]{2})?)'
    r'|([0-9,]+(?:\.[0-9]{2})?)\s*(?:Rs\.?|INR|\$|USD)',
    caseSensitive: false,
  );

  // Regex to extract merchant/payee name
  static final RegExp _merchantRegex = RegExp(
    r'(?:at|to|spent\s+on|vpa|info|vendor|merchant|towards)\s+([A-Za-z0-9\s\*\-\.\&]+?)(?:\s+on|\s+for|\s+Ref|\s+UPI|\s+limit|\.|\b|\,|\n)',
    caseSensitive: false,
  );

  /// Check if the email subject or snippet is indicative of a transaction alert
  static bool isTransactionalEmail(String subject, String body) {
    final combinedText = '$subject $body'.toLowerCase();
    final hasAmount = _amountRegex.hasMatch(combinedText);
    final hasKeywords = combinedText.contains('debited') ||
        combinedText.contains('credited') ||
        combinedText.contains('spent') ||
        combinedText.contains('paid') ||
        combinedText.contains('received') ||
        combinedText.contains('withdrawn') ||
        combinedText.contains('charge') ||
        combinedText.contains('payment alert') ||
        combinedText.contains('transaction alert') ||
        combinedText.contains('transfer') ||
        combinedText.contains('purchase');
    return hasAmount && hasKeywords;
  }

  /// Parse email metadata and text into a ParsedEmailTransaction object
  static ParsedEmailTransaction? parseEmail({
    required String subject,
    required String body,
    required DateTime date,
    String? sender,
  }) {
    if (!isTransactionalEmail(subject, body)) {
      return null;
    }

    final combinedText = '$subject\n$body';
    final amount = _parseAmount(combinedText);
    if (amount <= 0.0) return null;

    final isCredit = _checkIsCredit(combinedText);
    final merchant = _parseMerchant(combinedText, isCredit);
    final bank = _parseBank(sender ?? '', combinedText);
    final category = parseCategory(merchant, isCredit);
    final snippet = body.length > 120 ? '${body.substring(0, 117)}...' : body;

    final senderEmail = sender ?? 'bank.alerts@domain.com';

    return ParsedEmailTransaction(
      merchant: merchant,
      amount: amount,
      isCredit: isCredit,
      date: date,
      bank: bank,
      category: category,
      emailSubject: subject,
      snippet: snippet,
      senderEmail: senderEmail,
    );
  }

  static double _parseAmount(String text) {
    final match = _amountRegex.firstMatch(text);
    if (match != null) {
      final amountStr = match.group(1) ?? match.group(2);
      if (amountStr != null) {
        return double.tryParse(amountStr.replaceAll(',', '')) ?? 0.0;
      }
    }
    return 0.0;
  }

  static bool _checkIsCredit(String text) {
    final cleanText = text.toLowerCase();
    if (cleanText.contains('credited') ||
        cleanText.contains('received') ||
        cleanText.contains('added') ||
        cleanText.contains('refunded') ||
        cleanText.contains('salary')) {
      return true;
    }
    return false; // Default to expense / debit
  }

  static String _parseMerchant(String text, bool isCredit) {
    final match = _merchantRegex.firstMatch(text);
    if (match != null) {
      final rawMerchant = match.group(1)?.trim() ?? '';
      if (rawMerchant.isNotEmpty && rawMerchant.length < 35) {
        final cleanMerchant = rawMerchant
            .replaceAll(RegExp(r'\s+on$'), '')
            .replaceAll(RegExp(r'\s+for$'), '')
            .trim();
        if (cleanMerchant.isNotEmpty) {
          return cleanMerchant;
        }
      }
    }
    return isCredit ? 'Income Alert' : 'Expense Alert';
  }

  static String _parseBank(String sender, String text) {
    final upperText = '$sender $text'.toUpperCase();
    if (upperText.contains('HDFC')) return 'HDFC Bank';
    if (upperText.contains('SBI') || upperText.contains('STATE BANK')) return 'SBI';
    if (upperText.contains('ICICI')) return 'ICICI Bank';
    if (upperText.contains('AXIS')) return 'Axis Bank';
    if (upperText.contains('KOTAK')) return 'Kotak Bank';
    if (upperText.contains('PAYTM')) return 'Paytm';
    if (upperText.contains('RAZORPAY')) return 'Razorpay';
    if (upperText.contains('PAYPAL')) return 'PayPal';
    if (upperText.contains('CHASE')) return 'Chase';
    if (upperText.contains('AMEX') || upperText.contains('AMERICAN EXPRESS')) return 'Amex';

    return 'Bank Alert';
  }

  static String parseCategory(String merchant, bool isCredit) {
    if (isCredit) {
      final clean = merchant.toLowerCase();
      if (clean.contains('salary')) return 'Salary';
      if (clean.contains('interest')) return 'Interest';
      if (clean.contains('freelance') || clean.contains('upwork')) return 'Freelance';
      return 'Received from Others';
    }

    final clean = merchant.toLowerCase();
    if (clean.contains('zomato') ||
        clean.contains('swiggy') ||
        clean.contains('starbucks') ||
        clean.contains('food') ||
        clean.contains('dining') ||
        clean.contains('restaurant') ||
        clean.contains('dominos') ||
        clean.contains('eats')) {
      return 'Food & Dining';
    }
    if (clean.contains('uber') ||
        clean.contains('ola') ||
        clean.contains('cab') ||
        clean.contains('transport') ||
        clean.contains('metro') ||
        clean.contains('petrol') ||
        clean.contains('fuel')) {
      return 'Transport';
    }
    if (clean.contains('netflix') ||
        clean.contains('spotify') ||
        clean.contains('movie') ||
        clean.contains('cinema') ||
        clean.contains('entertainment') ||
        clean.contains('prime')) {
      return 'Entertainment';
    }
    if (clean.contains('bill') ||
        clean.contains('electricity') ||
        clean.contains('water') ||
        clean.contains('phone') ||
        clean.contains('recharge') ||
        clean.contains('utility')) {
      return 'Bills / Utilities';
    }
    if (clean.contains('amazon') ||
        clean.contains('flipkart') ||
        clean.contains('shopping') ||
        clean.contains('grocery') ||
        clean.contains('myntra') ||
        clean.contains('store')) {
      return 'Shopping';
    }
    return 'Other';
  }
}
