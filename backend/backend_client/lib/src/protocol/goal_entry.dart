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

abstract class GoalEntry implements _i1.SerializableModel {
  GoalEntry._({
    this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.iconCode,
    required this.colorValue,
    required this.category,
    required this.userEmail,
    required this.priority,
    required this.status,
    this.productUrl,
    required this.autoDepositAmount,
    required this.autoDepositDay,
  });

  factory GoalEntry({
    int? id,
    required String title,
    required double targetAmount,
    required double currentAmount,
    required DateTime targetDate,
    required int iconCode,
    required int colorValue,
    required String category,
    required String userEmail,
    required String priority,
    required String status,
    String? productUrl,
    required double autoDepositAmount,
    required int autoDepositDay,
  }) = _GoalEntryImpl;

  factory GoalEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return GoalEntry(
      id: jsonSerialization['id'] as int?,
      title: jsonSerialization['title'] as String,
      targetAmount: (jsonSerialization['targetAmount'] as num).toDouble(),
      currentAmount: (jsonSerialization['currentAmount'] as num).toDouble(),
      targetDate:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['targetDate']),
      iconCode: jsonSerialization['iconCode'] as int,
      colorValue: jsonSerialization['colorValue'] as int,
      category: jsonSerialization['category'] as String,
      userEmail: jsonSerialization['userEmail'] as String,
      priority: jsonSerialization['priority'] as String,
      status: jsonSerialization['status'] as String,
      productUrl: jsonSerialization['productUrl'] as String?,
      autoDepositAmount:
          (jsonSerialization['autoDepositAmount'] as num).toDouble(),
      autoDepositDay: jsonSerialization['autoDepositDay'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String title;

  double targetAmount;

  double currentAmount;

  DateTime targetDate;

  int iconCode;

  int colorValue;

  String category;

  String userEmail;

  String priority;

  String status;

  String? productUrl;

  double autoDepositAmount;

  int autoDepositDay;

  /// Returns a shallow copy of this [GoalEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GoalEntry copyWith({
    int? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    int? iconCode,
    int? colorValue,
    String? category,
    String? userEmail,
    String? priority,
    String? status,
    String? productUrl,
    double? autoDepositAmount,
    int? autoDepositDay,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toJson(),
      'iconCode': iconCode,
      'colorValue': colorValue,
      'category': category,
      'userEmail': userEmail,
      'priority': priority,
      'status': status,
      if (productUrl != null) 'productUrl': productUrl,
      'autoDepositAmount': autoDepositAmount,
      'autoDepositDay': autoDepositDay,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GoalEntryImpl extends GoalEntry {
  _GoalEntryImpl({
    int? id,
    required String title,
    required double targetAmount,
    required double currentAmount,
    required DateTime targetDate,
    required int iconCode,
    required int colorValue,
    required String category,
    required String userEmail,
    required String priority,
    required String status,
    String? productUrl,
    required double autoDepositAmount,
    required int autoDepositDay,
  }) : super._(
          id: id,
          title: title,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          targetDate: targetDate,
          iconCode: iconCode,
          colorValue: colorValue,
          category: category,
          userEmail: userEmail,
          priority: priority,
          status: status,
          productUrl: productUrl,
          autoDepositAmount: autoDepositAmount,
          autoDepositDay: autoDepositDay,
        );

  /// Returns a shallow copy of this [GoalEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GoalEntry copyWith({
    Object? id = _Undefined,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    int? iconCode,
    int? colorValue,
    String? category,
    String? userEmail,
    String? priority,
    String? status,
    Object? productUrl = _Undefined,
    double? autoDepositAmount,
    int? autoDepositDay,
  }) {
    return GoalEntry(
      id: id is int? ? id : this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      category: category ?? this.category,
      userEmail: userEmail ?? this.userEmail,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      productUrl: productUrl is String? ? productUrl : this.productUrl,
      autoDepositAmount: autoDepositAmount ?? this.autoDepositAmount,
      autoDepositDay: autoDepositDay ?? this.autoDepositDay,
    );
  }
}
