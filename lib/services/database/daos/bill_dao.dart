import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/api_client.dart';

class BillDao {
  final Future<Database> Function() _getDatabase;
  final ValueNotifier<List<BillModel>> billsNotifier;
  final Future<void> Function(String email)? onBillsRefreshed;

  BillDao({
    required Future<Database> Function() getDatabase,
    ValueNotifier<List<BillModel>>? notifier,
    this.onBillsRefreshed,
  })  : _getDatabase = getDatabase,
        billsNotifier = notifier ?? ValueNotifier([]);

  Future<void> insertBill(BillModel bill) async {
    final db = await _getDatabase();
    final localId = await db.insert('bills', bill.toMap());

    // Schedule notification for the newly added bill if not paid
    if (!bill.isPaid) {
      final dueDate = bill.dueDate;
      final reminderDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        9,
        0,
      ).subtract(const Duration(days: 1));

      await NotificationService.instance.scheduleBillReminder(
        id: localId,
        title: 'Upcoming Bill: ${bill.title}',
        body:
            'Your bill of ₹${bill.amount.toStringAsFixed(2)} is due tomorrow.',
        scheduledDate: reminderDate,
      );
    }

    await refreshBills(bill.userEmail);

    // Push to remote in background
    try {
      final resJson = await apiClient.client.billEntry.addBillEntry(
        bill.userEmail.trim().toLowerCase(),
        bill.title,
        bill.amount,
        bill.dueDate.toIso8601String(),
        bill.endDate?.toIso8601String(),
        bill.category,
        bill.isPaid,
        bill.isRecurring,
      );
      if (resJson != null && resJson.isNotEmpty) {
        final res = jsonDecode(resJson) as Map<String, dynamic>;
        if (res['id'] != null) {
          await db.update(
            'bills',
            {'remoteId': res['id'] as int},
            where: 'id = ?',
            whereArgs: [localId],
          );
          await refreshBills(bill.userEmail);
        }
      }
    } catch (e) {
      debugPrint('Background insert bill remote failed: $e');
    }
  }

  Future<List<BillModel>> getBills(String? email) async {
    if (email == null) return [];
    final db = await _getDatabase();
    const orderBy = 'dueDate ASC';
    final result = await db.query(
      'bills',
      where: 'LOWER(TRIM(userEmail)) = ?',
      whereArgs: [email.trim().toLowerCase()],
      orderBy: orderBy,
    );

    return result.map((json) => BillModel.fromMap(json)).toList();
  }

  Future<void> refreshBills(String? email,
      {bool syncFromRemote = false}) async {
    if (email == null) return;
    final cleanEmail = email.trim().toLowerCase();
    billsNotifier.value = await getBills(cleanEmail);
    if (onBillsRefreshed != null) {
      await onBillsRefreshed!(cleanEmail);
    }

    if (syncFromRemote) {
      syncBillsWithRemote(cleanEmail).then((_) async {
        billsNotifier.value = await getBills(cleanEmail);
        if (onBillsRefreshed != null) {
          await onBillsRefreshed!(cleanEmail);
        }
      }).catchError((e) => debugPrint('Background bill sync error: $e'));
    }
  }

  Future<void> deleteBill(int id, String? email) async {
    final db = await _getDatabase();

    // Get remoteId before deleting
    final existing = await db.query(
      'bills',
      columns: ['remoteId'],
      where: 'id = ?',
      whereArgs: [id],
    );
    final remoteId =
        existing.isNotEmpty ? existing.first['remoteId'] as int? : null;

    await db.delete(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
    );
    await NotificationService.instance.cancelNotification(id);
    await refreshBills(email);

    // Delete from remote in background
    if (remoteId != null) {
      try {
        await apiClient.client.billEntry.deleteBillEntry(remoteId);
      } catch (e) {
        debugPrint('Background delete bill remote failed: $e');
      }
    }
  }

  Future<void> updateBill(BillModel bill) async {
    final db = await _getDatabase();
    await db.update(
      'bills',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );

    if (bill.id != null) {
      await NotificationService.instance.cancelNotification(bill.id!);

      if (!bill.isPaid) {
        final dueDate = bill.dueDate;
        final reminderDate = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          9,
          0,
        ).subtract(const Duration(days: 1));

        await NotificationService.instance.scheduleBillReminder(
          id: bill.id!,
          title: 'Upcoming Bill: ${bill.title}',
          body:
              'Your bill of ₹${bill.amount.toStringAsFixed(2)} is due tomorrow.',
          scheduledDate: reminderDate,
        );
      }
    }

    await refreshBills(bill.userEmail);

    // Push update to remote in background
    if (bill.remoteId != null) {
      try {
        await apiClient.client.billEntry.updateBillEntry(
          bill.remoteId!,
          bill.amount,
          bill.dueDate.toIso8601String(),
          bill.endDate?.toIso8601String(),
          bill.category,
          bill.isPaid,
          bill.isRecurring,
        );
      } catch (e) {
        debugPrint('Background update bill remote failed: $e');
      }
    } else {
      // If no remoteId yet, push as new entry and capture remoteId
      try {
        final resJson = await apiClient.client.billEntry.addBillEntry(
          bill.userEmail.trim().toLowerCase(),
          bill.title,
          bill.amount,
          bill.dueDate.toIso8601String(),
          bill.endDate?.toIso8601String(),
          bill.category,
          bill.isPaid,
          bill.isRecurring,
        );
        if (resJson != null && resJson.isNotEmpty) {
          final res = jsonDecode(resJson) as Map<String, dynamic>;
          if (res['id'] != null && bill.id != null) {
            await db.update(
              'bills',
              {'remoteId': res['id'] as int},
              where: 'id = ?',
              whereArgs: [bill.id],
            );
          }
        }
      } catch (e) {
        debugPrint('Background upsert bill remote failed: $e');
      }
    }
  }

  Future<void> syncBillsWithRemote(String email) async {
    if (email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();
    try {
      final String? jsonString =
          await apiClient.client.billEntry.getBillEntries(cleanEmail);
      if (jsonString == null || jsonString.isEmpty) return;

      final List<dynamic> remoteEntries =
          jsonDecode(jsonString) as List<dynamic>;
      final db = await _getDatabase();

      for (var entry in remoteEntries) {
        final Map<String, dynamic> map =
            Map<String, dynamic>.from(entry as Map);
        final remoteId = map['id'] as int?;
        if (remoteId == null) continue;

        final title = map['title'] as String;
        final amount = (map['amount'] as num).toDouble();
        final dueDate = map['dueDate'] as String;
        final endDate = map['endDate'] as String?;
        final category = map['category'] as String;
        final isPaid = map['isPaid'] as bool? ?? false;
        final isRecurring = map['isRecurring'] as bool? ?? false;

        final existing = await db.query(
          'bills',
          where:
              'remoteId = ? OR (LOWER(TRIM(userEmail)) = ? AND title = ? AND dueDate = ?)',
          whereArgs: [remoteId, cleanEmail, title, dueDate],
        );

        if (existing.isEmpty) {
          final model = BillModel(
            remoteId: remoteId,
            title: title,
            amount: amount,
            dueDate: DateTime.parse(dueDate),
            endDate: endDate != null ? DateTime.parse(endDate) : null,
            category: category,
            isPaid: isPaid,
            isRecurring: isRecurring,
            userEmail: cleanEmail,
          );
          await db.insert('bills', model.toMap());
        } else {
          final localId = existing.first['id'] as int;
          await db.update(
            'bills',
            {
              'remoteId': remoteId,
              'amount': amount,
              'dueDate': dueDate,
              'endDate': endDate,
              'category': category,
              'isPaid': isPaid ? 1 : 0,
              'isRecurring': isRecurring ? 1 : 0,
            },
            where: 'id = ?',
            whereArgs: [localId],
          );
        }
      }
    } catch (e) {
      debugPrint('Bills sync failed: $e');
    }
  }
}
