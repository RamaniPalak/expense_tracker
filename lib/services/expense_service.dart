import 'dart:developer';

import 'package:backend_client/backend_client.dart';
import 'api_client.dart';

class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal();

  /// Adds a new expense to the remote server.
  Future<ExpenseEntry?> addExpense(ExpenseEntry entry) async {
    try {
      return await apiClient.client.expenseEntry.addExpenseEntry(entry);
    } catch (e) {
      log('Error adding expense: $e');
      return null;
    }
  }

  /// Deletes an expense from the remote server.
  Future<bool> deleteExpense(int id) async {
    try {
      return await apiClient.client.expenseEntry.deleteExpenseEntry(id);
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  /// Fetches all expenses for a given user email from the remote server.
  Future<List<ExpenseEntry>> getExpenses(String email) async {
    try {
      return await apiClient.client.expenseEntry.getExpenseEntries(email);
    } catch (e) {
      print('Error fetching expenses: $e');
      return [];
    }
  }
}
