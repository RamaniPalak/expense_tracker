import 'dart:developer';

import 'package:backend_client/backend_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';
  static const String _userNameKey = 'userName';
  static const String _isBiometricEnabledKey = 'isBiometricEnabled';

  Future<bool> login(String email, String password) async {
    try {
      final user = await apiClient.client.auth.login(email, password);
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_userEmailKey, user.email);
        await prefs.setString(_userNameKey, user.name);
        return true;
      }
      return false;
    } catch (e) {
      log('Login error: $e');
      rethrow;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final user = User(
        name: name,
        email: email,
        password: password,
      );
      final success = await apiClient.client.auth.register(user);
      return success;
    } catch (e) {
      log('Registration error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_isBiometricEnabledKey);
  }

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isBiometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isBiometricEnabledKey, value);
  }
}
