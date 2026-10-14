import 'package:dartz/dartz.dart';

abstract class IAuthRepository {
  Future<bool> hasSeenOnboarding();
  Future<void> setSeenOnboarding();
  Future<Either<String, void>> login(String email, String password);
  Future<Either<String, void>> register(
      String name, String email, String password);
  Future<Either<String, void>> changePassword(
      String email, String oldPassword, String newPassword);
  Future<Either<String, void>> logout();
  Future<bool> isLoggedIn();
  Future<String?> getUserEmail();
  Future<String?> getUserName();
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool value);
  Future<void> updateProfile(String name, String? imagePath);
  Future<String?> getUserImagePath();

  /// Requests a password-reset OTP for [email].
  /// Returns Right(otp) on success or Left(errorMessage) on failure.
  Future<Either<String, String>> requestPasswordReset(String email);

  /// Verifies [otp] for [email] and updates the password to [newPassword].
  /// Returns Right(null) on success or Left(errorMessage) on failure.
  Future<Either<String, void>> verifyOtpAndResetPassword(
      String email, String otp, String newPassword);
}

