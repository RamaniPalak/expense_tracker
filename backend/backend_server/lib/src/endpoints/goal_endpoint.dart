import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class GoalEntryEndpoint extends Endpoint {
  Future<GoalEntry> addGoalEntry(Session session, GoalEntry entry) async {
    return await GoalEntry.db.insertRow(session, entry);
  }

  Future<GoalEntry> updateGoalEntry(Session session, GoalEntry entry) async {
    return await GoalEntry.db.updateRow(session, entry);
  }

  Future<bool> deleteGoalEntry(Session session, int id) async {
    var result = await GoalEntry.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
    return result.isNotEmpty;
  }

  Future<List<GoalEntry>> getGoalEntries(Session session, String userEmail) async {
    return await GoalEntry.db.find(
      session,
      where: (t) => t.userEmail.equals(userEmail),
      orderBy: (t) => t.targetDate,
      orderDescending: false,
    );
  }

  Future<GoalContributionEntry> addGoalContribution(Session session, GoalContributionEntry entry) async {
    return await GoalContributionEntry.db.insertRow(session, entry);
  }

  Future<bool> deleteGoalContribution(Session session, int id) async {
    var result = await GoalContributionEntry.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
    return result.isNotEmpty;
  }

  Future<List<GoalContributionEntry>> getGoalContributions(Session session, String userEmail) async {
    return await GoalContributionEntry.db.find(
      session,
      where: (t) => t.userEmail.equals(userEmail),
      orderBy: (t) => t.date,
      orderDescending: true,
    );
  }
}
