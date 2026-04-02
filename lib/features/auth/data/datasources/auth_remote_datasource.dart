import 'package:backend_client/backend_client.dart';
import 'package:expense_tracker/services/api_client.dart';

abstract class IAuthRemoteDataSource {
  Future<User?> login(String email, String password);
  Future<bool> register(String name, String email, String password);
}

class AuthRemoteDataSourceImpl implements IAuthRemoteDataSource {
  @override
  Future<User?> login(String email, String password) async {
    return await apiClient.client.auth.login(email, password);
  }

  @override
  Future<bool> register(String name, String email, String password) async {
    final user = User(
      name: name,
      email: email,
      password: password,
    );
    return await apiClient.client.auth.register(user);
  }
}
