import 'package:shared_preferences/shared_preferences.dart';

abstract class IAuthLocalDataSource {
  Future<bool> hasSeenOnboarding();
  Future<void> setSeenOnboarding();
  Future<void> cacheSession(String email, String name);
  Future<void> clearSession();
  Future<bool> isLoggedIn();
  Future<String?> getCachedEmail();
  Future<String?> getCachedName();
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool value);
  Future<void> updateProfile(String name, String? imagePath);
  Future<String?> getCachedImagePath();
}

class AuthLocalDataSourceImpl implements IAuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';
  static const String _userNameKey = 'userName';
  static const String _userImageKey = 'userImage';
  static const String _isBiometricEnabledKey = 'isBiometricEnabled';
  static const String _hasSeenOnboardingKey = 'hasSeenOnboarding';

  @override
  Future<bool> hasSeenOnboarding() async {
    return sharedPreferences.getBool(_hasSeenOnboardingKey) ?? false;
  }

  @override
  Future<void> setSeenOnboarding() async {
    await sharedPreferences.setBool(_hasSeenOnboardingKey, true);
  }

  @override
  Future<void> cacheSession(String email, String name) async {
    await sharedPreferences.setBool(_isLoggedInKey, true);
    await sharedPreferences.setString(_userEmailKey, email);
    await sharedPreferences.setString(_userNameKey, name);
  }

  @override
  Future<void> clearSession() async {
    await sharedPreferences.remove(_isLoggedInKey);
    await sharedPreferences.remove(_userEmailKey);
    await sharedPreferences.remove(_userNameKey);
    await sharedPreferences.remove(_userImageKey);
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

  @override
  Future<void> updateProfile(String name, String? imagePath) async {
    await sharedPreferences.setString(_userNameKey, name);
    if (imagePath != null) {
      await sharedPreferences.setString(_userImageKey, imagePath);
    } else {
      await sharedPreferences.remove(_userImageKey);
    }
  }

  @override
  Future<String?> getCachedImagePath() async {
    return sharedPreferences.getString(_userImageKey);
  }
}
