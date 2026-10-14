import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/sync/data/sources/email_parser_service.dart';
import 'package:expense_tracker/features/sync/data/models/parsed_email_transaction.dart';

void main() {
  group('EmailParserService Tests', () {
    test('Should identify transactional emails', () {
      expect(
        EmailParserService.isTransactionalEmail(
          'Alert: Rs 1,450.00 debited from HDFC Bank',
          'Dear Customer, Rs. 1450.00 has been debited at Starbucks.',
        ),
        isTrue,
      );

      expect(
        EmailParserService.isTransactionalEmail(
          'Weekly Newsletter',
          'Check out our new products and updates.',
        ),
        isFalse,
      );
    });

    test('Should parse debit email correctly', () {
      final now = DateTime.now();
      final parsed = EmailParserService.parseEmail(
        subject: 'Axis Bank Alert: Rs. 420.00 debited for Uber Trip',
        body:
            'Rs. 420.00 debited from Axis Bank A/C ending 0932 at Uber on ${now.toString()}. Ref No 884102.',
        date: now,
        sender: 'alerts@axisbank.com',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 420.0);
      expect(parsed.isCredit, isFalse);
      expect(parsed.merchant, 'Uber');
      expect(parsed.bank, 'Axis Bank');
      expect(parsed.category, 'Transport');
    });

    test('Should parse salary credit email correctly', () {
      final now = DateTime.now();
      final parsed = EmailParserService.parseEmail(
        subject: 'Credit Alert: INR 65,000.00 credited',
        body:
            'Your A/C XXXX1092 has been credited with INR 65000.00 on ${now.toString()} towards Salary from ACME Corp.',
        date: now,
        sender: 'customercare@icicibank.com',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 65000.0);
      expect(parsed.isCredit, isTrue);
      expect(parsed.bank, 'ICICI Bank');
      expect(parsed.category, 'Salary');
    });

    test('Should parse HTML formatted email with ₹ symbol and decode entities',
        () {
      final now = DateTime.now();
      const htmlBody = '''
        <div style="font-family: sans-serif;">
          <p>Dear Customer,</p>
          <p>Your HDFC Bank account has been <strong>debited</strong> by &#8377;&nbsp;1,450.00 at Starbucks on 2026-09-16.</p>
          <p>Info: UPI/394201/Starbucks</p>
        </div>
      ''';

      final parsed = EmailParserService.parseEmail(
        subject: 'Debit Alert: &#8377; 1,450.00 debited',
        body: htmlBody,
        date: now,
        sender: 'alerts@hdfcbank.net',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 1450.0);
      expect(parsed.isCredit, isFalse);
      expect(parsed.merchant, 'Starbucks');
      expect(parsed.bank, 'HDFC Bank');
      expect(parsed.category, 'Food & Dining');
    });

    test('Should fallback to sender domain when merchant not in body', () {
      final now = DateTime.now();
      final parsed = EmailParserService.parseEmail(
        subject: 'Order Confirmed! Paid Rs. 580.00',
        body:
            'Thank you for your order. Payment of Rs. 580.00 has been debited from your card.',
        date: now,
        sender: 'info@swiggy.in',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 580.0);
      expect(parsed.merchant, 'Swiggy');
      expect(parsed.category, 'Food & Dining');
    });

    test('Should identify newer Indian banks like PNB and IDFC FIRST', () {
      final now = DateTime.now();
      final pnbParsed = EmailParserService.parseEmail(
        subject: 'PNB Alert: Rs. 1,200.00 debited',
        body:
            'Rs 1200.00 debited from PNB A/C at Blinkit on ${now.toString()}. Ref No 987654.',
        date: now,
        sender: 'alerts@pnb.co.in',
      );

      expect(pnbParsed, isNotNull);
      expect(pnbParsed!.bank, 'PNB');
      expect(pnbParsed.merchant, 'Blinkit');
      expect(pnbParsed.category, 'Shopping');

      final idfcParsed = EmailParserService.parseEmail(
        subject: 'IDFC FIRST Bank Alert: Rs. 999.00 spent',
        body:
            'Your card was charged Rs 999.00 at Netflix on ${now.toString()}.',
        date: now,
        sender: 'alerts@idfcfirstbank.com',
      );

      expect(idfcParsed, isNotNull);
      expect(idfcParsed!.bank, 'IDFC FIRST Bank');
      expect(idfcParsed.category, 'Entertainment');
    });

    test('Should extract reference ID and filter out pure OTPs', () {
      expect(
        EmailParserService.parseRefId(
            'Payment of Rs. 500 completed. Ref No: UTR984210948.'),
        'UTR984210948',
      );

      expect(
        EmailParserService.isTransactionalEmail(
          'Your OTP for Login',
          'Use verification code 481920 to login to your banking portal.',
        ),
        isFalse,
      );
    });
  });

  group('ParsedEmailTransaction Equality & Dedup Tests', () {
    test(
        'Transactions with same amount, credit status, and minute date are equal',
        () {
      final t1 = ParsedEmailTransaction(
        merchant: 'Amazon',
        amount: 999.0,
        isCredit: false,
        date: DateTime(2026, 9, 16, 14, 30, 15),
        bank: 'HDFC',
        category: 'Shopping',
        emailSubject: 'Order Confirmation',
        snippet: 'Paid 999',
        senderEmail: 'auto-confirm@amazon.in',
        selected: true,
      );

      final t2 = ParsedEmailTransaction(
        merchant: 'Amazon India',
        amount: 999.0,
        isCredit: false,
        date: DateTime(
            2026, 9, 16, 14, 30, 45), // 30 seconds later in same minute
        bank: 'HDFC',
        category: 'Shopping',
        emailSubject: 'Order Confirmation 2',
        snippet: 'Paid 999',
        senderEmail: 'auto-confirm@amazon.in',
        selected: false, // selection differs, but equality should hold
      );

      expect(t1 == t2, isTrue);
      expect(t1.hashCode, equals(t2.hashCode));

      // Sets should deduplicate them
      final set = {t1, t2};
      expect(set.length, 1);
    });

    test('Transactions with different amounts or types are not equal', () {
      final t1 = ParsedEmailTransaction(
        merchant: 'Amazon',
        amount: 999.0,
        isCredit: false,
        date: DateTime(2026, 9, 16, 14, 30),
        bank: 'HDFC',
        category: 'Shopping',
        emailSubject: 'Order',
        snippet: '999',
        senderEmail: 'alerts@hdfc.com',
      );

      final t2 = ParsedEmailTransaction(
        merchant: 'Amazon',
        amount: 999.0,
        isCredit: true, // credit vs debit
        date: DateTime(2026, 9, 16, 14, 30),
        bank: 'HDFC',
        category: 'Shopping',
        emailSubject: 'Refund',
        snippet: '999',
        senderEmail: 'alerts@hdfc.com',
      );

      expect(t1 == t2, isFalse);
    });
  });
}
