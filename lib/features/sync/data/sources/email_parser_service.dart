import '../models/parsed_email_transaction.dart';

class EmailParserService {
  // Regex to extract amount — supports ₹, Rs., Rs, INR, Rupees, $, USD, €, EUR, £, GBP
  static final RegExp _amountRegex = RegExp(
    r'(?:Rs\.?|INR|Rupees|₹|\$|USD|€|EUR|£|GBP)\s*([0-9,]+(?:\.[0-9]{1,2})?)'
    r'|([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:Rs\.?|INR|Rupees|₹|\$|USD|€|EUR|£|GBP)',
    caseSensitive: false,
  );

  // Regex to extract merchant/payee name from body or subject
  static final RegExp _merchantRegex = RegExp(
    r'(?:at|to|paid\s+to|spent\s+on|vpa|info|vendor|merchant|towards|in\s+favour\s+of)\s+([A-Za-z0-9\s\*\-\.\&]+?)(?:\s+on|\s+for|\s+Ref|\s+UPI|\s+limit|\.|\b|\,|\n)',
    caseSensitive: false,
  );

  // Regex to extract UPI / Transaction Reference numbers
  static final RegExp _refRegex = RegExp(
    r'(?:UPI\s*Ref(?:\s*No)?|Ref\s*No|Txn\s*ID|Transaction\s*ID|UTR|URN)[.:\s]+([A-Z0-9]+)',
    caseSensitive: false,
  );

  // Regex to capture UPI info formatted like "Info: UPI/394201/Starbucks"
  static final RegExp _upiInfoRegex = RegExp(
    r'UPI\/[0-9]+\/([A-Za-z0-9\s\*\-\.\&]+)',
    caseSensitive: false,
  );

