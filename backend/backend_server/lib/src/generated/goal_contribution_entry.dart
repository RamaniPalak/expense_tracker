/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class GoalContributionEntry
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = GoalContributionEntryTable();

  static const db = GoalContributionEntryRepository._();

  @override
  int? id;

  int goalId;

  double amount;

  DateTime date;

  String? note;

  String type;

  String userEmail;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static GoalContributionEntryInclude include() {
    return GoalContributionEntryInclude._();
  }

  static GoalContributionEntryIncludeList includeList({
    _i1.WhereExpressionBuilder<GoalContributionEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GoalContributionEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GoalContributionEntryTable>? orderByList,
    GoalContributionEntryInclude? include,
  }) {
    return GoalContributionEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GoalContributionEntry.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GoalContributionEntry.t),
      include: include,
    );
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

class GoalContributionEntryTable extends _i1.Table<int?> {
  GoalContributionEntryTable({super.tableRelation})
      : super(tableName: 'goal_contribution_entry') {
    goalId = _i1.ColumnInt(
      'goalId',
      this,
    );
    amount = _i1.ColumnDouble(
      'amount',
      this,
    );
    date = _i1.ColumnDateTime(
      'date',
      this,
    );
    note = _i1.ColumnString(
      'note',
      this,
    );
    type = _i1.ColumnString(
      'type',
      this,
    );
    userEmail = _i1.ColumnString(
      'userEmail',
      this,
    );
  }

  late final _i1.ColumnInt goalId;

  late final _i1.ColumnDouble amount;

  late final _i1.ColumnDateTime date;

  late final _i1.ColumnString note;

  late final _i1.ColumnString type;

  late final _i1.ColumnString userEmail;

  @override
  List<_i1.Column> get columns => [
        id,
        goalId,
        amount,
        date,
        note,
        type,
        userEmail,
      ];
}

class GoalContributionEntryInclude extends _i1.IncludeObject {
  GoalContributionEntryInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => GoalContributionEntry.t;
}

class GoalContributionEntryIncludeList extends _i1.IncludeList {
  GoalContributionEntryIncludeList._({
    _i1.WhereExpressionBuilder<GoalContributionEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GoalContributionEntry.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GoalContributionEntry.t;
}

class GoalContributionEntryRepository {
  const GoalContributionEntryRepository._();

  /// Returns a list of [GoalContributionEntry]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<GoalContributionEntry>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<GoalContributionEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GoalContributionEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GoalContributionEntryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<GoalContributionEntry>(
      where: where?.call(GoalContributionEntry.t),
      orderBy: orderBy?.call(GoalContributionEntry.t),
      orderByList: orderByList?.call(GoalContributionEntry.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [GoalContributionEntry] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<GoalContributionEntry?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<GoalContributionEntryTable>? where,
    int? offset,
    _i1.OrderByBuilder<GoalContributionEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GoalContributionEntryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<GoalContributionEntry>(
      where: where?.call(GoalContributionEntry.t),
      orderBy: orderBy?.call(GoalContributionEntry.t),
      orderByList: orderByList?.call(GoalContributionEntry.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [GoalContributionEntry] by its [id] or null if no such row exists.
  Future<GoalContributionEntry?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<GoalContributionEntry>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [GoalContributionEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [GoalContributionEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<GoalContributionEntry>> insert(
    _i1.Session session,
    List<GoalContributionEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<GoalContributionEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [GoalContributionEntry] and returns the inserted row.
  ///
  /// The returned [GoalContributionEntry] will have its `id` field set.
  Future<GoalContributionEntry> insertRow(
    _i1.Session session,
    GoalContributionEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GoalContributionEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [GoalContributionEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GoalContributionEntry>> update(
    _i1.Session session,
    List<GoalContributionEntry> rows, {
    _i1.ColumnSelections<GoalContributionEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GoalContributionEntry>(
      rows,
      columns: columns?.call(GoalContributionEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GoalContributionEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GoalContributionEntry> updateRow(
    _i1.Session session,
    GoalContributionEntry row, {
    _i1.ColumnSelections<GoalContributionEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GoalContributionEntry>(
      row,
      columns: columns?.call(GoalContributionEntry.t),
      transaction: transaction,
    );
  }

  /// Deletes all [GoalContributionEntry]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GoalContributionEntry>> delete(
    _i1.Session session,
    List<GoalContributionEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GoalContributionEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [GoalContributionEntry].
  Future<GoalContributionEntry> deleteRow(
    _i1.Session session,
    GoalContributionEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GoalContributionEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GoalContributionEntry>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<GoalContributionEntryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GoalContributionEntry>(
      where: where(GoalContributionEntry.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<GoalContributionEntryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GoalContributionEntry>(
      where: where?.call(GoalContributionEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
