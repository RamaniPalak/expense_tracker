import '../models/parsed_sms_transaction.dart';

/// Lightweight, package-agnostic representation of a raw SMS message.
/// The review screen maps android_sms_reader's SmsMessage → SmsData before
/// passing it to the parser, keeping this service free of platform bindings.
class SmsData {
  final String? address;
  final String? body;
  final DateTime? date;

  const SmsData({this.address, this.body, this.date});
}

class SmsParserService {
  // Regex to extract amount — handles Rs. 500, INR 500, Rupees 1,500, 500.00 Rs
  static final RegExp _amountRegex = RegExp(
    r'(?:Rs\.?|INR|Rupees)\s*([0-9,]+(?:\.[0-9]{2})?)'
    r'|([0-9,]+(?:\.[0-9]{2})?)\s*(?:Rs\.?|INR)',
    caseSensitive: false,
  );

  // Regex to extract merchant/payee name
  static final RegExp _merchantRegex = RegExp(
    r'(?:at|to|spent\s+on|vpa|info)\s+([A-Za-z0-9\s\*\-\.]+?)(?:\s+on|\s+for|\s+Ref|\s+Ref\b|\s+UPI|\s+limit|\.|\b)',
    caseSensitive: false,
  );

  // Regex to capture UPI / transaction reference number
  static final RegExp _refRegex = RegExp(
    r'(?:UPI\s*Ref(?:\s*No)?|Ref\s*No|Txn\s*ID|Transaction\s*ID)[.:\s]+([A-Z0-9]+)',
    caseSensitive: false,
  );

  /// Returns true when [body] looks like a bank transaction alert.
  static bool isTransactional(String body) {
    final cleanBody = body.toLowerCase();
    final hasAmount = _amountRegex.hasMatch(body);
    final hasTransactionKeywords = cleanBody.contains('debited') ||
        cleanBody.contains('credited') ||
        cleanBody.contains('spent') ||
        cleanBody.contains('withdrawn') ||
        cleanBody.contains('sent') ||
        cleanBody.contains('received') ||
        cleanBody.contains('paid');
    return hasAmount && hasTransactionKeywords;
  }

  /// Parse a list of raw [SmsData] messages into [ParsedSmsTransaction] objects.
  static List<ParsedSmsTransaction> parseMessages(List<SmsData> messages) {
    final List<ParsedSmsTransaction> transactions = [];

    for (var msg in messages) {
      final body = msg.body;
      if (body == null || !isTransactional(body)) continue;

      try {
        final amount = _parseAmount(body);
        if (amount == 0.0) continue;

        final isCredit = _checkIsCredit(body);
        final merchant = _parseMerchant(body, isCredit);
        final bank = _parseBank(msg.address ?? '', body);
        final date = msg.date ?? DateTime.now();
        final category = parseCategory(merchant, isCredit);

        transactions.add(ParsedSmsTransaction(
          merchant: merchant,
          amount: amount,
          isCredit: isCredit,
          date: date,
          bank: bank,
          category: category,
        ));
      } catch (e) {
        // Skip malformed messages
      }
    }

    return transactions;
  }

  static double _parseAmount(String body) {
    final match = _amountRegex.firstMatch(body);
    if (match != null) {
      final amountStr = match.group(1) ?? match.group(2);
      if (amountStr != null) {
        return double.tryParse(amountStr.replaceAll(',', '')) ?? 0.0;
      }
    }
    return 0.0;
  }

  static bool _checkIsCredit(String body) {
    final cleanBody = body.toLowerCase();
    if (cleanBody.contains('debited') ||
        cleanBody.contains('spent') ||
        cleanBody.contains('withdrawn') ||
        cleanBody.contains('sent') ||
        cleanBody.contains('paid')) {
      return false;
    }
    if (cleanBody.contains('credited') ||
        cleanBody.contains('received') ||
        cleanBody.contains('added')) {
      return true;
    }
    return false; // Default to debit (safer for expense tracker)
  }

