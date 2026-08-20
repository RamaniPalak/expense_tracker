import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class ExpenseEntryEndpoint extends Endpoint {
  Future<ExpenseEntry> addExpenseEntry(
      Session session, ExpenseEntry expenseEntry) async {
    expenseEntry.userEmail = expenseEntry.userEmail.trim().toLowerCase();
    return await ExpenseEntry.db.insertRow(session, expenseEntry);
  }

  Future<ExpenseEntry> updateExpenseEntry(
      Session session, ExpenseEntry entry) async {
    entry.userEmail = entry.userEmail.trim().toLowerCase();
    return await ExpenseEntry.db.updateRow(session, entry);
  }

  Future<bool> deleteExpenseEntry(Session session, int id) async {
    var result = await ExpenseEntry.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
    return result.isNotEmpty;
  }

  Future<List<ExpenseEntry>> getExpenseEntries(
      Session session, String userEmail) async {
    final cleanEmail = userEmail.trim().toLowerCase();
    return await ExpenseEntry.db.find(
      session,
      where: (t) => t.userEmail.equals(cleanEmail) | t.userEmail.ilike(cleanEmail),
      orderBy: (t) => t.date,
      orderDescending: true,
    );
  }
}
