import 'package:flutter/material.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/services/biometric_service.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

class AppLockOverlay extends StatefulWidget {
  final Widget child;

  const AppLockOverlay({super.key, required this.child});

  @override
  State<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends State<AppLockOverlay> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lockApp();
    } else if (state == AppLifecycleState.resumed) {
      _unlockApp();
    }
  }

  Future<void> _lockApp() async {
    final enabled = await sl<IAuthRepository>().isBiometricEnabled();
    if (enabled && !_isLocked) {
      setState(() {
        _isLocked = true;
      });
    }
  }

  Future<void> _unlockApp() async {
    if (!_isLocked || _isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
    });

    final result = await BiometricService.authenticate();
    
    if (mounted) {
      setState(() {
        _isAuthenticating = false;
        if (result == BiometricResult.success) {
          _isLocked = false;
        } else {
          // Stay locked if they cancel or it fails, giving them a button to retry
          _isLocked = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLocked)
          Container(
            color: AppColors.primary,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'App Locked',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!_isAuthenticating)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _unlockApp,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock'),
                    )
                  else
                    const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
