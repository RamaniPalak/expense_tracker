import 'package:dartz/dartz.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource remoteDataSource;
  final IAuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<String, void>> login(String email, String password) async {
    try {
      final user = await remoteDataSource.login(email, password);
      if (user != null) {
        await localDataSource.cacheSession(user.email, user.name);
        return const Right(null);
      }
      return const Left("Login failed: Invalid credentials");
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> register(String name, String email, String password) async {
    try {
      final success = await remoteDataSource.register(name, email, password);
      if (success) {
        return const Right(null);
      }
      return const Left("Registration failed");
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> logout() async {
    try {
      await localDataSource.clearSession();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await localDataSource.isLoggedIn();
  }

  @override
  Future<String?> getUserEmail() async {
    return await localDataSource.getCachedEmail();
  }

  @override
  Future<String?> getUserName() async {
    return await localDataSource.getCachedName();
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return await localDataSource.isBiometricEnabled();
  }

  @override
  Future<void> setBiometricEnabled(bool value) async {
    await localDataSource.setBiometricEnabled(value);
  }
}
