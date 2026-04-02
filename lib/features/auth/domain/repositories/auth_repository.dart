import 'package:dartz/dartz.dart';

abstract class IAuthRepository {
  Future<Either<String, void>> login(String email, String password);
  Future<Either<String, void>> register(String name, String email, String password);
  Future<Either<String, void>> logout();
  Future<bool> isLoggedIn();
  Future<String?> getUserEmail();
  Future<String?> getUserName();
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool value);
}
