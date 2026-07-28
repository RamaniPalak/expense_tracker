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

abstract class BudgetEntry
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = BudgetEntryTable();

  static const db = BudgetEntryRepository._();

  @override
  int? id;

  String category;

  double amount;

  int month;

  int year;

  String userEmail;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
      'userEmail': userEmail,
    };
  }

  static BudgetEntryInclude include() {
    return BudgetEntryInclude._();
  }

  static BudgetEntryIncludeList includeList({
    _i1.WhereExpressionBuilder<BudgetEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BudgetEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BudgetEntryTable>? orderByList,
    BudgetEntryInclude? include,
  }) {
    return BudgetEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BudgetEntry.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(BudgetEntry.t),
      include: include,
    );
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

class BudgetEntryTable extends _i1.Table<int?> {
  BudgetEntryTable({super.tableRelation}) : super(tableName: 'budget_entry') {
    category = _i1.ColumnString(
      'category',
      this,
    );
    amount = _i1.ColumnDouble(
      'amount',
      this,
    );
    month = _i1.ColumnInt(
      'month',
      this,
    );
    year = _i1.ColumnInt(
      'year',
      this,
    );
    userEmail = _i1.ColumnString(
      'userEmail',
      this,
    );
  }

  late final _i1.ColumnString category;

  late final _i1.ColumnDouble amount;

  late final _i1.ColumnInt month;

  late final _i1.ColumnInt year;

  late final _i1.ColumnString userEmail;

  @override
  List<_i1.Column> get columns => [
        id,
        category,
        amount,
        month,
        year,
        userEmail,
      ];
}

class BudgetEntryInclude extends _i1.IncludeObject {
  BudgetEntryInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => BudgetEntry.t;
}

class BudgetEntryIncludeList extends _i1.IncludeList {
  BudgetEntryIncludeList._({
    _i1.WhereExpressionBuilder<BudgetEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BudgetEntry.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => BudgetEntry.t;
}

class BudgetEntryRepository {
  const BudgetEntryRepository._();

  /// Returns a list of [BudgetEntry]s matching the given query parameters.
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
  Future<List<BudgetEntry>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<BudgetEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BudgetEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BudgetEntryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<BudgetEntry>(
      where: where?.call(BudgetEntry.t),
      orderBy: orderBy?.call(BudgetEntry.t),
      orderByList: orderByList?.call(BudgetEntry.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [BudgetEntry] matching the given query parameters.
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
  Future<BudgetEntry?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<BudgetEntryTable>? where,
    int? offset,
    _i1.OrderByBuilder<BudgetEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BudgetEntryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<BudgetEntry>(
      where: where?.call(BudgetEntry.t),
      orderBy: orderBy?.call(BudgetEntry.t),
      orderByList: orderByList?.call(BudgetEntry.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [BudgetEntry] by its [id] or null if no such row exists.
  Future<BudgetEntry?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<BudgetEntry>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [BudgetEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [BudgetEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<BudgetEntry>> insert(
    _i1.Session session,
    List<BudgetEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<BudgetEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [BudgetEntry] and returns the inserted row.
  ///
  /// The returned [BudgetEntry] will have its `id` field set.
  Future<BudgetEntry> insertRow(
    _i1.Session session,
    BudgetEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<BudgetEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [BudgetEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<BudgetEntry>> update(
    _i1.Session session,
    List<BudgetEntry> rows, {
    _i1.ColumnSelections<BudgetEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<BudgetEntry>(
      rows,
      columns: columns?.call(BudgetEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BudgetEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BudgetEntry> updateRow(
    _i1.Session session,
    BudgetEntry row, {
    _i1.ColumnSelections<BudgetEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<BudgetEntry>(
      row,
      columns: columns?.call(BudgetEntry.t),
      transaction: transaction,
    );
  }

  /// Deletes all [BudgetEntry]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<BudgetEntry>> delete(
    _i1.Session session,
    List<BudgetEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<BudgetEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [BudgetEntry].
  Future<BudgetEntry> deleteRow(
    _i1.Session session,
    BudgetEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BudgetEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<BudgetEntry>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<BudgetEntryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<BudgetEntry>(
      where: where(BudgetEntry.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<BudgetEntryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<BudgetEntry>(
      where: where?.call(BudgetEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