  /// Strips HTML tags and decodes common HTML entities often found in email payloads
  static String cleanEmailText(String input) {
    if (input.isEmpty) return '';

    // Replace line break tags with newlines/spaces
    String text = input
        .replaceAll(RegExp(r'<br\s*[\/]?>', caseSensitive: false), '\n')
        .replaceAll(
            RegExp(r'<\/(p|div|tr|li|h[1-6])>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ');

    // Decode common entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#8377;', '₹')
        .replaceAll('&rupee;', '₹')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    // Collapse excessive whitespace
    return text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  }

  /// Check if the email subject or snippet is indicative of a transaction alert
  static bool isTransactionalEmail(String subject, String body) {
    final cleanedSubject = cleanEmailText(subject).toLowerCase();
    final cleanedBody = cleanEmailText(body).toLowerCase();
    final combinedText = '$cleanedSubject $cleanedBody';

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
        combinedText.contains('purchase') ||
        combinedText.contains('order confirmed') ||
        combinedText.contains('bill payment') ||
        combinedText.contains('autopay') ||
        combinedText.contains('mandate');

    // Filter out pure OTP / authentication alerts that mention no financial activity
    final isPureOtp = (combinedText.contains('otp') ||
            combinedText.contains('verification code')) &&
        !combinedText.contains('debited') &&
        !combinedText.contains('credited') &&
        !combinedText.contains('spent') &&
        !combinedText.contains('paid');

    return hasAmount && hasKeywords && !isPureOtp;
  }

  /// Parse email metadata and text into a ParsedEmailTransaction object
  static ParsedEmailTransaction? parseEmail({
    required String subject,
    required String body,
    required DateTime date,
    String? sender,
  }) {
    final cleanSubject = cleanEmailText(subject);
    final cleanBody = cleanEmailText(body);

    if (!isTransactionalEmail(cleanSubject, cleanBody)) {
      return null;
    }

    final combinedText = '$cleanSubject\n$cleanBody';
    final amount = _parseAmount(combinedText);
    if (amount <= 0.0) return null;

    final isCredit = _checkIsCredit(combinedText);
    final merchant = _parseMerchant(cleanSubject, cleanBody, sender, isCredit);
    final bank = _parseBank(sender ?? '', combinedText);
    final category = parseCategory(merchant, isCredit);
    final snippet = cleanBody.length > 120
        ? '${cleanBody.substring(0, 117)}...'
        : cleanBody;

    final senderEmail = sender ?? 'bank.alerts@domain.com';

    return ParsedEmailTransaction(
      merchant: merchant,
      amount: amount,
      isCredit: isCredit,
      date: date,
      bank: bank,
      category: category,
      emailSubject: cleanSubject,
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
    if (cleanText.contains('debited') ||
        cleanText.contains('spent') ||
        cleanText.contains('paid') ||
        cleanText.contains('withdrawn') ||
        cleanText.contains('sent') ||
        cleanText.contains('charged')) {
      return false;
    }
    if (cleanText.contains('credited') ||
        cleanText.contains('received') ||
        cleanText.contains('added') ||
        cleanText.contains('refunded') ||
        cleanText.contains('refund') ||
        cleanText.contains('cashback') ||
        cleanText.contains('dividend') ||
        cleanText.contains('salary')) {
      return true;
    }
    return false; // Default to expense / debit
  }

  static String _parseMerchant(
    String subject,
    String body,
    String? sender,
    bool isCredit,
  ) {
    // 1. Check for UPI slash pattern first (e.g. Info: UPI/394201/Starbucks)
    final upiMatch = _upiInfoRegex.firstMatch(body);
    if (upiMatch != null) {
      final candidate = upiMatch.group(1)?.trim() ?? '';
      if (candidate.isNotEmpty && candidate.length < 35) {
        return candidate;
      }
    }

    // 2. Check standard merchant keywords across subject and body
    final combinedText = '$subject\n$body';
    final match = _merchantRegex.firstMatch(combinedText);
    if (match != null) {
      final rawMerchant = match.group(1)?.trim() ?? '';
      if (rawMerchant.isNotEmpty && rawMerchant.length < 35) {
        final cleanMerchant = rawMerchant
            .replaceAll(RegExp(r'\s+on$'), '')
            .replaceAll(RegExp(r'\s+for$'), '')
            .replaceAll(RegExp(r'\s+trip$'), '')
            .trim();
        // Ignore generic words like "account", "your a/c", "card"
        if (cleanMerchant.isNotEmpty &&
            !cleanMerchant.toLowerCase().startsWith('your a/c') &&
            !cleanMerchant.toLowerCase().startsWith('account')) {
          return cleanMerchant;
        }
      }
    }

    // 3. Fallback: Extract from known sender domain (e.g. info@swiggy.in -> Swiggy)
    if (sender != null && sender.isNotEmpty) {
      final senderMerchant = _extractMerchantFromSender(sender);
      if (senderMerchant != null) {
        return senderMerchant;
      }
    }

    return isCredit ? 'Income Alert' : 'Expense Alert';
  }

  /// Extracts a recognizable merchant name from sender email address
  static String? _extractMerchantFromSender(String sender) {
    final lower = sender.toLowerCase();
    if (lower.contains('swiggy')) return 'Swiggy';
    if (lower.contains('zomato')) return 'Zomato';
    if (lower.contains('netflix')) return 'Netflix';
    if (lower.contains('amazon')) return 'Amazon';
    if (lower.contains('flipkart')) return 'Flipkart';
    if (lower.contains('uber')) return 'Uber';
    if (lower.contains('ola')) return 'Ola';
    if (lower.contains('blinkit')) return 'Blinkit';
    if (lower.contains('zepto')) return 'Zepto';
    if (lower.contains('myntra')) return 'Myntra';
    if (lower.contains('spotify')) return 'Spotify';
    if (lower.contains('apple')) return 'Apple';
    if (lower.contains('google')) return 'Google';
    if (lower.contains('starbucks')) return 'Starbucks';
    if (lower.contains('dominos')) return "Domino's";
    if (lower.contains('paypal')) return 'PayPal';
    if (lower.contains('razorpay')) return 'Razorpay';
    return null;
  }

  /// Optionally extract transaction / UPI reference ID
  static String? parseRefId(String text) {
    final match = _refRegex.firstMatch(text);
    return match?.group(1)?.trim();
  }

  static String _parseBank(String sender, String text) {
    final upperText = '$sender $text'.toUpperCase();
    if (upperText.contains('HDFC')) return 'HDFC Bank';
    if (upperText.contains('SBI') || upperText.contains('STATE BANK')) {
      return 'SBI';
    }
    if (upperText.contains('ICICI')) return 'ICICI Bank';
    if (upperText.contains('AXIS')) return 'Axis Bank';
    if (upperText.contains('KOTAK')) return 'Kotak Bank';
    if (upperText.contains('PNB') || upperText.contains('PUNJAB NATIONAL')) {
      return 'PNB';
    }
    if (upperText.contains('CANARA')) return 'Canara Bank';
    if (upperText.contains('INDUSIND')) return 'IndusInd Bank';
    if (upperText.contains('YES BANK') ||
        upperText.contains('YESBANK') ||
        upperText.contains('YESB')) {
      return 'YES Bank';
    }
    if (upperText.contains('FEDERAL')) return 'Federal Bank';
    if (upperText.contains('IDFCFIRST') ||
        upperText.contains('IDFC FIRST') ||
        upperText.contains('IDFC')) {
      return 'IDFC FIRST Bank';
    }
    if (upperText.contains('BARODA') || upperText.contains('BOB')) {
      return 'Bank of Baroda';
    }
    if (upperText.contains('UNION BANK') || upperText.contains('UBI')) {
      return 'Union Bank';
    }
    if (upperText.contains('BANK OF INDIA') || upperText.contains('BOI')) {
      return 'Bank of India';
    }
    if (upperText.contains('STANDARD CHARTERED') || upperText.contains('SCB')) {
      return 'Standard Chartered';
    }
    if (upperText.contains('CITI') || upperText.contains('CITIBANK')) {
      return 'Citibank';
    }
    if (upperText.contains('HSBC')) return 'HSBC';
    if (upperText.contains('AIRTEL')) return 'Airtel Payments Bank';
    if (upperText.contains('PAYTM')) return 'Paytm';
    if (upperText.contains('RAZORPAY')) return 'Razorpay';
    if (upperText.contains('PAYPAL')) return 'PayPal';
    if (upperText.contains('CHASE')) return 'Chase';
    if (upperText.contains('AMEX') || upperText.contains('AMERICAN EXPRESS')) {
      return 'Amex';
    }

    return 'Bank Alert';
  }

  static String parseCategory(String merchant, bool isCredit) {
    final m = merchant.toLowerCase();

    if (isCredit) {
      if (m.contains('salary') || m.contains('payroll')) return 'Salary';
      if (m.contains('dividend') || m.contains('interest')) return 'Interest';
      if (m.contains('cashback') || m.contains('reward')) return 'Cashback';
      if (m.contains('refund')) return 'Refund';
      if (m.contains('freelance') ||
          m.contains('upwork') ||
          m.contains('fiverr')) {
        return 'Freelance';
      }
      return 'Received from Others';
    }

    // ── Expense Categories ──────────────────────────────────────────────────
    if (m.contains('zomato') ||
        m.contains('swiggy') ||
        m.contains('starbucks') ||
        m.contains('food') ||
        m.contains('dining') ||
        m.contains('restaurant') ||
        m.contains('dominos') ||
        m.contains('pizza') ||
        m.contains('burger') ||
        m.contains('mcdonald') ||
        m.contains('kfc') ||
        m.contains('cafe') ||
        m.contains('eats')) {
      return 'Food & Dining';
    }

    if (m.contains('blinkit') ||
        m.contains('zepto') ||
        m.contains('bigbasket') ||
        m.contains('instamart') ||
        m.contains('grocery') ||
        m.contains('groceries') ||
        m.contains('dmart') ||
        m.contains('jiomart') ||
        m.contains('supermarket')) {
      return 'Shopping';
    }

    if (m.contains('uber') ||
        m.contains('ola') ||
        m.contains('rapido') ||
        m.contains('cab') ||
        m.contains('transport') ||
        m.contains('metro') ||
        m.contains('petrol') ||
        m.contains('fuel') ||
        m.contains('irctc') ||
        m.contains('redbus') ||
        m.contains('indigo') ||
        m.contains('air india') ||
        m.contains('flight') ||
        m.contains('fastag')) {
      return 'Transport';
    }

    if (m.contains('netflix') ||
        m.contains('spotify') ||
        m.contains('movie') ||
        m.contains('cinema') ||
        m.contains('entertainment') ||
        m.contains('prime') ||
        m.contains('hotstar') ||
        m.contains('bookmyshow') ||
        m.contains('pvr') ||
        m.contains('inox') ||
        m.contains('youtube') ||
        m.contains('gaming')) {
      return 'Entertainment';
    }

    if (m.contains('bill') ||
        m.contains('electricity') ||
        m.contains('water') ||
        m.contains('phone') ||
        m.contains('recharge') ||
        m.contains('utility') ||
        m.contains('broadband') ||
        m.contains('wifi') ||
        m.contains('jio') ||
        m.contains('airtel') ||
        m.contains('bescom') ||
        m.contains('gas') ||
        m.contains('insurance') ||
        m.contains('lic') ||
        m.contains('policy')) {
      return 'Bills / Utilities';
    }

    if (m.contains('apollo') ||
        m.contains('practo') ||
        m.contains('pharmeasy') ||
        m.contains('1mg') ||
        m.contains('hospital') ||
        m.contains('clinic') ||
        m.contains('medical') ||
        m.contains('pharmacy') ||
        m.contains('cult') ||
        m.contains('gym')) {
      return 'Health & Fitness';
    }

    if (m.contains('amazon') ||
        m.contains('flipkart') ||
        m.contains('shopping') ||
        m.contains('myntra') ||
        m.contains('ajio') ||
        m.contains('meesho') ||
        m.contains('nykaa') ||
        m.contains('croma') ||
        m.contains('store') ||
        m.contains('retail')) {
      return 'Shopping';
    }

    return 'Other';
  }
}
