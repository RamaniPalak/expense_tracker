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

abstract class GoalEntry
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = GoalEntryTable();

  static const db = GoalEntryRepository._();

  @override
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

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static GoalEntryInclude include() {
    return GoalEntryInclude._();
  }

  static GoalEntryIncludeList includeList({
    _i1.WhereExpressionBuilder<GoalEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GoalEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GoalEntryTable>? orderByList,
    GoalEntryInclude? include,
  }) {
    return GoalEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GoalEntry.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GoalEntry.t),
      include: include,
    );
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

class GoalEntryTable extends _i1.Table<int?> {
  GoalEntryTable({super.tableRelation}) : super(tableName: 'goal_entry') {
    title = _i1.ColumnString(
      'title',
      this,
    );
    targetAmount = _i1.ColumnDouble(
      'targetAmount',
      this,
    );
    currentAmount = _i1.ColumnDouble(
      'currentAmount',
      this,
    );
    targetDate = _i1.ColumnDateTime(
      'targetDate',
      this,
    );
    iconCode = _i1.ColumnInt(
      'iconCode',
      this,
    );
    colorValue = _i1.ColumnInt(
      'colorValue',
      this,
    );
    category = _i1.ColumnString(
      'category',
      this,
    );
    userEmail = _i1.ColumnString(
      'userEmail',
      this,
    );
    priority = _i1.ColumnString(
      'priority',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    productUrl = _i1.ColumnString(
      'productUrl',
      this,
    );
    autoDepositAmount = _i1.ColumnDouble(
      'autoDepositAmount',
      this,
    );
    autoDepositDay = _i1.ColumnInt(
      'autoDepositDay',
      this,
    );
  }

  late final _i1.ColumnString title;

  late final _i1.ColumnDouble targetAmount;

  late final _i1.ColumnDouble currentAmount;

  late final _i1.ColumnDateTime targetDate;

  late final _i1.ColumnInt iconCode;

  late final _i1.ColumnInt colorValue;

  late final _i1.ColumnString category;

  late final _i1.ColumnString userEmail;

  late final _i1.ColumnString priority;

  late final _i1.ColumnString status;

  late final _i1.ColumnString productUrl;

  late final _i1.ColumnDouble autoDepositAmount;

  late final _i1.ColumnInt autoDepositDay;

  @override
  List<_i1.Column> get columns => [
        id,
        title,
        targetAmount,
        currentAmount,
        targetDate,
        iconCode,
        colorValue,
        category,
        userEmail,
        priority,
        status,
        productUrl,
        autoDepositAmount,
        autoDepositDay,
      ];
}

class GoalEntryInclude extends _i1.IncludeObject {
  GoalEntryInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => GoalEntry.t;
}

class GoalEntryIncludeList extends _i1.IncludeList {
  GoalEntryIncludeList._({
    _i1.WhereExpressionBuilder<GoalEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GoalEntry.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GoalEntry.t;
}

class GoalEntryRepository {
  const GoalEntryRepository._();

  /// Returns a list of [GoalEntry]s matching the given query parameters.
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
  Future<List<GoalEntry>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<GoalEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GoalEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GoalEntryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<GoalEntry>(
      where: where?.call(GoalEntry.t),
      orderBy: orderBy?.call(GoalEntry.t),
      orderByList: orderByList?.call(GoalEntry.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [GoalEntry] matching the given query parameters.
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
  Future<GoalEntry?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<GoalEntryTable>? where,
    int? offset,
    _i1.OrderByBuilder<GoalEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GoalEntryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<GoalEntry>(
      where: where?.call(GoalEntry.t),
      orderBy: orderBy?.call(GoalEntry.t),
      orderByList: orderByList?.call(GoalEntry.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [GoalEntry] by its [id] or null if no such row exists.
  Future<GoalEntry?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<GoalEntry>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [GoalEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [GoalEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<GoalEntry>> insert(
    _i1.Session session,
    List<GoalEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<GoalEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [GoalEntry] and returns the inserted row.
  ///
  /// The returned [GoalEntry] will have its `id` field set.
  Future<GoalEntry> insertRow(
    _i1.Session session,
    GoalEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GoalEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [GoalEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GoalEntry>> update(
    _i1.Session session,
    List<GoalEntry> rows, {
    _i1.ColumnSelections<GoalEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GoalEntry>(
      rows,
      columns: columns?.call(GoalEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GoalEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GoalEntry> updateRow(
    _i1.Session session,
    GoalEntry row, {
    _i1.ColumnSelections<GoalEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GoalEntry>(
      row,
      columns: columns?.call(GoalEntry.t),
      transaction: transaction,
    );
  }

  /// Deletes all [GoalEntry]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GoalEntry>> delete(
    _i1.Session session,
    List<GoalEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GoalEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [GoalEntry].
  Future<GoalEntry> deleteRow(
    _i1.Session session,
    GoalEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GoalEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GoalEntry>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<GoalEntryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GoalEntry>(
      where: where(GoalEntry.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<GoalEntryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GoalEntry>(
      where: where?.call(GoalEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
