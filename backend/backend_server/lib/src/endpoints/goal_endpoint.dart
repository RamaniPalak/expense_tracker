import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class GoalEntryEndpoint extends Endpoint {
  bool _tablesEnsured = false;

  Future<void> _ensureTablesExist(Session session) async {
    if (_tablesEnsured) return;
    try {
      await session.db.unsafeQuery('''
CREATE TABLE IF NOT EXISTS "goal_entry" (
    "id" bigserial PRIMARY KEY,
    "title" text NOT NULL,
    "targetAmount" double precision NOT NULL,
    "currentAmount" double precision NOT NULL,
    "targetDate" timestamp without time zone NOT NULL,
    "iconCode" bigint NOT NULL,
    "colorValue" bigint NOT NULL,
    "category" text NOT NULL,
    "userEmail" text NOT NULL,
    "priority" text NOT NULL,
    "status" text NOT NULL,
    "productUrl" text,
    "autoDepositAmount" double precision NOT NULL,
    "autoDepositDay" bigint NOT NULL
);
CREATE TABLE IF NOT EXISTS "goal_contribution_entry" (
    "id" bigserial PRIMARY KEY,
    "goalId" bigint NOT NULL,
    "amount" double precision NOT NULL,
    "date" timestamp without time zone NOT NULL,
    "note" text,
    "type" text NOT NULL,
    "userEmail" text NOT NULL
);
''');
      _tablesEnsured = true;
    } catch (e) {
      session.log('Auto table check warning: $e');
    }
  }

  Future<GoalEntry> addGoalEntry(Session session, GoalEntry entry) async {
    await _ensureTablesExist(session);
    entry.userEmail = entry.userEmail.trim().toLowerCase();
    return await GoalEntry.db.insertRow(session, entry);
  }

  Future<GoalEntry> updateGoalEntry(Session session, GoalEntry entry) async {
    await _ensureTablesExist(session);
    entry.userEmail = entry.userEmail.trim().toLowerCase();
    return await GoalEntry.db.updateRow(session, entry);
  }

  Future<bool> deleteGoalEntry(Session session, int id) async {
    await _ensureTablesExist(session);
    var result = await GoalEntry.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
    return result.isNotEmpty;
  }

  Future<List<GoalEntry>> getGoalEntries(Session session, String userEmail) async {
    await _ensureTablesExist(session);
    final cleanEmail = userEmail.trim().toLowerCase();
    return await GoalEntry.db.find(
      session,
      where: (t) => t.userEmail.equals(cleanEmail) | t.userEmail.ilike(cleanEmail),
      orderBy: (t) => t.targetDate,
      orderDescending: false,
    );
  }

  Future<GoalContributionEntry> addGoalContribution(Session session, GoalContributionEntry entry) async {
    await _ensureTablesExist(session);
    entry.userEmail = entry.userEmail.trim().toLowerCase();
    return await GoalContributionEntry.db.insertRow(session, entry);
  }

  Future<bool> deleteGoalContribution(Session session, int id) async {
    await _ensureTablesExist(session);
    var result = await GoalContributionEntry.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
    return result.isNotEmpty;
  }

  Future<List<GoalContributionEntry>> getGoalContributions(Session session, String userEmail) async {
    await _ensureTablesExist(session);
    final cleanEmail = userEmail.trim().toLowerCase();
    return await GoalContributionEntry.db.find(
      session,
      where: (t) => t.userEmail.equals(cleanEmail) | t.userEmail.ilike(cleanEmail),
      orderBy: (t) => t.date,
      orderDescending: true,
    );
  }
}
