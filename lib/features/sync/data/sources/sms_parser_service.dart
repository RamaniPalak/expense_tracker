import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../models/parsed_sms_transaction.dart';

class SmsParserService {
  // Regex to extract amount (e.g., Rs. 500, Rs 500, INR 500, 500.00 Rs)
  static final RegExp _amountRegex = RegExp(
    r'(?:Rs\.?|INR)\s*([0-9,]+(?:\.[0-9]{2})?)'
    r'|([0-9,]+(?:\.[0-9]{2})?)\s*(?:Rs\.?|INR)',
    caseSensitive: false,
  );

  // Regex to extract merchant/payee name
  static final RegExp _merchantRegex = RegExp(
    r'(?:at|to|spent\s+on|vpa|info)\s+([A-Za-z0-9\s\*\-\.]+?)(?:\s+on|\s+for|\s+Ref|\s+Ref\b|\s+UPI|\s+limit|\.|\b)',
    caseSensitive: false,
  );

  /// Check if the sender or message body is typical of a bank transaction
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

  /// Parse a list of raw SMS messages into transaction objects
  static List<ParsedSmsTransaction> parseMessages(List<SmsMessage> messages) {
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
      // The amount can be in group 1 (for Rs. X) or group 2 (for X Rs)
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
        // Clean up common fillers
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
    if (cleanAddress.contains('HDFC') || body.toUpperCase().contains('HDFC')) {
      return 'HDFC';
    }
    if (cleanAddress.contains('SBI') || body.toUpperCase().contains('SBI')) {
      return 'SBI';
    }
    if (cleanAddress.contains('ICICI') || body.toUpperCase().contains('ICICI')) {
      return 'ICICI';
    }
    if (cleanAddress.contains('AXIS') || body.toUpperCase().contains('AXIS')) {
      return 'AXIS';
    }
    if (cleanAddress.contains('KOTAK') || body.toUpperCase().contains('KOTAK')) {
      return 'KOTAK';
    }

    // Extract last 4 chars of shortcode or default
    if (cleanAddress.length >= 6) {
      final parts = cleanAddress.split('-');
      if (parts.length > 1) return parts[1];
      return cleanAddress.substring(cleanAddress.length - 4);
    }
    return 'Bank';
  }

  static String parseCategory(String merchant, bool isCredit) {
    if (isCredit) {
      final cleanMerchant = merchant.toLowerCase();
      if (cleanMerchant.contains('salary')) return 'Salary';
      if (cleanMerchant.contains('interest')) return 'Interest';
      if (cleanMerchant.contains('freelance') || cleanMerchant.contains('upwork')) return 'Freelance';
      return 'Received from Others';
    }

    final cleanMerchant = merchant.toLowerCase();
    if (cleanMerchant.contains('zomato') ||
        cleanMerchant.contains('swiggy') ||
        cleanMerchant.contains('food') ||
        cleanMerchant.contains('dining') ||
        cleanMerchant.contains('restaurant') ||
        cleanMerchant.contains('dominos') ||
        cleanMerchant.contains('eats')) {
      return 'Food & Dining';
    }
    if (cleanMerchant.contains('uber') ||
        cleanMerchant.contains('ola') ||
        cleanMerchant.contains('cab') ||
        cleanMerchant.contains('transport') ||
        cleanMerchant.contains('metro') ||
        cleanMerchant.contains('petrol') ||
        cleanMerchant.contains('fuel')) {
      return 'Transport';
    }
    if (cleanMerchant.contains('netflix') ||
        cleanMerchant.contains('spotify') ||
        cleanMerchant.contains('movie') ||
        cleanMerchant.contains('cinema') ||
        cleanMerchant.contains('entertainment')) {
      return 'Entertainment';
    }
    if (cleanMerchant.contains('bill') ||
        cleanMerchant.contains('electricity') ||
        cleanMerchant.contains('water') ||
        cleanMerchant.contains('phone') ||
        cleanMerchant.contains('recharge') ||
        cleanMerchant.contains('utility')) {
      return 'Bills / Utilities';
    }
    if (cleanMerchant.contains('amazon') ||
        cleanMerchant.contains('flipkart') ||
        cleanMerchant.contains('shopping') ||
        cleanMerchant.contains('grocery') ||
        cleanMerchant.contains('groceries') ||
        cleanMerchant.contains('store')) {
      return 'Shopping';
    }
    return 'Other';
  }
}
