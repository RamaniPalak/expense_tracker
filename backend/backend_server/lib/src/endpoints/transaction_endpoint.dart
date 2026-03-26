import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class ExpenseEntryEndpoint extends Endpoint {
  Future<ExpenseEntry> addExpenseEntry(
      Session session, ExpenseEntry expenseEntry) async {
    return await ExpenseEntry.db.insertRow(session, expenseEntry);
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
    return await ExpenseEntry.db.find(
      session,
      where: (t) => t.userEmail.equals(userEmail),
      orderBy: (t) => t.date,
      orderDescending: true,
    );
  }
}
