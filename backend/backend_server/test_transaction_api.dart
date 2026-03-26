import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final baseUrl = 'http://localhost:8080/expenseEntry';

  // 1. Add a transaction
  print('--- Testing addExpenseEntry ---');
  final addResponse = await http.post(
    Uri.parse('$baseUrl/addExpenseEntry'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'expenseEntry': {
        'title': 'Test Coffee',
        'amount': 5.50,
        'date': DateTime.now().toIso8601String(),
        'category': 'Food',
        'isIncome': false,
        'userEmail': 'test@example.com',
      }
    }),
  );

  print('Add Status: ${addResponse.statusCode}');
  print('Add Response: ${addResponse.body}');

  if (addResponse.statusCode == 200) {
    final entry = jsonDecode(addResponse.body);
    final id = entry['id'];
    print('Added Entry ID: $id');

    if (id == null) {
      print(
          'Error: ID is null. Retrying to find the entry via getExpenseEntries...');
    }

    // 2. Get transactions for user
    print('\n--- Testing getExpenseEntries ---');
    final getResponse = await http.post(
      Uri.parse('$baseUrl/getExpenseEntries'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userEmail': 'test@example.com'}),
    );
    print('Get Status: ${getResponse.statusCode}');
    final entries = jsonDecode(getResponse.body) as List;
    print('Entries Count: ${entries.length}');

    final entryId = id ?? (entries.isNotEmpty ? entries.first['id'] : null);

    if (entryId != null) {
      // 3. Delete the transaction
      print('\n--- Testing deleteExpenseEntry with ID: $entryId ---');
      final deleteResponse = await http.post(
        Uri.parse('$baseUrl/deleteExpenseEntry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': entryId}),
      );
      print('Delete Status: ${deleteResponse.statusCode}');
      print('Delete Response: ${deleteResponse.body}');

      // 4. Verify deletion
      print('\n--- Verifying deletion ---');
      final verifyResponse = await http.post(
        Uri.parse('$baseUrl/getExpenseEntries'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userEmail': 'test@example.com'}),
      );
      final remainingEntries = jsonDecode(verifyResponse.body) as List;
      print('Verify Response Count: ${remainingEntries.length}');
    } else {
      print('Could not find an ID to delete.');
    }
  }
}
