import 'package:flutter/material.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/services/biometric_service.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Repository is now handled via DI


  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1));
    final authRepo = sl<IAuthRepository>();
    final isLoggedIn = await authRepo.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      final isBiometricEnabled = await sl<IAuthRepository>().isBiometricEnabled();
      if (isBiometricEnabled) {
        await _handleBiometricAuth();
      } else {
        context.go(RoutePaths.home);
      }
    } else {
      context.go(RoutePaths.onboarding);
    }
  }

  Future<void> _handleBiometricAuth() async {
    final bool biometricAvailable = await BiometricService.isBiometricAvailable();

    if (!mounted) return;

    if (!biometricAvailable) {
      _goToHome();
      return;
    }

    final result = await BiometricService.authenticate();

    if (!mounted) return;

    switch (result) {
      case BiometricResult.success:
        _goToHome();
        break;
      case BiometricResult.notEnrolled:
        _goToHome();
        break;
      case BiometricResult.lockedOut:
        _showBiometricError(
          'Too many failed attempts. Please log in with your password.',
        );
        break;
      case BiometricResult.notAvailable:
      case BiometricResult.failed:
        _goToLogin();
        break;
    }
  }

  void _goToHome() {
    context.go(RoutePaths.home);
  }

  void _goToLogin() {
    context.go(RoutePaths.login);
  }

  void _showBiometricError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Authentication Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
              _goToLogin();
            },
            child: const Text('Login with Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Icon(
          Icons.account_balance_wallet,
          size: 100,
          color: Colors.white,
        ),
      ),
    );
  }
}
