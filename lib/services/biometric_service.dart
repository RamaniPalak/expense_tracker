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

      if (Platform.isIOS) {
        // iOS: Only allow Face ID
        return availableBiometrics.contains(BiometricType.face);
      } else {
        // Android: Allow any biometric (fingerprint, face, etc.)
        return availableBiometrics.isNotEmpty;
      }
    } on PlatformException {
      return false;
    }
  }

  /// Prompt the user with biometric authentication.
  /// Returns true if authentication succeeded.
  static Future<BiometricResult> authenticate() async {
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: Platform.isIOS
            ? 'Use Face ID to access your Expense Tracker'
            : 'Use your fingerprint to access your Expense Tracker',
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