  static String _parseMerchant(String body, bool isCredit) {
    final match = _merchantRegex.firstMatch(body);
    if (match != null) {
      final merchant = match.group(1)?.trim() ?? '';
      if (merchant.isNotEmpty && merchant.length < 30) {
        final cleanMerchant = merchant
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

  static String _parseBank(String address, String body) {
    final cleanAddress = address.toUpperCase();
    final cleanBody = body.toUpperCase();
    if (cleanAddress.contains('HDFC') || cleanBody.contains('HDFC')) {
      return 'HDFC';
    }
    if (cleanAddress.contains('SBI') || cleanBody.contains('SBI')) return 'SBI';
    if (cleanAddress.contains('ICICI') || cleanBody.contains('ICICI')) {
      return 'ICICI';
    }
    if (cleanAddress.contains('AXIS') || cleanBody.contains('AXIS')) {
      return 'AXIS';
    }
    if (cleanAddress.contains('KOTAK') || cleanBody.contains('KOTAK')) {
      return 'KOTAK';
    }
    if (cleanAddress.contains('PNB') || cleanBody.contains('PNB')) return 'PNB';
    if (cleanAddress.contains('CANARA') || cleanBody.contains('CANARA')) {
      return 'CANARA';
    }
    if (cleanAddress.contains('INDUSIND') || cleanBody.contains('INDUSIND')) {
      return 'INDUSIND';
    }
    if (cleanAddress.contains('YESBANK') ||
        cleanBody.contains('YES BANK') ||
        cleanBody.contains('YESB')) {
      return 'YES';
    }
    if (cleanAddress.contains('FEDERAL') || cleanBody.contains('FEDERAL')) {
      return 'FEDERAL';
    }
    if (cleanAddress.contains('IDFCFIRST') ||
        cleanBody.contains('IDFC FIRST') ||
        cleanBody.contains('IDFCFIRST')) {
      return 'IDFC';
    }
    if (cleanAddress.contains('PAYTM') || cleanBody.contains('PAYTM')) {
      return 'PAYTM';
    }
    if (cleanAddress.contains('AIRTEL') || cleanBody.contains('AIRTEL')) {
      return 'AIRTEL';
    }
    if (cleanAddress.contains('BOI') || cleanBody.contains('BANK OF INDIA')) {
      return 'BOI';
    }
    if (cleanAddress.contains('UNION') || cleanBody.contains('UNION BANK')) {
      return 'UNION';
    }

    // Fallback: extract from shortcode (e.g., AD-HDFCBK → HDFCBK)
    if (cleanAddress.length >= 6) {
      final parts = cleanAddress.split('-');
      if (parts.length > 1) return parts[1];
      return cleanAddress.substring(cleanAddress.length - 4);
    }
    return 'Bank';
  }

  /// Optionally parse a UPI / transaction reference ID from the SMS body.
  static String? parseRefId(String body) {
    final match = _refRegex.firstMatch(body);
    return match?.group(1)?.trim();
  }

  static String parseCategory(String merchant, bool isCredit) {
    if (isCredit) {
      final m = merchant.toLowerCase();
      if (m.contains('salary')) return 'Salary';
      if (m.contains('interest')) return 'Interest';
      if (m.contains('freelance') || m.contains('upwork')) return 'Freelance';
      return 'Received from Others';
    }

    final m = merchant.toLowerCase();
    if (m.contains('zomato') ||
        m.contains('swiggy') ||
        m.contains('food') ||
        m.contains('dining') ||
        m.contains('restaurant') ||
        m.contains('dominos') ||
        m.contains('eats') ||
        m.contains('blinkit') ||
        m.contains('zepto') ||
        m.contains('bigbasket')) {
      return 'Food & Dining';
    }
    if (m.contains('uber') ||
        m.contains('ola') ||
        m.contains('cab') ||
        m.contains('transport') ||
        m.contains('metro') ||
        m.contains('petrol') ||
        m.contains('fuel') ||
        m.contains('irctc') ||
        m.contains('redbus') ||
        m.contains('indigo') ||
        m.contains('air india')) {
      return 'Transport';
    }
    if (m.contains('netflix') ||
        m.contains('spotify') ||
        m.contains('movie') ||
        m.contains('cinema') ||
        m.contains('entertainment') ||
        m.contains('hotstar') ||
        m.contains('prime')) {
      return 'Entertainment';
    }
    if (m.contains('bill') ||
        m.contains('electricity') ||
        m.contains('water') ||
        m.contains('phone') ||
        m.contains('recharge') ||
        m.contains('utility')) {
      return 'Bills / Utilities';
    }
    if (m.contains('amazon') ||
        m.contains('flipkart') ||
        m.contains('shopping') ||
        m.contains('grocery') ||
        m.contains('groceries') ||
        m.contains('store') ||
        m.contains('jiomart') ||
        m.contains('dmart')) {
      return 'Shopping';
    }
    if (m.contains('apollo') ||
        m.contains('practo') ||
        m.contains('pharmeasy') ||
        m.contains('1mg') ||
        m.contains('hospital') ||
        m.contains('clinic') ||
        m.contains('medical')) {
      return 'Health & Fitness';
    }
    if (m.contains('lic') || m.contains('insurance') || m.contains('policy')) {
      return 'Bills / Utilities';
    }
    return 'Other';
  }
}
