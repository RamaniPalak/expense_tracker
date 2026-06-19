import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometrics are available on this device.
  /// On iOS, only Face ID is checked.
  static Future<bool> isBiometricAvailable() async {
    try {
      // Check if the device supports biometrics at all
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      final bool isDeviceSupported = await _auth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      // Get available biometrics
      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();

      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Prompt the user with biometric authentication.
  /// Returns true if authentication succeeded.
  static Future<BiometricResult> authenticate() async {
    try {
      String reason = 'Authenticate to access your Expense Tracker';
      try {
        final List<BiometricType> availableBiometrics =
            await _auth.getAvailableBiometrics();
        if (availableBiometrics.contains(BiometricType.face)) {
          reason = 'Use Face ID to access your Expense Tracker';
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          reason = Platform.isIOS
              ? 'Use Touch ID to access your Expense Tracker'
              : 'Use your fingerprint to access your Expense Tracker';
        }
      } catch (_) {
        // Fallback to default reason
      }

      final bool authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,   // Allow fallback so it doesn't fail on weak biometrics
          stickyAuth: true,       // Keep prompt open if app loses focus
          useErrorDialogs: true,
        ),
      );
      return authenticated
          ? BiometricResult.success
          : BiometricResult.failed;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        return BiometricResult.notAvailable;
      } else if (e.code == auth_error.notEnrolled) {
        return BiometricResult.notEnrolled;
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return BiometricResult.lockedOut;
      }
      return BiometricResult.failed;
    }
  }
}

enum BiometricResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
}
