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
import '../endpoints/auth_endpoint.dart' as _i2;
import '../endpoints/budget_endpoint.dart' as _i3;
import '../endpoints/goal_endpoint.dart' as _i4;
import '../endpoints/transaction_endpoint.dart' as _i5;
import 'package:backend_server/src/generated/user.dart' as _i6;
import 'package:backend_server/src/generated/budget_entry.dart' as _i7;
import 'package:backend_server/src/generated/goal_entry.dart' as _i8;
import 'package:backend_server/src/generated/goal_contribution_entry.dart'
    as _i9;
import 'package:backend_server/src/generated/expense_entry.dart' as _i10;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'auth': _i2.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'budgetEntry': _i3.BudgetEntryEndpoint()
        ..initialize(
          server,
          'budgetEntry',
          null,
        ),
      'goalEntry': _i4.GoalEntryEndpoint()
        ..initialize(
          server,
          'goalEntry',
          null,
        ),
      'expenseEntry': _i5.ExpenseEntryEndpoint()
        ..initialize(
          server,
          'expenseEntry',
          null,
        ),
    };
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'register': _i1.MethodConnector(
          name: 'register',
          params: {
            'user': _i1.ParameterDescription(
              name: 'user',
              type: _i1.getType<_i6.User>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i2.AuthEndpoint).register(
            session,
            params['user'],
          ),
        ),
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i2.AuthEndpoint).login(
            session,
            params['email'],
            params['password'],
          ),
        ),
        'changePassword': _i1.MethodConnector(
          name: 'changePassword',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'oldPassword': _i1.ParameterDescription(
              name: 'oldPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i2.AuthEndpoint).changePassword(
            session,
            params['email'],
            params['oldPassword'],
            params['newPassword'],
          ),
        ),
        'updateProfile': _i1.MethodConnector(
          name: 'updateProfile',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'imagePath': _i1.ParameterDescription(
              name: 'imagePath',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i2.AuthEndpoint).updateProfile(
            session,
            params['email'],
            params['name'],
            params['imagePath'],
          ),
        ),
      },
    );
    connectors['budgetEntry'] = _i1.EndpointConnector(
      name: 'budgetEntry',
      endpoint: endpoints['budgetEntry']!,
      methodConnectors: {
        'addBudgetEntry': _i1.MethodConnector(
          name: 'addBudgetEntry',
          params: {
            'entry': _i1.ParameterDescription(
              name: 'entry',
              type: _i1.getType<_i7.BudgetEntry>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['budgetEntry'] as _i3.BudgetEntryEndpoint)
                  .addBudgetEntry(
            session,
            params['entry'],
          ),
        ),
        'updateBudgetEntry': _i1.MethodConnector(
          name: 'updateBudgetEntry',
          params: {
            'entry': _i1.ParameterDescription(
              name: 'entry',
              type: _i1.getType<_i7.BudgetEntry>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['budgetEntry'] as _i3.BudgetEntryEndpoint)
                  .updateBudgetEntry(
            session,
            params['entry'],
          ),
        ),
        'deleteBudgetEntry': _i1.MethodConnector(
          name: 'deleteBudgetEntry',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['budgetEntry'] as _i3.BudgetEntryEndpoint)
                  .deleteBudgetEntry(
            session,
            params['id'],
          ),
        ),
        'getBudgetEntries': _i1.MethodConnector(
          name: 'getBudgetEntries',
          params: {
            'userEmail': _i1.ParameterDescription(
              name: 'userEmail',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['budgetEntry'] as _i3.BudgetEntryEndpoint)
                  .getBudgetEntries(
            session,
            params['userEmail'],
          ),
        ),
      },
    );
    connectors['goalEntry'] = _i1.EndpointConnector(
      name: 'goalEntry',
      endpoint: endpoints['goalEntry']!,
      methodConnectors: {
        'addGoalEntry': _i1.MethodConnector(
          name: 'addGoalEntry',
          params: {
            'entry': _i1.ParameterDescription(
              name: 'entry',
              type: _i1.getType<_i8.GoalEntry>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['goalEntry'] as _i4.GoalEntryEndpoint).addGoalEntry(
            session,
            params['entry'],
          ),
        ),
        'updateGoalEntry': _i1.MethodConnector(
          name: 'updateGoalEntry',
          params: {
            'entry': _i1.ParameterDescription(
              name: 'entry',
              type: _i1.getType<_i8.GoalEntry>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['goalEntry'] as _i4.GoalEntryEndpoint).updateGoalEntry(
            session,
            params['entry'],
          ),
        ),
        'deleteGoalEntry': _i1.MethodConnector(
          name: 'deleteGoalEntry',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['goalEntry'] as _i4.GoalEntryEndpoint).deleteGoalEntry(
            session,
            params['id'],
          ),
        ),
        'getGoalEntries': _i1.MethodConnector(
          name: 'getGoalEntries',
          params: {
            'userEmail': _i1.ParameterDescription(
              name: 'userEmail',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['goalEntry'] as _i4.GoalEntryEndpoint).getGoalEntries(
            session,
            params['userEmail'],
          ),
        ),
        'addGoalContribution': _i1.MethodConnector(
          name: 'addGoalContribution',
          params: {
            'entry': _i1.ParameterDescription(
              name: 'entry',
              type: _i1.getType<_i9.GoalContributionEntry>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['goalEntry'] as _i4.GoalEntryEndpoint)
                  .addGoalContribution(
            session,
            params['entry'],
          ),
        ),
        'deleteGoalContribution': _i1.MethodConnector(
          name: 'deleteGoalContribution',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['goalEntry'] as _i4.GoalEntryEndpoint)
                  .deleteGoalContribution(
            session,
            params['id'],
          ),
        ),
        'getGoalContributions': _i1.MethodConnector(
          name: 'getGoalContributions',
          params: {
            'userEmail': _i1.ParameterDescription(
              name: 'userEmail',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['goalEntry'] as _i4.GoalEntryEndpoint)
                  .getGoalContributions(
            session,
            params['userEmail'],
          ),
        ),
      },
    );
    connectors['expenseEntry'] = _i1.EndpointConnector(
      name: 'expenseEntry',
      endpoint: endpoints['expenseEntry']!,
      methodConnectors: {
        'addExpenseEntry': _i1.MethodConnector(
          name: 'addExpenseEntry',
          params: {
            'expenseEntry': _i1.ParameterDescription(
              name: 'expenseEntry',
              type: _i1.getType<_i10.ExpenseEntry>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['expenseEntry'] as _i5.ExpenseEntryEndpoint)
                  .addExpenseEntry(
            session,
            params['expenseEntry'],
          ),
        ),
        'updateExpenseEntry': _i1.MethodConnector(
          name: 'updateExpenseEntry',
          params: {
            'entry': _i1.ParameterDescription(
              name: 'entry',
              type: _i1.getType<_i10.ExpenseEntry>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['expenseEntry'] as _i5.ExpenseEntryEndpoint)
                  .updateExpenseEntry(
            session,
            params['entry'],
          ),
        ),
        'deleteExpenseEntry': _i1.MethodConnector(
          name: 'deleteExpenseEntry',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['expenseEntry'] as _i5.ExpenseEntryEndpoint)
                  .deleteExpenseEntry(
            session,
            params['id'],
          ),
        ),
        'getExpenseEntries': _i1.MethodConnector(
          name: 'getExpenseEntries',
          params: {
            'userEmail': _i1.ParameterDescription(
              name: 'userEmail',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['expenseEntry'] as _i5.ExpenseEntryEndpoint)
                  .getExpenseEntries(
            session,
            params['userEmail'],
          ),
        ),
      },
    );
  }
}
