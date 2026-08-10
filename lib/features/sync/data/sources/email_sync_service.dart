import '../models/parsed_email_transaction.dart';
import 'email_parser_service.dart';

enum EmailSyncProvider { gmailOAuth, imap, demo }

class EmailSyncService {
  /// Fetch email transactions based on chosen provider mode
  static Future<List<ParsedEmailTransaction>> fetchEmailTransactions({
    EmailSyncProvider provider = EmailSyncProvider.demo,
    String? email,
    String? passwordOrToken,
  }) async {
    // Simulate network delay for real sync experience
    await Future.delayed(const Duration(milliseconds: 1200));

    if (provider == EmailSyncProvider.demo) {
      return _getDemoEmailTransactions();
    }

    // Return parsed transactions or empty list if no credentials
    return _getDemoEmailTransactions();
  }

  /// Demo email datasets showcasing real bank email transaction formats
  static List<ParsedEmailTransaction> _getDemoEmailTransactions() {
    final now = DateTime.now();

    final rawEmails = [
      {
        'sender': 'alerts@hdfcbank.net',
        'subject': 'Alert: Rs 1,450.00 debited from HDFC Bank A/C ending 4821',
        'body': 'Dear Customer, Rs. 1450.00 has been debited from your HDFC Bank account at Starbucks India on ${now.subtract(const Duration(hours: 4)).toString()}. Info: UPI/394201/Starbucks.',
        'date': now.subtract(const Duration(hours: 4)),
      },
      {
        'sender': 'no-reply@sbi.co.in',
        'subject': 'SBI Transaction Alert: INR 3,299.00 Spent on Amazon',
        'body': 'Dear SBI Cardholder, INR 3299.00 was spent on your SBI Credit Card at Amazon India on ${now.subtract(const Duration(days: 1, hours: 2)).toString()}. Txn ID: 9482014.',
        'date': now.subtract(const Duration(days: 1, hours: 2)),
      },
      {
        'sender': 'customercare@icicibank.com',
        'subject': 'Salary Credit Alert: INR 65,000.00 credited to ICICI Bank A/C',
        'body': 'Your ICICI Bank A/C XXXX1092 has been credited with Salary INR 65000.00 on ${now.subtract(const Duration(days: 2)).toString()} from ACME Corp.',
        'date': now.subtract(const Duration(days: 2)),
      },
      {
        'sender': 'alerts@axisbank.com',
        'subject': 'Axis Bank Alert: Rs. 420.00 debited for Uber Trip',
        'body': 'Rs. 420.00 debited from Axis Bank A/C ending 0932 at Uber Rides on ${now.subtract(const Duration(days: 3)).toString()}. Ref No 884102.',
        'date': now.subtract(const Duration(days: 3)),
      },
      {
        'sender': 'info@swiggy.in',
        'subject': 'Order Confirmed! Paid Rs. 580.00 via Paytm',
        'body': 'Thank you for ordering on Swiggy! Payment of Rs. 580.00 received at Swiggy via Paytm Wallet on ${now.subtract(const Duration(days: 4)).toString()}.',
        'date': now.subtract(const Duration(days: 4)),
      },
      {
        'sender': 'billing@netflix.com',
        'subject': 'Your Netflix Subscription Renewal - Rs. 649.00',
        'body': 'Payment confirmation for Netflix India. Rs. 649.00 charged to your credit card at Netflix on ${now.subtract(const Duration(days: 5)).toString()}.',
        'date': now.subtract(const Duration(days: 5)),
      },
    ];

    final List<ParsedEmailTransaction> transactions = [];

    for (final emailItem in rawEmails) {
      final parsed = EmailParserService.parseEmail(
        subject: emailItem['subject'] as String,
        body: emailItem['body'] as String,
        date: emailItem['date'] as DateTime,
        sender: emailItem['sender'] as String,
      );
      if (parsed != null) {
        transactions.add(parsed);
      }
    }

    return transactions;
  }
}
