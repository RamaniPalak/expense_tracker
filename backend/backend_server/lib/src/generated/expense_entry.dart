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

abstract class ExpenseEntry
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = ExpenseEntryTable();

  static const db = ExpenseEntryRepository._();

  @override
  int? id;

  String title;

  double amount;

  DateTime date;

  String category;

  bool isIncome;

  String userEmail;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static ExpenseEntryInclude include() {
    return ExpenseEntryInclude._();
  }

  static ExpenseEntryIncludeList includeList({
    _i1.WhereExpressionBuilder<ExpenseEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ExpenseEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ExpenseEntryTable>? orderByList,
    ExpenseEntryInclude? include,
  }) {
    return ExpenseEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ExpenseEntry.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ExpenseEntry.t),
      include: include,
    );
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

class ExpenseEntryTable extends _i1.Table<int?> {
  ExpenseEntryTable({super.tableRelation}) : super(tableName: 'expense_entry') {
    title = _i1.ColumnString(
      'title',
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
    category = _i1.ColumnString(
      'category',
      this,
    );
    isIncome = _i1.ColumnBool(
      'isIncome',
      this,
    );
    userEmail = _i1.ColumnString(
      'userEmail',
      this,
    );
  }

  late final _i1.ColumnString title;

  late final _i1.ColumnDouble amount;

  late final _i1.ColumnDateTime date;

  late final _i1.ColumnString category;

  late final _i1.ColumnBool isIncome;

  late final _i1.ColumnString userEmail;

  @override
  List<_i1.Column> get columns => [
        id,
        title,
        amount,
        date,
        category,
        isIncome,
        userEmail,
      ];
}

class ExpenseEntryInclude extends _i1.IncludeObject {
  ExpenseEntryInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ExpenseEntry.t;
}

class ExpenseEntryIncludeList extends _i1.IncludeList {
  ExpenseEntryIncludeList._({
    _i1.WhereExpressionBuilder<ExpenseEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ExpenseEntry.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ExpenseEntry.t;
}

class ExpenseEntryRepository {
  const ExpenseEntryRepository._();

  /// Returns a list of [ExpenseEntry]s matching the given query parameters.
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
  Future<List<ExpenseEntry>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ExpenseEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ExpenseEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ExpenseEntryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<ExpenseEntry>(
      where: where?.call(ExpenseEntry.t),
      orderBy: orderBy?.call(ExpenseEntry.t),
      orderByList: orderByList?.call(ExpenseEntry.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [ExpenseEntry] matching the given query parameters.
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
  Future<ExpenseEntry?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ExpenseEntryTable>? where,
    int? offset,
    _i1.OrderByBuilder<ExpenseEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ExpenseEntryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<ExpenseEntry>(
      where: where?.call(ExpenseEntry.t),
      orderBy: orderBy?.call(ExpenseEntry.t),
      orderByList: orderByList?.call(ExpenseEntry.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [ExpenseEntry] by its [id] or null if no such row exists.
  Future<ExpenseEntry?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<ExpenseEntry>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [ExpenseEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [ExpenseEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<ExpenseEntry>> insert(
    _i1.Session session,
    List<ExpenseEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<ExpenseEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [ExpenseEntry] and returns the inserted row.
  ///
  /// The returned [ExpenseEntry] will have its `id` field set.
  Future<ExpenseEntry> insertRow(
    _i1.Session session,
    ExpenseEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ExpenseEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ExpenseEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ExpenseEntry>> update(
    _i1.Session session,
    List<ExpenseEntry> rows, {
    _i1.ColumnSelections<ExpenseEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ExpenseEntry>(
      rows,
      columns: columns?.call(ExpenseEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ExpenseEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ExpenseEntry> updateRow(
    _i1.Session session,
    ExpenseEntry row, {
    _i1.ColumnSelections<ExpenseEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ExpenseEntry>(
      row,
      columns: columns?.call(ExpenseEntry.t),
      transaction: transaction,
    );
  }

  /// Deletes all [ExpenseEntry]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ExpenseEntry>> delete(
    _i1.Session session,
    List<ExpenseEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ExpenseEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ExpenseEntry].
  Future<ExpenseEntry> deleteRow(
    _i1.Session session,
    ExpenseEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ExpenseEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ExpenseEntry>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ExpenseEntryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ExpenseEntry>(
      where: where(ExpenseEntry.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ExpenseEntryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ExpenseEntry>(
      where: where?.call(ExpenseEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
