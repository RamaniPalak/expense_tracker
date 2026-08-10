import 'dart:developer';
import 'package:backend_client/backend_client.dart';
import 'api_client.dart';

class GoalService {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;
  GoalService._internal();

  /// Adds a new goal to the remote server.
  Future<GoalEntry?> addGoal(GoalEntry entry) async {
    try {
      return await apiClient.client.goalEntry.addGoalEntry(entry);
    } catch (e) {
      log('Error adding remote goal: $e');
      return null;
    }
  }

  /// Updates an existing goal on the remote server.
  Future<GoalEntry?> updateGoal(GoalEntry entry) async {
    try {
      return await apiClient.client.goalEntry.updateGoalEntry(entry);
    } catch (e) {
      log('Error updating remote goal: $e');
      return null;
    }
  }

  /// Deletes a goal from the remote server.
  Future<bool> deleteGoal(int id) async {
    try {
      return await apiClient.client.goalEntry.deleteGoalEntry(id);
    } catch (e) {
      log('Error deleting remote goal: $e');
      return false;
    }
  }

  /// Fetches all goals for a given user email from the remote server.
  Future<List<GoalEntry>> getGoals(String email) async {
    try {
      return await apiClient.client.goalEntry.getGoalEntries(email);
    } catch (e) {
      log('Error fetching remote goals: $e');
      return [];
    }
  }

  /// Adds a goal contribution to the remote server.
  Future<GoalContributionEntry?> addGoalContribution(GoalContributionEntry entry) async {
    try {
      return await apiClient.client.goalEntry.addGoalContribution(entry);
    } catch (e) {
      log('Error adding remote goal contribution: $e');
      return null;
    }
  }

  /// Deletes a goal contribution from the remote server.
  Future<bool> deleteGoalContribution(int id) async {
    try {
      return await apiClient.client.goalEntry.deleteGoalContribution(id);
    } catch (e) {
      log('Error deleting remote goal contribution: $e');
      return false;
    }
  }

  /// Fetches all goal contributions for a given user email from the remote server.
  Future<List<GoalContributionEntry>> getGoalContributions(String email) async {
    try {
      return await apiClient.client.goalEntry.getGoalContributions(email);
    } catch (e) {
      log('Error fetching remote goal contributions: $e');
      return [];
    }
  }
}
