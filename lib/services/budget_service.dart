import 'dart:developer';
import 'package:backend_client/backend_client.dart';
import 'api_client.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  /// Adds a new budget to the remote server.
  Future<BudgetEntry?> addBudget(BudgetEntry entry) async {
    try {
      return await apiClient.client.budgetEntry.addBudgetEntry(entry);
    } catch (e) {
      log('Error adding budget: $e');
      return null;
    }
  }

  /// Updates an existing budget on the remote server.
  Future<BudgetEntry?> updateBudget(BudgetEntry entry) async {
    try {
      return await apiClient.client.budgetEntry.updateBudgetEntry(entry);
    } catch (e) {
      log('Error updating budget: $e');
      return null;
    }
  }

  /// Deletes a budget from the remote server.
  Future<bool> deleteBudget(int id) async {
    try {
      return await apiClient.client.budgetEntry.deleteBudgetEntry(id);
    } catch (e) {
      log('Error deleting budget: $e');
      return false;
    }
  }

  /// Fetches all budgets for a given user email from the remote server.
  Future<List<BudgetEntry>> getBudgets(String email) async {
    try {
      return await apiClient.client.budgetEntry.getBudgetEntries(email);
    } catch (e) {
      log('Error fetching budgets: $e');
      return [];
    }
  }
}
