/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class ExpenseEntry implements _i1.SerializableModel {
  ExpenseEntry._({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isIncome,
    required this.userEmail,
  });

  factory ExpenseEntry({
    int? id,
    required String title,
    required double amount,
    required DateTime date,
    required String category,
    required bool isIncome,
    required String userEmail,
  }) = _ExpenseEntryImpl;

  factory ExpenseEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return ExpenseEntry(
      id: jsonSerialization['id'] as int?,
      title: jsonSerialization['title'] as String,
      amount: (jsonSerialization['amount'] as num).toDouble(),
      date: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['date']),
      category: jsonSerialization['category'] as String,
      isIncome: jsonSerialization['isIncome'] as bool,
      userEmail: jsonSerialization['userEmail'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String title;

  double amount;

  DateTime date;

  String category;

  bool isIncome;

  String userEmail;

  /// Returns a shallow copy of this [ExpenseEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ExpenseEntry copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    bool? isIncome,
    String? userEmail,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'date': date.toJson(),
      'category': category,
      'isIncome': isIncome,
      'userEmail': userEmail,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ExpenseEntryImpl extends ExpenseEntry {
  _ExpenseEntryImpl({
    int? id,
    required String title,
    required double amount,
    required DateTime date,
    required String category,
    required bool isIncome,
    required String userEmail,
  }) : super._(
          id: id,
          title: title,
          amount: amount,
          date: date,
          category: category,
          isIncome: isIncome,
          userEmail: userEmail,
        );

  /// Returns a shallow copy of this [ExpenseEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ExpenseEntry copyWith({
    Object? id = _Undefined,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    bool? isIncome,
    String? userEmail,
  }) {
    return ExpenseEntry(
      id: id is int? ? id : this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      isIncome: isIncome ?? this.isIncome,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
