import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/sync/data/sources/statement_parser_service.dart';

void main() {
  group('StatementParserService Tests', () {
    test('Should parse standard 3-column CSV (Date, Narration, Amount)', () {
      const csv = '''Date,Description,Amount
15/09/2026,Swiggy Food Order,-450.00
16/09/2026,Client Project Payment,25000.00
17/09/2026,Uber Ride,-230.50
''';

      final results = StatementParserService.parseCsv(csv);

      expect(results.length, 3);

      expect(results[0].title, 'Swiggy Food Order');
      expect(results[0].amount, 450.0);
      expect(results[0].isIncome, isFalse);
      expect(results[0].category, 'Food & Dining');

      expect(results[1].title, 'Client Project Payment');
      expect(results[1].amount, 25000.0);
      expect(results[1].isIncome, isTrue);

      expect(results[2].title, 'Uber Ride');
      expect(results[2].amount, 230.5);
      expect(results[2].isIncome, isFalse);
      expect(results[2].category, 'Automobile / Car');
    });

    test('Should parse Indian Bank CSV with Debit and Credit columns', () {
      const csv = '''Date,Narration,Withdrawal,Deposit
10/08/2026,UPI-AMAZON PAY-SHOPPING,1899.00,0.00
11/08/2026,SALARY CREDIT NEFT ACME CORP,0.00,75000.00
12/08/2026,NETFLIX SUBSCRIPTION,649.00,
''';

      final results = StatementParserService.parseCsv(csv);

      expect(results.length, 3);

      expect(results[0].title, 'AMAZON PAY-SHOPPING');
      expect(results[0].amount, 1899.0);
      expect(results[0].isIncome, isFalse);
      expect(results[0].category, 'Shopping');

      expect(results[1].title, 'SALARY CREDIT NEFT ACME CORP');
      expect(results[1].amount, 75000.0);
      expect(results[1].isIncome, isTrue);
      expect(results[1].category, 'Salary');

      expect(results[2].title, 'NETFLIX SUBSCRIPTION');
      expect(results[2].amount, 649.0);
      expect(results[2].isIncome, isFalse);
      expect(results[2].category, 'Entertainment');
    });

    test('Should handle semicolon-separated and tab-separated CSVs', () {
      const semicolonCsv = '''Date;Description;Amount;Category
2026-09-01;Pharmacy Medicines;350.00;Health & Fitness
2026-09-02;Freelance Retainer;15000.00;Salary
''';

      final results = StatementParserService.parseCsv(semicolonCsv);

      expect(results.length, 2);
      expect(results[0].category, 'Health & Fitness');
      expect(results[0].amount, 350.0);
      expect(results[1].category, 'Salary');
      expect(results[1].amount, 15000.0);
    });

    test('Should auto-categorize various merchant patterns correctly', () {
      expect(
          StatementParserService.autoCategorize('Zomato Order 129',
              isIncome: false),
          'Food & Dining');
      expect(
          StatementParserService.autoCategorize('Ola Cabs Banglore',
              isIncome: false),
          'Automobile / Car');
      expect(
          StatementParserService.autoCategorize('Apollo Pharmacy Bill',
              isIncome: false),
          'Health & Fitness');
      expect(
          StatementParserService.autoCategorize(
              'Electricity Bill Torrent Power',
              isIncome: false),
          'Bills / Utilities');
      expect(
          StatementParserService.autoCategorize('Spotify Premium',
              isIncome: false),
          'Entertainment');
      expect(
          StatementParserService.autoCategorize('Amazon Retail Shopping',
              isIncome: false),
          'Shopping');
      expect(
          StatementParserService.autoCategorize('Monthly Payroll Salary',
              isIncome: true),
          'Salary');
    });

    test('Should generate valid sample demo CSV and parse it completely', () {
      final sampleCsv = StatementParserService.getSampleCsvStatement();
      expect(sampleCsv.isNotEmpty, isTrue);

      final parsed = StatementParserService.parseCsv(sampleCsv);
      expect(parsed.length, 6);

      final hasSalary = parsed.any((tx) => tx.isIncome && tx.amount == 65000.0);
      expect(hasSalary, isTrue);
    });

    test('Should return empty list for invalid or empty text', () {
      expect(StatementParserService.parseCsv(''), isEmpty);
      expect(StatementParserService.parseCsv('Random text without columns'),
          isEmpty);
    });
  });
}
