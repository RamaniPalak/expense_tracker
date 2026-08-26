import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class BudgetEntryEndpoint extends Endpoint {
  bool _tableEnsured = false;

  Future<void> _ensureTableExists(Session session) async {
    if (_tableEnsured) return;
    try {
      await session.db.unsafeQuery('''
CREATE TABLE IF NOT EXISTS "budget_entry" (
    "id" bigserial PRIMARY KEY,
    "category" text NOT NULL,
    "amount" double precision NOT NULL,
    "month" bigint NOT NULL,
    "year" bigint NOT NULL,
    "userEmail" text NOT NULL
);
''');
      _tableEnsured = true;
    } catch (e) {
      session.log('Auto table check warning: $e');
    }
  }

  Future<BudgetEntry> addBudgetEntry(
      Session session, BudgetEntry entry) async {
    await _ensureTableExists(session);
    entry.userEmail = entry.userEmail.trim().toLowerCase();
    
    // Check if a budget entry already exists for the same category, month, year, and email
    final existing = await BudgetEntry.db.find(
      session,
      where: (t) =>
          t.userEmail.equals(entry.userEmail) &
          t.category.equals(entry.category) &
          t.month.equals(entry.month) &
          t.year.equals(entry.year),
    );

    if (existing.isNotEmpty) {
      entry.id = existing.first.id;
      return await BudgetEntry.db.updateRow(session, entry);
    }

    return await BudgetEntry.db.insertRow(session, entry);
  }

  Future<BudgetEntry> updateBudgetEntry(
      Session session, BudgetEntry entry) async {
    await _ensureTableExists(session);
    entry.userEmail = entry.userEmail.trim().toLowerCase();
    return await BudgetEntry.db.updateRow(session, entry);
  }

  Future<bool> deleteBudgetEntry(Session session, int id) async {
    await _ensureTableExists(session);
    var result = await BudgetEntry.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
    return result.isNotEmpty;
  }

  Future<List<BudgetEntry>> getBudgetEntries(
      Session session, String userEmail) async {
    await _ensureTableExists(session);
    final cleanEmail = userEmail.trim().toLowerCase();
    return await BudgetEntry.db.find(
      session,
      where: (t) => t.userEmail.equals(cleanEmail) | t.userEmail.ilike(cleanEmail),
    );
  }

  // ── Dedicated Whole Month Budget Entry Table ─────────────────────────────
  Future<void> _ensureMonthlyTableExists(Session session) async {
    try {
      await session.db.unsafeQuery('''
CREATE TABLE IF NOT EXISTS "monthly_budget_entry" (
    "id" bigserial PRIMARY KEY,
    "amount" double precision NOT NULL,
    "month" bigint NOT NULL,
    "year" bigint NOT NULL,
    "userEmail" text NOT NULL
);
''');
    } catch (e) {
      session.log('Auto table check warning: $e');
    }
  }

  Future<Map<String, dynamic>> addMonthlyBudgetEntry(
      Session session, String userEmail, double amount, int month, int year) async {
    await _ensureMonthlyTableExists(session);
    final cleanEmail = userEmail.trim().toLowerCase();

    final existing = await session.db.unsafeQuery('''
SELECT id FROM "monthly_budget_entry"
WHERE LOWER(TRIM("userEmail")) = '$cleanEmail' AND "month" = $month AND "year" = $year;
''');

    if (existing.isNotEmpty) {
      final id = existing.first.first as int;
      await session.db.unsafeQuery('''
UPDATE "monthly_budget_entry"
SET "amount" = $amount
WHERE "id" = $id;
''');
      return {'id': id, 'userEmail': cleanEmail, 'amount': amount, 'month': month, 'year': year};
    } else {
      final result = await session.db.unsafeQuery('''
INSERT INTO "monthly_budget_entry" ("userEmail", "amount", "month", "year")
VALUES ('$cleanEmail', $amount, $month, $year)
RETURNING id;
''');
      final id = result.first.first as int;
      return {'id': id, 'userEmail': cleanEmail, 'amount': amount, 'month': month, 'year': year};
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyBudgetEntries(
      Session session, String userEmail) async {
    await _ensureMonthlyTableExists(session);
    final cleanEmail = userEmail.trim().toLowerCase();
    final result = await session.db.unsafeQuery('''
SELECT id, "userEmail", amount, month, year FROM "monthly_budget_entry"
WHERE LOWER(TRIM("userEmail")) = '$cleanEmail';
''');

    return result.map((row) => {
      'id': row[0] as int,
      'userEmail': row[1] as String,
      'amount': (row[2] as num).toDouble(),
      'month': (row[3] as num).toInt(),
      'year': (row[4] as num).toInt(),
    }).toList();
  }
}
