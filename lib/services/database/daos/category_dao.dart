import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';

class CategoryDao {
  final Future<Database> Function() _getDatabase;
  final ValueNotifier<List<CategoryModel>> categoriesNotifier;

  CategoryDao({
    required Future<Database> Function() getDatabase,
    ValueNotifier<List<CategoryModel>>? notifier,
  })  : _getDatabase = getDatabase,
        categoriesNotifier = notifier ?? ValueNotifier([]);

  static final List<Map<String, dynamic>> defaultExpenseCategories = [
    {
      "name": "Automobile / Car",
      "emoji": "🚗",
      "iconCode": Icons.directions_car_filled_rounded.codePoint,
      "colorValue": 0xFFEF4444
    },
    {
      "name": "Bills / Utilities",
      "emoji": "🔌",
      "iconCode": Icons.electrical_services_rounded.codePoint,
      "colorValue": 0xFF06B6D4
    },
    {
      "name": "Charges / Fees",
      "emoji": "🏛️",
      "iconCode": Icons.account_balance_rounded.codePoint,
      "colorValue": 0xFF84CC16
    },
    {
      "name": "Education",
      "emoji": "📚",
      "iconCode": Icons.school_rounded.codePoint,
      "colorValue": 0xFFEC4899
    },
    {
      "name": "Entertainment",
      "emoji": "🎭",
      "iconCode": Icons.theater_comedy_rounded.codePoint,
      "colorValue": 0xFF10B981
    },
    {
      "name": "Food & Dining",
      "emoji": "🍔",
      "iconCode": Icons.fastfood_rounded.codePoint,
      "colorValue": 0xFFF59E0B
    },
    {
      "name": "Gifts & Similar",
      "emoji": "🎁",
      "iconCode": Icons.card_giftcard_rounded.codePoint,
      "colorValue": 0xFF0EA5E9
    },
    {
      "name": "Health & Fitness",
      "emoji": "💪",
      "iconCode": Icons.fitness_center_rounded.codePoint,
      "colorValue": 0xFF8B5CF6
    },
    {
      "name": "Housing",
      "emoji": "🏠",
      "iconCode": Icons.home_rounded.codePoint,
      "colorValue": 0xFFF97316
    },
    {
      "name": "Subscriptions",
      "emoji": "📱",
      "iconCode": Icons.phonelink_setup_rounded.codePoint,
      "colorValue": 0xFF3B82F6
    },
    {
      "name": "Travel",
      "emoji": "✈️",
      "iconCode": Icons.flight_takeoff_rounded.codePoint,
      "colorValue": 0xFF0EA5E9
    },
    {
      "name": "Other",
      "emoji": "🧩",
      "iconCode": Icons.category_rounded.codePoint,
      "colorValue": 0xFF64748B
    },
  ];

  static final List<Map<String, dynamic>> defaultIncomeCategories = [
    {
      "name": "Bonus",
      "emoji": "🌈",
      "iconCode": Icons.celebration_rounded.codePoint,
      "colorValue": 0xFFF43F5E
    },
    {
      "name": "Commission",
      "emoji": "🎉",
      "iconCode": Icons.percent_rounded.codePoint,
      "colorValue": 0xFF06B6D4
    },
    {
      "name": "Interest",
      "emoji": "🌱",
      "iconCode": Icons.trending_up_rounded.codePoint,
      "colorValue": 0xFF22C55E
    },
    {
      "name": "Investments",
      "emoji": "🚀",
      "iconCode": Icons.rocket_launch_rounded.codePoint,
      "colorValue": 0xFFEAB308
    },
    {
      "name": "Received from Others",
      "emoji": "📦",
      "iconCode": Icons.inventory_2_rounded.codePoint,
      "colorValue": 0xFF6366F1
    },
    {
      "name": "Rental Income",
      "emoji": "🛏️",
      "iconCode": Icons.home_rounded.codePoint,
      "colorValue": 0xFFF97316
    },
    {
      "name": "Salary",
      "emoji": "💼",
      "iconCode": Icons.work_rounded.codePoint,
      "colorValue": 0xFF22C55E
    },
    {
      "name": "Selling Assets",
      "emoji": "💰",
      "iconCode": Icons.monetization_on_rounded.codePoint,
      "colorValue": 0xFF0EA5E9
    },
    {
      "name": "Other",
      "emoji": "🧩",
      "iconCode": Icons.category_rounded.codePoint,
      "colorValue": 0xFF64748B
    },
  ];

  Future<void> ensureCategoriesSeeded(String email) async {
    final db = await _getDatabase();
    final existing = await db
        .query('categories', where: 'userEmail = ?', whereArgs: [email]);
    if (existing.isEmpty) {
      // Seed expense default categories
      for (var cat in defaultExpenseCategories) {
        await db.insert('categories', {
          'name': cat['name'],
          'emoji': cat['emoji'],
          'iconCode': cat['iconCode'],
          'colorValue': cat['colorValue'],
          'isIncome': 0,
          'isDefault': 1,
          'userEmail': email,
        });
      }
      // Seed income default categories
      for (var cat in defaultIncomeCategories) {
        await db.insert('categories', {
          'name': cat['name'],
          'emoji': cat['emoji'],
          'iconCode': cat['iconCode'],
          'colorValue': cat['colorValue'],
          'isIncome': 1,
          'isDefault': 1,
          'userEmail': email,
        });
      }
    }
  }

  Future<List<CategoryModel>> getCategories(String? email,
      {required bool isIncome}) async {
    if (email == null || email.trim().isEmpty) return [];
    final cleanEmail = email.trim().toLowerCase();
    await ensureCategoriesSeeded(cleanEmail);
    final db = await _getDatabase();
    final result = await db.query(
      'categories',
      where: 'LOWER(TRIM(userEmail)) = ? AND isIncome = ?',
      whereArgs: [cleanEmail, isIncome ? 1 : 0],
      orderBy: 'isDefault DESC, id ASC',
    );
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<void> refreshCategories(String? email) async {
    if (email == null || email.trim().isEmpty) return;
    final cleanEmail = email.trim().toLowerCase();
    await ensureCategoriesSeeded(cleanEmail);
    final db = await _getDatabase();
    final result = await db.query(
      'categories',
      where: 'LOWER(TRIM(userEmail)) = ?',
      whereArgs: [cleanEmail],
      orderBy: 'isDefault DESC, id ASC',
    );
    categoriesNotifier.value =
        result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<void> insertCategory(CategoryModel category) async {
    final db = await _getDatabase();
    await db.insert('categories', category.toMap());
    await refreshCategories(category.userEmail);
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await _getDatabase();
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    await refreshCategories(category.userEmail);
  }

  Future<void> deleteCategory(int id, String? email) async {
    final db = await _getDatabase();
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshCategories(email);
  }
}
