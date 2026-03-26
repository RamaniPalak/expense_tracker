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
import 'package:backend_client/src/protocol/expense_entry.dart' as _i4;
import 'package:backend_client/src/protocol/greeting.dart' as _i5;
import 'protocol.dart' as _i6;

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
}

/// {@category Endpoint}
class EndpointExpenseEntry extends _i1.EndpointRef {
  EndpointExpenseEntry(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'expenseEntry';

  _i2.Future<_i4.ExpenseEntry> addExpenseEntry(_i4.ExpenseEntry expenseEntry) =>
      caller.callServerEndpoint<_i4.ExpenseEntry>(
        'expenseEntry',
        'addExpenseEntry',
        {'expenseEntry': expenseEntry},
      );

  _i2.Future<bool> deleteExpenseEntry(int id) =>
      caller.callServerEndpoint<bool>(
        'expenseEntry',
        'deleteExpenseEntry',
        {'id': id},
      );

  _i2.Future<List<_i4.ExpenseEntry>> getExpenseEntries(String userEmail) =>
      caller.callServerEndpoint<List<_i4.ExpenseEntry>>(
        'expenseEntry',
        'getExpenseEntries',
        {'userEmail': userEmail},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i5.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i5.Greeting>(
        'greeting',
        'hello',
        {'name': name},
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
          _i6.Protocol(),
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
    expenseEntry = EndpointExpenseEntry(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointAuth auth;

  late final EndpointExpenseEntry expenseEntry;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
        'auth': auth,
        'expenseEntry': expenseEntry,
        'greeting': greeting,
      };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
