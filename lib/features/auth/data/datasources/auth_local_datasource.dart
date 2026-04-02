import 'package:shared_preferences/shared_preferences.dart';

abstract class IAuthLocalDataSource {
  Future<void> cacheSession(String email, String name);
  Future<void> clearSession();
  Future<bool> isLoggedIn();
  Future<String?> getCachedEmail();
  Future<String?> getCachedName();
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool value);
}

class AuthLocalDataSourceImpl implements IAuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';
  static const String _userNameKey = 'userName';
  static const String _isBiometricEnabledKey = 'isBiometricEnabled';

  @override
  Future<void> cacheSession(String email, String name) async {
    await sharedPreferences.setBool(_isLoggedInKey, true);
    await sharedPreferences.setString(_userEmailKey, email);
    await sharedPreferences.setString(_userNameKey, name);
  }

  @override
  Future<void> clearSession() async {
    await sharedPreferences.setBool(_isLoggedInKey, false);
    await sharedPreferences.remove(_userEmailKey);
    await sharedPreferences.remove(_userNameKey);
    await sharedPreferences.remove(_isBiometricEnabledKey);
  }

  @override
  Future<bool> isLoggedIn() async {
    return sharedPreferences.getBool(_isLoggedInKey) ?? false;
  }

  @override
  Future<String?> getCachedEmail() async {
    return sharedPreferences.getString(_userEmailKey);
  }

  @override
  Future<String?> getCachedName() async {
    return sharedPreferences.getString(_userNameKey);
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return sharedPreferences.getBool(_isBiometricEnabledKey) ?? false;
  }

  @override
  Future<void> setBiometricEnabled(bool value) async {
    await sharedPreferences.setBool(_isBiometricEnabledKey, value);
  }
}
