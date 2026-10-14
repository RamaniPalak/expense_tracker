import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/services/goal_service.dart';
import 'package:backend_client/backend_client.dart';

class GoalDao {
  final Future<Database> Function() _getDatabase;
  final ValueNotifier<List<GoalModel>> goalsNotifier;
  final Future<void> Function(String email)? onGoalsRefreshed;

  GoalDao({
    required Future<Database> Function() getDatabase,
    ValueNotifier<List<GoalModel>>? notifier,
    this.onGoalsRefreshed,
  })  : _getDatabase = getDatabase,
        goalsNotifier = notifier ?? ValueNotifier([]);

  Future<int> insertGoal(GoalModel goal) async {
    final db = await _getDatabase();

    // Save locally first for instant UI response (Offline-first approach)
    final localId = await db.insert('goals', goal.toMap());
    await refreshGoals(goal.userEmail);

    // Perform remote sync in background without blocking UI
    GoalService()
        .addGoal(GoalEntry(
      title: goal.title,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      targetDate: goal.targetDate,
      iconCode: goal.iconCode,
      colorValue: goal.colorValue,
      category: goal.category,
      userEmail: goal.userEmail,
      priority: goal.priority,
      status: goal.status,
      productUrl: goal.productUrl,
      autoDepositAmount: goal.autoDepositAmount,
      autoDepositDay: goal.autoDepositDay,
    ))
        .then((remoteEntry) async {
      if (remoteEntry != null && remoteEntry.id != null) {
        final updatedGoal =
            goal.copyWith(id: localId, remoteId: remoteEntry.id);
        await db.update('goals', updatedGoal.toMap(),
            where: 'id = ?', whereArgs: [localId]);
      }
    }).catchError(
            (e) => debugPrint("Background addGoal remote sync failed: $e"));

    return localId;
  }

  Future<List<GoalModel>> getGoals(String? email) async {
    if (email == null || email.trim().isEmpty) return [];
    final cleanEmail = email.trim().toLowerCase();
    final db = await _getDatabase();
    final result = await db.query(
      'goals',
      where: 'LOWER(TRIM(userEmail)) = ?',
      whereArgs: [cleanEmail],
      orderBy: 'targetDate ASC',
    );
    return result.map((json) => GoalModel.fromMap(json)).toList();
  }

  Future<void> refreshGoals(String? email,
      {bool syncFromRemote = false}) async {
    if (email == null || email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();
    goalsNotifier.value = await getGoals(cleanEmail);
    if (onGoalsRefreshed != null) {
      await onGoalsRefreshed!(cleanEmail);
    }

    if (syncFromRemote) {
      try {
        await syncGoalsWithRemote(cleanEmail);
        goalsNotifier.value = await getGoals(cleanEmail);
        if (onGoalsRefreshed != null) {
          await onGoalsRefreshed!(cleanEmail);
        }
      } catch (e) {
        debugPrint("Background goals sync error: $e");
      }
    }
  }

  Future<void> syncGoalsWithRemote(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final remoteGoals = await GoalService().getGoals(cleanEmail);
      final remoteContributions =
          await GoalService().getGoalContributions(cleanEmail);
      final db = await _getDatabase();

      for (GoalEntry entry in remoteGoals) {
        if (entry.id == null) continue;

        final existing = await db.query(
          'goals',
          where:
              'remoteId = ? OR (LOWER(TRIM(userEmail)) = ? AND LOWER(TRIM(title)) = ?)',
          whereArgs: [entry.id, cleanEmail, entry.title.trim().toLowerCase()],
        );

        if (existing.isEmpty) {
          final goal = GoalModel(
            remoteId: entry.id,
            title: entry.title,
            targetAmount: entry.targetAmount,
            currentAmount: entry.currentAmount,
            targetDate: entry.targetDate,
            iconCode: entry.iconCode,
            colorValue: entry.colorValue,
            category: entry.category,
            userEmail: cleanEmail,
            priority: entry.priority,
            status: entry.status,
            productUrl: entry.productUrl,
            autoDepositAmount: entry.autoDepositAmount,
            autoDepositDay: entry.autoDepositDay,
          );
          await db.insert('goals', goal.toMap());
        } else {
          final localId = existing.first['id'] as int;
          final updatedGoal = GoalModel(
            id: localId,
            remoteId: entry.id,
            title: entry.title,
            targetAmount: entry.targetAmount,
            currentAmount: entry.currentAmount,
            targetDate: entry.targetDate,
            iconCode: entry.iconCode,
            colorValue: entry.colorValue,
            category: entry.category,
            userEmail: cleanEmail,
            priority: entry.priority,
            status: entry.status,
            productUrl: entry.productUrl,
            autoDepositAmount: entry.autoDepositAmount,
            autoDepositDay: entry.autoDepositDay,
          );
          await db.update('goals', updatedGoal.toMap(),
              where: 'id = ?', whereArgs: [localId]);
        }
      }

      for (GoalContributionEntry contrib in remoteContributions) {
        if (contrib.id == null) continue;

        final matchingGoals = await db.query(
          'goals',
          where: 'remoteId = ?',
          whereArgs: [contrib.goalId],
        );
        final localGoalId = matchingGoals.isNotEmpty
            ? (matchingGoals.first['id'] as int)
            : contrib.goalId;

        final existing = await db.query(
          'goal_contributions',
          where: 'remoteId = ?',
          whereArgs: [contrib.id],
        );

        if (existing.isEmpty) {
          final contribution = GoalContributionModel(
            remoteId: contrib.id,
            goalId: localGoalId,
            amount: contrib.amount,
            date: contrib.date,
            note: contrib.note,
            type: contrib.type,
            userEmail: cleanEmail,
          );
          await db.insert('goal_contributions', contribution.toMap());
        }
      }
    } catch (e) {
      debugPrint('Goals sync failed: $e');
    }
  }

