import 'package:backend_client/backend_client.dart';
import 'package:expense_tracker/services/api_client.dart';

abstract class IAuthRemoteDataSource {
  Future<User?> login(String email, String password);
  Future<bool> register(String name, String email, String password);
  Future<bool> changePassword(String email, String oldPassword, String newPassword);
  Future<User?> updateProfile(String email, String name, String? imagePath);
}

class AuthRemoteDataSourceImpl implements IAuthRemoteDataSource {
  @override
  Future<User?> login(String email, String password) async {
    try {
      return await apiClient.client.auth.login(email, password);
    } catch (e, st) {
      print('=== REMOTE DATASOURCE LOGIN EXCEPTION ===');
      print('Exception: $e');
      print('Type: ${e.runtimeType}');
      print('Stack: $st');
      print('========================================');
      rethrow;
    }
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

  @override
  Future<bool> changePassword(String email, String oldPassword, String newPassword) async {
    return await apiClient.client.auth.changePassword(email, oldPassword, newPassword);
  }

  @override
  Future<User?> updateProfile(String email, String name, String? imagePath) async {
    return await apiClient.client.auth.updateProfile(email, name, imagePath);
  }
}
