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

abstract class BudgetEntry implements _i1.SerializableModel {
  BudgetEntry._({
    this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    required this.userEmail,
  });

  factory BudgetEntry({
    int? id,
    required String category,
    required double amount,
    required int month,
    required int year,
    required String userEmail,
  }) = _BudgetEntryImpl;

  factory BudgetEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return BudgetEntry(
      id: jsonSerialization['id'] as int?,
      category: jsonSerialization['category'] as String,
      amount: (jsonSerialization['amount'] as num).toDouble(),
      month: jsonSerialization['month'] as int,
      year: jsonSerialization['year'] as int,
      userEmail: jsonSerialization['userEmail'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String category;

  double amount;

  int month;

  int year;

  String userEmail;

  /// Returns a shallow copy of this [BudgetEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BudgetEntry copyWith({
    int? id,
    String? category,
    double? amount,
    int? month,
    int? year,
    String? userEmail,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
      'userEmail': userEmail,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BudgetEntryImpl extends BudgetEntry {
  _BudgetEntryImpl({
    int? id,
    required String category,
    required double amount,
    required int month,
    required int year,
    required String userEmail,
  }) : super._(
          id: id,
          category: category,
          amount: amount,
          month: month,
          year: year,
          userEmail: userEmail,
        );

  /// Returns a shallow copy of this [BudgetEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BudgetEntry copyWith({
    Object? id = _Undefined,
    String? category,
    double? amount,
    int? month,
    int? year,
    String? userEmail,
  }) {
    return BudgetEntry(
      id: id is int? ? id : this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
