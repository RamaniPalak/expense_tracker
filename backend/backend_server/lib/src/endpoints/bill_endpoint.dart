import 'dart:convert';
import 'package:serverpod/serverpod.dart';

class BillEntryEndpoint extends Endpoint {
  bool _tableEnsured = false;

  Future<void> _ensureTableExists(Session session) async {
    if (_tableEnsured) return;
    try {
      await session.db.unsafeQuery('''
CREATE TABLE IF NOT EXISTS "bill_entry" (
    "id" bigserial PRIMARY KEY,
    "title" text NOT NULL,
    "amount" double precision NOT NULL,
    "dueDate" text NOT NULL,
    "endDate" text,
    "category" text NOT NULL,
    "isPaid" boolean NOT NULL DEFAULT false,
    "isRecurring" boolean NOT NULL DEFAULT false,
    "userEmail" text NOT NULL
);
''');
      _tableEnsured = true;
    } catch (e) {
      session.log('bill_entry table check warning: $e');
    }
  }

  Future<String> addBillEntry(Session session, String userEmail, String title,
      double amount, String dueDate, String? endDate, String category,
      bool isPaid, bool isRecurring) async {
    await _ensureTableExists(session);
    final cleanEmail = userEmail.trim().toLowerCase();
    final safeTitle = title.replaceAll("'", "''");
    final safeCategory = category.replaceAll("'", "''");
    final endDateSql = endDate != null ? "'$endDate'" : 'NULL';

    final existing = await session.db.unsafeQuery("""
SELECT id FROM "bill_entry"
WHERE LOWER(TRIM("userEmail")) = '$cleanEmail'
  AND "title" = '$safeTitle'
  AND "dueDate" = '$dueDate';
""");

    if (existing.isNotEmpty) {
      final id = existing.first.first as int;
      await session.db.unsafeQuery("""
UPDATE "bill_entry"
SET "amount" = $amount,
    "endDate" = $endDateSql,
    "category" = '$safeCategory',
    "isPaid" = $isPaid,
    "isRecurring" = $isRecurring
WHERE "id" = $id;
""");
      return jsonEncode({
        'id': id, 'userEmail': cleanEmail, 'title': title,
        'amount': amount, 'dueDate': dueDate, 'endDate': endDate,
        'category': category, 'isPaid': isPaid, 'isRecurring': isRecurring,
      });
    } else {
      final result = await session.db.unsafeQuery("""
INSERT INTO "bill_entry" ("userEmail", "title", "amount", "dueDate", "endDate", "category", "isPaid", "isRecurring")
VALUES ('$cleanEmail', '$safeTitle', $amount, '$dueDate', $endDateSql, '$safeCategory', $isPaid, $isRecurring)
RETURNING id;
""");
      final id = result.first.first as int;
      return jsonEncode({
        'id': id, 'userEmail': cleanEmail, 'title': title,
        'amount': amount, 'dueDate': dueDate, 'endDate': endDate,
        'category': category, 'isPaid': isPaid, 'isRecurring': isRecurring,
      });
    }
  }

  Future<String> updateBillEntry(Session session, int remoteId,
      double amount, String dueDate, String? endDate, String category,
      bool isPaid, bool isRecurring) async {
    await _ensureTableExists(session);
    final safeCategory = category.replaceAll("'", "''");
    final endDateSql = endDate != null ? "'$endDate'" : 'NULL';
    await session.db.unsafeQuery("""
UPDATE "bill_entry"
SET "amount" = $amount,
    "dueDate" = '$dueDate',
    "endDate" = $endDateSql,
    "category" = '$safeCategory',
    "isPaid" = $isPaid,
    "isRecurring" = $isRecurring
WHERE "id" = $remoteId;
""");
    return jsonEncode({'success': true, 'id': remoteId});
  }

  Future<bool> deleteBillEntry(Session session, int remoteId) async {
    await _ensureTableExists(session);
    await session.db.unsafeQuery(
        'DELETE FROM "bill_entry" WHERE "id" = $remoteId;');
    return true;
  }

  Future<String> getBillEntries(Session session, String userEmail) async {
    await _ensureTableExists(session);
    final cleanEmail = userEmail.trim().toLowerCase();
    final result = await session.db.unsafeQuery("""
SELECT id, "userEmail", title, amount, "dueDate", "endDate", category, "isPaid", "isRecurring"
FROM "bill_entry"
WHERE LOWER(TRIM("userEmail")) = '$cleanEmail'
ORDER BY "dueDate" ASC;
""");
    final list = result
        .map((row) => {
              'id': row[0] as int,
              'userEmail': row[1] as String,
              'title': row[2] as String,
              'amount': (row[3] as num).toDouble(),
              'dueDate': row[4] as String,
              'endDate': row[5] as String?,
              'category': row[6] as String,
              'isPaid': row[7] as bool,
              'isRecurring': row[8] as bool,
            })
        .toList();
    return jsonEncode(list);
  }
}