  Future<void> updateGoal(GoalModel goal) async {
    final db = await _getDatabase();
    await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );

    await refreshGoals(goal.userEmail);

    if (goal.remoteId != null) {
      GoalService()
          .updateGoal(GoalEntry(
            id: goal.remoteId,
            title: goal.title,
            targetAmount: goal.targetAmount,
            currentAmount: goal.currentAmount,
            targetDate: goal.targetDate,
            iconCode: goal.iconCode,
            colorValue: goal.colorValue,
            category: goal.category,
            userEmail: goal.userEmail,
            priority: goal.priority,
            status: goal.status,
            productUrl: goal.productUrl,
            autoDepositAmount: goal.autoDepositAmount,
            autoDepositDay: goal.autoDepositDay,
          ))
          .catchError((e) =>
              debugPrint("Background updateGoal remote sync failed: $e"));
    }
  }

  Future<void> deleteGoal(int id, String? email) async {
    final db = await _getDatabase();

    final rows = await db.query('goals', where: 'id = ?', whereArgs: [id]);
    final GoalModel? goal =
        rows.isNotEmpty ? GoalModel.fromMap(rows.first) : null;

    // Delete local records first
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
    await db.delete('goal_contributions', where: 'goalId = ?', whereArgs: [id]);
    await refreshGoals(email);

    // Perform remote deletion in background
    if (goal != null && goal.remoteId != null) {
      GoalService().deleteGoal(goal.remoteId!).catchError(
            (e) => debugPrint("Background deleteGoal remote sync failed: $e"),
          );
    }
  }

  Future<void> insertGoalContribution(
      GoalContributionModel contribution) async {
    final db = await _getDatabase();

    // Insert contribution locally first
    final localId = await db.insert('goal_contributions', contribution.toMap());

    // Perform remote sync in background
    GoalService()
        .addGoalContribution(GoalContributionEntry(
      goalId: contribution.goalId,
      amount: contribution.amount,
      date: contribution.date,
      note: contribution.note,
      type: contribution.type,
      userEmail: contribution.userEmail,
    ))
        .then((remoteContrib) async {
      if (remoteContrib != null && remoteContrib.id != null) {
        final updatedContrib = GoalContributionModel(
          id: localId,
          remoteId: remoteContrib.id,
          goalId: contribution.goalId,
          amount: contribution.amount,
          date: contribution.date,
          note: contribution.note,
          type: contribution.type,
          userEmail: contribution.userEmail,
        );
        await db.update('goal_contributions', updatedContrib.toMap(),
            where: 'id = ?', whereArgs: [localId]);
      }
    }).catchError((e) => debugPrint(
            "Background addGoalContribution remote sync failed: $e"));

    // Update goal current amount & status locally
    final goalRows = await db
        .query('goals', where: 'id = ?', whereArgs: [contribution.goalId]);
    if (goalRows.isNotEmpty) {
      final goal = GoalModel.fromMap(goalRows.first);
      final newAmount = contribution.isDeposit
          ? goal.currentAmount + contribution.amount
          : (goal.currentAmount - contribution.amount)
              .clamp(0.0, double.infinity);
      final isCompleted =
          newAmount >= goal.targetAmount && goal.targetAmount > 0;
      final newStatus = isCompleted
          ? 'Completed'
          : (goal.status == 'Completed' ? 'Active' : goal.status);
      await updateGoal(goal.copyWith(
        currentAmount: newAmount,
        status: newStatus,
      ));
    }
  }

  Future<List<GoalContributionModel>> getGoalContributions(
      int goalId, String? email) async {
    if (email == null || email.trim().isEmpty) return [];
    final cleanEmail = email.trim().toLowerCase();
    final db = await _getDatabase();
    final result = await db.query(
      'goal_contributions',
      where: 'goalId = ? AND LOWER(TRIM(userEmail)) = ?',
      whereArgs: [goalId, cleanEmail],
      orderBy: 'date DESC',
    );
    return result.map((json) => GoalContributionModel.fromMap(json)).toList();
  }

  Future<void> deleteGoalContribution(int contributionId, int goalId,
      double amount, String type, String? email) async {
    final db = await _getDatabase();

    final rows = await db.query('goal_contributions',
        where: 'id = ?', whereArgs: [contributionId]);
    final GoalContributionModel? contrib =
        rows.isNotEmpty ? GoalContributionModel.fromMap(rows.first) : null;

    // Delete local record first
    await db.delete('goal_contributions',
        where: 'id = ?', whereArgs: [contributionId]);

    // Perform remote deletion in background
    if (contrib != null && contrib.remoteId != null) {
      GoalService().deleteGoalContribution(contrib.remoteId!).catchError(
            (e) => debugPrint(
                "Background deleteGoalContribution remote sync failed: $e"),
          );
    }

    // Revert goal amount & status
    final goalRows =
        await db.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (goalRows.isNotEmpty) {
      final goal = GoalModel.fromMap(goalRows.first);
      final isDeposit = type == 'deposit';
      final newAmount = isDeposit
          ? (goal.currentAmount - amount).clamp(0.0, double.infinity)
          : goal.currentAmount + amount;
      final isCompleted =
          newAmount >= goal.targetAmount && goal.targetAmount > 0;
      final newStatus = isCompleted
          ? 'Completed'
          : (goal.status == 'Completed' ? 'Active' : goal.status);
      await updateGoal(goal.copyWith(
        currentAmount: newAmount,
        status: newStatus,
      ));
    }
  }
}
