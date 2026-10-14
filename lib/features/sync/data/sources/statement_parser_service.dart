import 'package:intl/intl.dart';
import '../models/parsed_file_transaction.dart';

class StatementParserService {
  /// Parses a bank statement from raw CSV content into a list of [ParsedFileTransaction].
  static List<ParsedFileTransaction> parseCsv(
    String content, {
    String? defaultBank,
  }) {
    if (content.trim().isEmpty) return [];

    final lines = content
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    // Detect delimiter: check first non-empty line for comma, tab, or semicolon
    final delimiter = _detectDelimiter(lines.first);

    // Locate header row index
    int headerIndex = -1;
    Map<String, int> colMap = {};

    for (int i = 0; i < lines.length && i < 15; i++) {
      final cols = _splitRow(lines[i], delimiter)
          .map((c) => c.toLowerCase().trim())
          .toList();
      final map = _mapHeaderColumns(cols);
      if (map.containsKey('date') &&
          (map.containsKey('amount') ||
              map.containsKey('debit') ||
              map.containsKey('credit') ||
              map.containsKey('withdrawal') ||
              map.containsKey('deposit'))) {
        headerIndex = i;
        colMap = map;
        break;
      }
    }

    final transactions = <ParsedFileTransaction>[];

    final startIndex = headerIndex >= 0 ? headerIndex + 1 : 0;

    for (int i = startIndex; i < lines.length; i++) {
      final rawLine = lines[i];
      final cols = _splitRow(rawLine, delimiter);
      if (cols.isEmpty) continue;

      ParsedFileTransaction? tx;
      if (headerIndex >= 0) {
        tx = _parseRowWithHeaderMap(cols, colMap, defaultBank, rawLine);
      } else {
        tx = _parsePositionalFallback(cols, defaultBank, rawLine);
      }

      if (tx != null && tx.amount > 0) {
        transactions.add(tx);
      }
    }

    return transactions;
  }

  static String _detectDelimiter(String sampleLine) {
    if (sampleLine.contains('\t')) return '\t';
    if (sampleLine.contains(';') && !sampleLine.contains(',')) return ';';
    return ',';
  }

