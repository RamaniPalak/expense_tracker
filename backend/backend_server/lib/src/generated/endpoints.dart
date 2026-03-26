/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/auth_endpoint.dart' as _i2;
import '../endpoints/transaction_endpoint.dart' as _i3;
import 'package:backend_server/src/generated/user.dart' as _i5;
import 'package:backend_server/src/generated/expense_entry.dart' as _i6;

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
      'expenseEntry': _i3.ExpenseEntryEndpoint()
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
              type: _i1.getType<_i5.User>(),
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
              type: _i1.getType<_i6.ExpenseEntry>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['expenseEntry'] as _i3.ExpenseEntryEndpoint)
                  .addExpenseEntry(
            session,
            params['expenseEntry'],
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
              (endpoints['expenseEntry'] as _i3.ExpenseEntryEndpoint)
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
              (endpoints['expenseEntry'] as _i3.ExpenseEntryEndpoint)
                  .getExpenseEntries(
            session,
            params['userEmail'],
          ),
        ),
      },
    );
  }
}
