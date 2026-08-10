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

abstract class GoalContributionEntry implements _i1.SerializableModel {
  GoalContributionEntry._({
    this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
    required this.type,
    required this.userEmail,
  });

  factory GoalContributionEntry({
    int? id,
    required int goalId,
    required double amount,
    required DateTime date,
    String? note,
    required String type,
    required String userEmail,
  }) = _GoalContributionEntryImpl;

  factory GoalContributionEntry.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return GoalContributionEntry(
      id: jsonSerialization['id'] as int?,
      goalId: jsonSerialization['goalId'] as int,
      amount: (jsonSerialization['amount'] as num).toDouble(),
      date: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['date']),
      note: jsonSerialization['note'] as String?,
      type: jsonSerialization['type'] as String,
      userEmail: jsonSerialization['userEmail'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int goalId;

  double amount;

  DateTime date;

  String? note;

  String type;

  String userEmail;

  /// Returns a shallow copy of this [GoalContributionEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GoalContributionEntry copyWith({
    int? id,
    int? goalId,
    double? amount,
    DateTime? date,
    String? note,
    String? type,
    String? userEmail,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'goalId': goalId,
      'amount': amount,
      'date': date.toJson(),
      if (note != null) 'note': note,
      'type': type,
      'userEmail': userEmail,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GoalContributionEntryImpl extends GoalContributionEntry {
  _GoalContributionEntryImpl({
    int? id,
    required int goalId,
    required double amount,
    required DateTime date,
    String? note,
    required String type,
    required String userEmail,
  }) : super._(
          id: id,
          goalId: goalId,
          amount: amount,
          date: date,
          note: note,
          type: type,
          userEmail: userEmail,
        );

  /// Returns a shallow copy of this [GoalContributionEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GoalContributionEntry copyWith({
    Object? id = _Undefined,
    int? goalId,
    double? amount,
    DateTime? date,
    Object? note = _Undefined,
    String? type,
    String? userEmail,
  }) {
    return GoalContributionEntry(
      id: id is int? ? id : this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note is String? ? note : this.note,
      type: type ?? this.type,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
