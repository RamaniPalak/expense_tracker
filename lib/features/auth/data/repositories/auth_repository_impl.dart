import 'dart:async';
import 'dart:io';
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

  // Converts low-level network exceptions into user-friendly messages.
  String _friendlyError(Object e) {
    if (e is TimeoutException ||
        e.toString().toLowerCase().contains('timeout') ||
        e.toString().toLowerCase().contains('timed out')) {
      return 'Server is waking up, please try again in a moment.';
    }
    if (e is SocketException ||
        e.toString().toLowerCase().contains('socketexception') ||
        e.toString().toLowerCase().contains('connection refused')) {
      return 'Cannot reach server. Check your internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Future<Either<String, void>> login(String email, String password) async {
    try {
      final user = await remoteDataSource.login(email, password);
      if (user != null) {
        await localDataSource.cacheSession(user.email, user.name);
        await localDataSource.updateProfile(user.name, user.imagePath);
        return const Right(null);
      }
      return const Left("Login failed: Invalid credentials");
    } catch (e) {
      return Left(_friendlyError(e));
    }
  }

  @override
  Future<Either<String, void>> register(String name, String email, String password) async {
    try {
      final success = await remoteDataSource.register(name, email, password);
      if (success) {
        await localDataSource.cacheSession(email, name);
        return const Right(null);
      }
      return const Left("Email already registered");
    } catch (e) {
      return Left(_friendlyError(e));
    }
  }

  @override
  Future<Either<String, void>> changePassword(String email, String oldPassword, String newPassword) async {
    try {
      final success = await remoteDataSource.changePassword(email, oldPassword, newPassword);
      if (success) {
        return const Right(null);
      }
      return const Left("Incorrect current password or update failed");
    } catch (e) {
      return Left(_friendlyError(e));
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

  @override
  Future<void> updateProfile(String name, String? imagePath) async {
    final email = await localDataSource.getCachedEmail();
    if (email == null) throw Exception("User not logged in");
    
    final updatedUser = await remoteDataSource.updateProfile(email, name, imagePath);
    if (updatedUser == null) {
      throw Exception("Failed to sync profile to server.");
    }
    await localDataSource.updateProfile(name, imagePath);
  }

  @override
  Future<String?> getUserImagePath() async {
    return await localDataSource.getCachedImagePath();
  }
}
