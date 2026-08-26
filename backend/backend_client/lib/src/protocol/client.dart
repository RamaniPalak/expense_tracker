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
import 'dart:async' as _i2;
import 'package:backend_client/src/protocol/user.dart' as _i3;
import 'package:backend_client/src/protocol/budget_entry.dart' as _i4;
import 'package:backend_client/src/protocol/goal_entry.dart' as _i5;
import 'package:backend_client/src/protocol/goal_contribution_entry.dart'
    as _i6;
import 'package:backend_client/src/protocol/expense_entry.dart' as _i7;
import 'protocol.dart' as _i8;

/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  _i2.Future<bool> register(_i3.User user) => caller.callServerEndpoint<bool>(
        'auth',
        'register',
        {'user': user},
      );

  _i2.Future<_i3.User?> login(
    String email,
    String password,
  ) =>
      caller.callServerEndpoint<_i3.User?>(
        'auth',
        'login',
        {
          'email': email,
          'password': password,
        },
      );

  _i2.Future<bool> changePassword(
    String email,
    String oldPassword,
    String newPassword,
  ) =>
      caller.callServerEndpoint<bool>(
        'auth',
        'changePassword',
        {
          'email': email,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

  _i2.Future<_i3.User?> updateProfile(
    String email,
    String name,
    String? imagePath,
  ) =>
      caller.callServerEndpoint<_i3.User?>(
        'auth',
        'updateProfile',
        {
          'email': email,
          'name': name,
          'imagePath': imagePath,
        },
      );
}

/// {@category Endpoint}
class EndpointBudgetEntry extends _i1.EndpointRef {
  EndpointBudgetEntry(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'budgetEntry';

  _i2.Future<_i4.BudgetEntry> addBudgetEntry(_i4.BudgetEntry entry) =>
      caller.callServerEndpoint<_i4.BudgetEntry>(
        'budgetEntry',
        'addBudgetEntry',
        {'entry': entry},
      );

  _i2.Future<_i4.BudgetEntry> updateBudgetEntry(_i4.BudgetEntry entry) =>
      caller.callServerEndpoint<_i4.BudgetEntry>(
        'budgetEntry',
        'updateBudgetEntry',
        {'entry': entry},
      );

  _i2.Future<bool> deleteBudgetEntry(int id) => caller.callServerEndpoint<bool>(
        'budgetEntry',
        'deleteBudgetEntry',
        {'id': id},
      );

  _i2.Future<List<_i4.BudgetEntry>> getBudgetEntries(String userEmail) =>
      caller.callServerEndpoint<List<_i4.BudgetEntry>>(
        'budgetEntry',
        'getBudgetEntries',
        {'userEmail': userEmail},
      );

  _i2.Future<Map<String, dynamic>?> addMonthlyBudgetEntry(
    String userEmail,
    double amount,
    int month,
    int year,
  ) =>
      caller.callServerEndpoint<Map<String, dynamic>?>(
        'budgetEntry',
        'addMonthlyBudgetEntry',
        {
          'userEmail': userEmail,
          'amount': amount,
          'month': month,
          'year': year,
        },
      );

  _i2.Future<List<dynamic>> getMonthlyBudgetEntries(
    String userEmail,
  ) =>
      caller.callServerEndpoint<List<dynamic>>(
        'budgetEntry',
        'getMonthlyBudgetEntries',
        {
          'userEmail': userEmail,
        },
      );
}

/// {@category Endpoint}
class EndpointGoalEntry extends _i1.EndpointRef {
  EndpointGoalEntry(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'goalEntry';

  _i2.Future<_i5.GoalEntry> addGoalEntry(_i5.GoalEntry entry) =>
      caller.callServerEndpoint<_i5.GoalEntry>(
        'goalEntry',
        'addGoalEntry',
        {'entry': entry},
      );

  _i2.Future<_i5.GoalEntry> updateGoalEntry(_i5.GoalEntry entry) =>
      caller.callServerEndpoint<_i5.GoalEntry>(
        'goalEntry',
        'updateGoalEntry',
        {'entry': entry},
      );

  _i2.Future<bool> deleteGoalEntry(int id) => caller.callServerEndpoint<bool>(
        'goalEntry',
        'deleteGoalEntry',
        {'id': id},
      );

  _i2.Future<List<_i5.GoalEntry>> getGoalEntries(String userEmail) =>
      caller.callServerEndpoint<List<_i5.GoalEntry>>(
        'goalEntry',
        'getGoalEntries',
        {'userEmail': userEmail},
      );

  _i2.Future<_i6.GoalContributionEntry> addGoalContribution(
          _i6.GoalContributionEntry entry) =>
      caller.callServerEndpoint<_i6.GoalContributionEntry>(
        'goalEntry',
        'addGoalContribution',
        {'entry': entry},
      );

  _i2.Future<bool> deleteGoalContribution(int id) =>
      caller.callServerEndpoint<bool>(
        'goalEntry',
        'deleteGoalContribution',
        {'id': id},
      );

  _i2.Future<List<_i6.GoalContributionEntry>> getGoalContributions(
          String userEmail) =>
      caller.callServerEndpoint<List<_i6.GoalContributionEntry>>(
        'goalEntry',
        'getGoalContributions',
        {'userEmail': userEmail},
      );
}

/// {@category Endpoint}
class EndpointExpenseEntry extends _i1.EndpointRef {
  EndpointExpenseEntry(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'expenseEntry';

  _i2.Future<_i7.ExpenseEntry> addExpenseEntry(_i7.ExpenseEntry expenseEntry) =>
      caller.callServerEndpoint<_i7.ExpenseEntry>(
        'expenseEntry',
        'addExpenseEntry',
        {'expenseEntry': expenseEntry},
      );

  _i2.Future<_i7.ExpenseEntry> updateExpenseEntry(_i7.ExpenseEntry entry) =>
      caller.callServerEndpoint<_i7.ExpenseEntry>(
        'expenseEntry',
        'updateExpenseEntry',
        {'entry': entry},
      );

  _i2.Future<bool> deleteExpenseEntry(int id) =>
      caller.callServerEndpoint<bool>(
        'expenseEntry',
        'deleteExpenseEntry',
        {'id': id},
      );

  _i2.Future<List<_i7.ExpenseEntry>> getExpenseEntries(String userEmail) =>
      caller.callServerEndpoint<List<_i7.ExpenseEntry>>(
        'expenseEntry',
        'getExpenseEntries',
        {'userEmail': userEmail},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    _i1.AuthenticationKeyManager? authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )? onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
          host,
          _i8.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    auth = EndpointAuth(this);
    budgetEntry = EndpointBudgetEntry(this);
    goalEntry = EndpointGoalEntry(this);
    expenseEntry = EndpointExpenseEntry(this);
  }

  late final EndpointAuth auth;

  late final EndpointBudgetEntry budgetEntry;

  late final EndpointGoalEntry goalEntry;

  late final EndpointExpenseEntry expenseEntry;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
        'auth': auth,
        'budgetEntry': budgetEntry,
        'goalEntry': goalEntry,
        'expenseEntry': expenseEntry,
      };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