  static List<String> _splitRow(String row, String delimiter) {
    // Robust CSV splitter supporting quoted strings containing delimiters
    final result = <String>[];
    final buffer = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < row.length; i++) {
      final char = row[i];
      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == delimiter && !insideQuotes) {
        result.add(buffer.toString().trim().replaceAll(RegExp(r'^"|"$'), ''));
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString().trim().replaceAll(RegExp(r'^"|"$'), ''));
    return result;
  }

  static Map<String, int> _mapHeaderColumns(List<String> headers) {
    final map = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ').trim();
      if (h.contains('date') ||
          h.contains('txn date') ||
          h.contains('value date')) {
        map.putIfAbsent('date', () => i);
      } else if (h.contains('desc') ||
          h.contains('narration') ||
          h.contains('particular') ||
          h.contains('merchant') ||
          h.contains('remarks') ||
          h.contains('title')) {
        map.putIfAbsent('description', () => i);
      } else if (h.contains('debit') ||
          h.contains('withdrawal') ||
          h.contains('dr')) {
        map.putIfAbsent('debit', () => i);
      } else if (h.contains('credit') ||
          h.contains('deposit') ||
          h.contains('cr')) {
        map.putIfAbsent('credit', () => i);
      } else if (h.contains('amount') || h.contains('txn amount')) {
        map.putIfAbsent('amount', () => i);
      } else if (h.contains('type') ||
          h.contains('cr dr') ||
          h.contains('d c')) {
        map.putIfAbsent('type', () => i);
      } else if (h.contains('category')) {
        map.putIfAbsent('category', () => i);
      }
    }
    return map;
  }

  static ParsedFileTransaction? _parseRowWithHeaderMap(
    List<String> cols,
    Map<String, int> colMap,
    String? defaultBank,
    String rawLine,
  ) {
    final dateCol = colMap['date'];
    if (dateCol == null || dateCol >= cols.length) return null;
    final date = _parseDate(cols[dateCol]);
    if (date == null) return null;

    final descCol = colMap['description'];
    String description = 'Transaction';
    if (descCol != null && descCol < cols.length && cols[descCol].isNotEmpty) {
      description = cols[descCol];
    }

    double amount = 0.0;
    bool isIncome = false;

    // Check separate debit / credit columns
    if (colMap.containsKey('debit') || colMap.containsKey('credit')) {
      final debitCol = colMap['debit'];
      final creditCol = colMap['credit'];

      double debitAmt = 0.0;
      double creditAmt = 0.0;

      if (debitCol != null && debitCol < cols.length) {
        debitAmt = _parseAmount(cols[debitCol]);
      }
      if (creditCol != null && creditCol < cols.length) {
        creditAmt = _parseAmount(cols[creditCol]);
      }

      if (creditAmt > 0) {
        amount = creditAmt;
        isIncome = true;
      } else if (debitAmt > 0) {
        amount = debitAmt;
        isIncome = false;
      } else {
        return null;
      }
    } else if (colMap.containsKey('amount')) {
      final amtCol = colMap['amount']!;
      if (amtCol >= cols.length) return null;
      final rawAmountStr = cols[amtCol];
      final isNegative = rawAmountStr.contains('-');
      amount = _parseAmount(rawAmountStr);

      if (colMap.containsKey('type')) {
        final typeCol = colMap['type']!;
        if (typeCol < cols.length) {
          final typeStr = cols[typeCol].toLowerCase();
          isIncome = typeStr.contains('cr') ||
              typeStr.contains('credit') ||
              typeStr.contains('deposit');
        }
      } else {
        isIncome = !isNegative &&
            (rawAmountStr.toLowerCase().contains('cr') ||
                rawAmountStr.trim().startsWith('+') ||
                description.toLowerCase().contains('credited') ||
                description.toLowerCase().contains('salary') ||
                description.toLowerCase().contains('client') ||
                description.toLowerCase().contains('payment received') ||
                description.toLowerCase().contains('deposit'));
      }
    }

    if (amount <= 0) return null;

    String category = 'Other';
    if (colMap.containsKey('category')) {
      final catCol = colMap['category']!;
      if (catCol < cols.length && cols[catCol].isNotEmpty) {
        category = cols[catCol];
      }
    } else {
      category = autoCategorize(description, isIncome: isIncome);
    }

    return ParsedFileTransaction(
      title: _cleanTitle(description),
      amount: amount,
      date: date,
      category: category,
      isIncome: isIncome,
      bankName: defaultBank ?? _detectBank(description),
      rawLine: rawLine,
    );
  }

  static ParsedFileTransaction? _parsePositionalFallback(
    List<String> cols,
    String? defaultBank,
    String rawLine,
  ) {
    if (cols.length < 3) return null;

    final date = _parseDate(cols[0]);
    if (date == null) return null;

    final description = cols[1];
    final amount = _parseAmount(cols[2]);
    if (amount <= 0) return null;

    bool isIncome = false;
    if (cols.length >= 4) {
      final typeStr = cols[3].toLowerCase();
      isIncome = typeStr.contains('cr') ||
          typeStr.contains('credit') ||
          typeStr.contains('income');
    }

    final category = cols.length >= 5
        ? cols[4]
        : autoCategorize(description, isIncome: isIncome);

    return ParsedFileTransaction(
      title: _cleanTitle(description),
      amount: amount,
      date: date,
      category: category,
      isIncome: isIncome,
      bankName: defaultBank ?? _detectBank(description),
      rawLine: rawLine,
    );
  }

  static DateTime? _parseDate(String dateStr) {
    final clean =
        dateStr.trim().replaceAll(RegExp(r'[^0-9a-zA-Z\/\-\.\s]'), '');
    if (clean.isEmpty) return null;

    final patterns = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'MM/dd/yyyy',
      'dd MMM yyyy',
      'dd-MMM-yyyy',
      'dd.MM.yyyy',
      'dd/MM/yy',
      'dd-MM-yy',
    ];

    for (final pattern in patterns) {
      try {
        return DateFormat(pattern).parseStrict(clean);
      } catch (_) {}
    }

    return DateTime.tryParse(clean);
  }

  static double _parseAmount(String amountStr) {
    final clean = amountStr
        .replaceAll('₹', '')
        .replaceAll('\$', '')
        .replaceAll('Rs.', '')
        .replaceAll('INR', '')
        .replaceAll('CR', '')
        .replaceAll('DR', '')
        .replaceAll('cr', '')
        .replaceAll('dr', '')
        .replaceAll(',', '')
        .replaceAll('-', '')
        .replaceAll('+', '')
        .trim();
    return double.tryParse(clean) ?? 0.0;
  }

  static String _cleanTitle(String raw) {
    var title = raw.trim();
    // Remove common statement noise prefixes like "UPI/P2A/", "NEFT-", "POS ", "IMPS/"
    title = title.replaceAll(
        RegExp(r'^(UPI|NEFT|IMPS|RTGS|POS|ACH|NACH)[\/\-\s]+',
            caseSensitive: false),
        '');
    // Take first meaningful segment if there are slash-separated details
    if (title.contains('/')) {
      final parts = title
          .split('/')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        title = parts.first;
      }
    }
    if (title.length > 30) {
      title = '${title.substring(0, 27)}...';
    }
    return title.isNotEmpty ? title : 'Bank Transaction';
  }

  static String _detectBank(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('hdfc')) return 'HDFC Bank';
    if (lower.contains('sbi') || lower.contains('state bank')) return 'SBI';
    if (lower.contains('icici')) return 'ICICI Bank';
    if (lower.contains('axis')) return 'Axis Bank';
    if (lower.contains('kotak')) return 'Kotak Bank';
    if (lower.contains('pnb')) return 'PNB';
    return 'Bank';
  }

  /// Automatically categorize merchant / narration into standard application categories.
  static String autoCategorize(String text, {required bool isIncome}) {
    if (isIncome) {
      final lower = text.toLowerCase();
      if (lower.contains('salary') ||
          lower.contains('payroll') ||
          lower.contains('stipend')) {
        return 'Salary';
      }
      if (lower.contains('interest') ||
          lower.contains('dividend') ||
          lower.contains('mutual') ||
          lower.contains('stock')) {
        return 'Investments';
      }
      if (lower.contains('bonus') ||
          lower.contains('reward') ||
          lower.contains('cashback')) {
        return 'Bonus';
      }
      if (lower.contains('refund')) {
        return 'Refunds';
      }
      return 'Other Income';
    }

    final lower = text.toLowerCase();
    if (lower.contains('swiggy') ||
        lower.contains('zomato') ||
        lower.contains('starbucks') ||
        lower.contains('restaurant') ||
        lower.contains('cafe') ||
        lower.contains('food') ||
        lower.contains('mcdonald') ||
        lower.contains('burger') ||
        lower.contains('pizza')) {
      return 'Food & Dining';
    }
    if (lower.contains('uber') ||
        lower.contains('ola') ||
        lower.contains('irctc') ||
        lower.contains('railway') ||
        lower.contains('flight') ||
        lower.contains('indigo') ||
        lower.contains('air') ||
        lower.contains('petrol') ||
        lower.contains('fuel') ||
        lower.contains('shell') ||
        lower.contains('hpcl') ||
        lower.contains('bpcl') ||
        lower.contains('toll')) {
      return 'Automobile / Car';
    }
    if (lower.contains('hospital') ||
        lower.contains('pharmacy') ||
        lower.contains('apollo') ||
        lower.contains('medicine') ||
        lower.contains('clinic') ||
        lower.contains('doctor')) {
      return 'Health & Fitness';
    }
    if (lower.contains('electricity') ||
        lower.contains('power') ||
        lower.contains('water') ||
        lower.contains('gas') ||
        lower.contains('bill') ||
        lower.contains('recharge') ||
        lower.contains('airtel') ||
        lower.contains('jio') ||
        lower.contains('broadband') ||
        lower.contains('bescom')) {
      return 'Bills / Utilities';
    }
    if (lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('prime') ||
        lower.contains('hotstar') ||
        lower.contains('movie') ||
        lower.contains('cinema') ||
        lower.contains('pvr')) {
      return 'Entertainment';
    }
    if (lower.contains('amazon') ||
        lower.contains('flipkart') ||
        lower.contains('myntra') ||
        lower.contains('zara') ||
        lower.contains('shopping') ||
        lower.contains('retail')) {
      return 'Shopping';
    }
    if (lower.contains('rent') ||
        lower.contains('maintenance') ||
        lower.contains('society')) {
      return 'Home / Rent';
    }

    return 'Other';
  }

  /// Sample demo statement content for immediate testing.
  static String getSampleCsvStatement() {
    final now = DateTime.now();
    final f = DateFormat('dd/MM/yyyy');
    final d1 = f.format(now.subtract(const Duration(days: 1)));
    final d2 = f.format(now.subtract(const Duration(days: 2)));
    final d3 = f.format(now.subtract(const Duration(days: 3)));
    final d4 = f.format(now.subtract(const Duration(days: 5)));
    final d5 = f.format(now.subtract(const Duration(days: 7)));
    final d6 = f.format(now.subtract(const Duration(days: 10)));

    return '''Date,Narration,Withdrawal,Deposit,Category
$d1,Swiggy Order #8921,480.00,,Food & Dining
$d2,Uber India Mobility,320.00,,Automobile / Car
$d3,Monthly Salary - Tech Corp,,65000.00,Salary
$d4,Electricity BESCOM Bill,1450.00,,Bills / Utilities
$d5,Amazon Retail Marketplace,2199.00,,Shopping
$d6,Netflix Monthly Subscription,649.00,,Entertainment
''';
  }
}
