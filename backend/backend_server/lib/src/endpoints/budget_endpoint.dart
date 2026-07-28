import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class BudgetEntryEndpoint extends Endpoint {
  Future<BudgetEntry> addBudgetEntry(
      Session session, BudgetEntry entry) async {
    return await BudgetEntry.db.insertRow(session, entry);
  }

  Future<BudgetEntry> updateBudgetEntry(
      Session session, BudgetEntry entry) async {
    return await BudgetEntry.db.updateRow(session, entry);
  }

  Future<bool> deleteBudgetEntry(Session session, int id) async {
    var result = await BudgetEntry.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
    return result.isNotEmpty;
  }

  Future<List<BudgetEntry>> getBudgetEntries(
      Session session, String userEmail) async {
    return await BudgetEntry.db.find(
      session,
      where: (t) => t.userEmail.equals(userEmail),
    );
  }
}
