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
import 'budget_entry.dart' as _i2;
import 'expense_entry.dart' as _i3;
import 'goal_contribution_entry.dart' as _i4;
import 'goal_entry.dart' as _i5;
import 'user.dart' as _i6;
import 'package:backend_client/src/protocol/budget_entry.dart' as _i7;
import 'package:backend_client/src/protocol/goal_entry.dart' as _i8;
import 'package:backend_client/src/protocol/goal_contribution_entry.dart'
    as _i9;
import 'package:backend_client/src/protocol/expense_entry.dart' as _i10;
export 'budget_entry.dart';
export 'expense_entry.dart';
export 'goal_contribution_entry.dart';
export 'goal_entry.dart';
export 'user.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    if (t == _i2.BudgetEntry) {
      return _i2.BudgetEntry.fromJson(data) as T;
    }
    if (t == _i3.ExpenseEntry) {
      return _i3.ExpenseEntry.fromJson(data) as T;
    }
    if (t == _i4.GoalContributionEntry) {
      return _i4.GoalContributionEntry.fromJson(data) as T;
    }
    if (t == _i5.GoalEntry) {
      return _i5.GoalEntry.fromJson(data) as T;
    }
    if (t == _i6.User) {
      return _i6.User.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.BudgetEntry?>()) {
      return (data != null ? _i2.BudgetEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.ExpenseEntry?>()) {
      return (data != null ? _i3.ExpenseEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.GoalContributionEntry?>()) {
      return (data != null ? _i4.GoalContributionEntry.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i5.GoalEntry?>()) {
      return (data != null ? _i5.GoalEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.User?>()) {
      return (data != null ? _i6.User.fromJson(data) : null) as T;
    }
    if (t == List<_i7.BudgetEntry>) {
      return (data as List).map((e) => deserialize<_i7.BudgetEntry>(e)).toList()
          as T;
    }
    if (t == List<_i8.GoalEntry>) {
      return (data as List).map((e) => deserialize<_i8.GoalEntry>(e)).toList()
          as T;
    }
    if (t == List<_i9.GoalContributionEntry>) {
      return (data as List)
          .map((e) => deserialize<_i9.GoalContributionEntry>(e))
          .toList() as T;
    }
    if (t == List<_i10.ExpenseEntry>) {
      return (data as List)
          .map((e) => deserialize<_i10.ExpenseEntry>(e))
          .toList() as T;
    }
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i2.BudgetEntry) {
      return 'BudgetEntry';
    }
    if (data is _i3.ExpenseEntry) {
      return 'ExpenseEntry';
    }
    if (data is _i4.GoalContributionEntry) {
      return 'GoalContributionEntry';
    }
    if (data is _i5.GoalEntry) {
      return 'GoalEntry';
    }
    if (data is _i6.User) {
      return 'User';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'BudgetEntry') {
      return deserialize<_i2.BudgetEntry>(data['data']);
    }
    if (dataClassName == 'ExpenseEntry') {
      return deserialize<_i3.ExpenseEntry>(data['data']);
    }
    if (dataClassName == 'GoalContributionEntry') {
      return deserialize<_i4.GoalContributionEntry>(data['data']);
    }
    if (dataClassName == 'GoalEntry') {
      return deserialize<_i5.GoalEntry>(data['data']);
    }
    if (dataClassName == 'User') {
      return deserialize<_i6.User>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
