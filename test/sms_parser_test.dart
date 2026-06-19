import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:expense_tracker/features/sync/data/sources/sms_parser_service.dart';

void main() {
  group('SmsParserService Tests', () {
    test('Should identify transactional SMS', () {
      expect(SmsParserService.isTransactional('Your A/c XX1234 was debited by Rs. 1500.00 at Amazon.'), isTrue);
      expect(SmsParserService.isTransactional('Your A/c XX1234 was credited with INR 5000.00 by salary.'), isTrue);
      expect(SmsParserService.isTransactional('OTP for login is 123456.'), isFalse);
    });

    test('Should parse debit transaction correctly', () {
      final msg = SmsMessage.fromJson({
        'address': 'AD-HDFCBK',
        'body': 'Your a/c no. XX5678 has been debited by Rs 350.00 on 2026-06-01 at Zomato.',
        'date': DateTime.now().millisecondsSinceEpoch,
      });
      final parsed = SmsParserService.parseMessages([msg]);
      expect(parsed.length, 1);
      expect(parsed[0].amount, 350.0);
      expect(parsed[0].isCredit, isFalse);
      expect(parsed[0].merchant, 'Zomato');
      expect(parsed[0].bank, 'HDFC');
      expect(parsed[0].category, 'Food & Dining');
    });

    test('Should parse credit transaction correctly', () {
      final msg = SmsMessage.fromJson({
        'address': 'ICICIB',
        'body': 'Dear Customer, your account XX987 has been credited with INR 12000.00 by NEFT.',
        'date': DateTime.now().millisecondsSinceEpoch,
      });
      final parsed = SmsParserService.parseMessages([msg]);
      expect(parsed.length, 1);
      expect(parsed[0].amount, 12000.0);
      expect(parsed[0].isCredit, isTrue);
      expect(parsed[0].bank, 'ICICI');
      expect(parsed[0].category, 'Received from Others');
    });
  });
}
