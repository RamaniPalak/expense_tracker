import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';

/// Two-step forgot-password screen.
///
/// Step 1 — Email entry: user submits their email. The server generates a
///   6-digit OTP, stores it (with 15-minute expiry), and returns it to the
///   client (demo). In production the OTP would be sent via email instead.
///
/// Step 2 — OTP + new password entry: user types the OTP and picks a new
///   password. The server validates the OTP and updates the password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // ── Step tracking ──────────────────────────────────────────────────────────
  int _step = 1; // 1 = email entry, 2 = OTP + new password

  // ── Step 1 controllers ────────────────────────────────────────────────────
  final _emailFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  // ── Step 2 controllers ────────────────────────────────────────────────────
  final _otpFormKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // ── Notifiers (avoid full rebuilds) ───────────────────────────────────────
  final ValueNotifier<bool> _newPasswordVisible = ValueNotifier(false);
  final ValueNotifier<bool> _confirmPasswordVisible = ValueNotifier(false);

  // ── Cached values from BLoC ───────────────────────────────────────────────
  String _resolvedEmail = '';

  /// The OTP returned by the server (demo only – shown in a banner so the
  /// tester can copy-paste it without needing a real email inbox).
  String _demoOtp = '';

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _newPasswordVisible.dispose();
    _confirmPasswordVisible.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _submitEmail() {
    if (_emailFormKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            ForgotPasswordRequested(
              email: _emailCtrl.text.trim().toLowerCase(),
            ),
          );
    }
  }

  void _submitOtp() {
    if (_otpFormKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            VerifyOtpAndResetPasswordRequested(
              email: _resolvedEmail,
              otp: _otpCtrl.text.trim(),
              newPassword: _newPasswordCtrl.text.trim(),
            ),
          );
    }
  }

  void _resendOtp() {
    _otpCtrl.clear();
    context.read<AuthBloc>().add(
          ForgotPasswordRequested(email: _resolvedEmail),
        );
  }

  void _transitionToStep2(String email, String otp) {
    setState(() {
      _step = 2;
      _resolvedEmail = email;
      _demoOtp = otp;
    });
    // Re-run entrance animation for step 2
    _animCtrl.forward(from: 0.0);
  }

  // ── BLoC listener ─────────────────────────────────────────────────────────

  void _onBlocState(BuildContext ctx, AuthState state) {
    if (state is AuthFailure) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (state is PasswordResetOtpSent) {
      _transitionToStep2(state.email, state.otp);
    } else if (state is PasswordResetSuccess) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please log in.'),
          backgroundColor: AppColors.incomeGreen,
        ),
      );
      // Navigate back to login and clear the stack so the user cannot go back
      ctx.go('/login');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: c.textPrimary),
          onPressed: () {
            if (_step == 2) {
              // Go back to step 1 instead of popping screen
              setState(() {
                _step = 1;
                _demoOtp = '';
                _otpCtrl.clear();
                _newPasswordCtrl.clear();
                _confirmPasswordCtrl.clear();
              });
              _animCtrl.forward(from: 0.0);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: _onBlocState,
        builder: (ctx, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _step == 1
                        ? _buildEmailStep(c, isLoading)
                        : _buildOtpStep(c, isLoading),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Step 1 UI ─────────────────────────────────────────────────────────────

  Widget _buildEmailStep(dynamic c, bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Container(
            alignment: Alignment.center,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Forgot Password?',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(
              fontSize: 26,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your registered email address and we'll send you a reset code.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 14,
              color: c.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // Email field
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary),
            decoration: _inputDecoration(
              context: context,
              hint: 'Email Address',
              icon: Icons.email_outlined,
              c: c,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your email';
              }
              final regex = RegExp(
                  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
              if (!regex.hasMatch(v.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Submit button
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Send Reset Code',
                      style: AppTextStyles.buttonText.copyWith(fontSize: 16),
                    ),
                  ),
                ),

          const SizedBox(height: 24),

          // Back to login link
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Text(
                'Back to Login',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2 UI ─────────────────────────────────────────────────────────────

  Widget _buildOtpStep(dynamic c, bool isLoading) {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Container(
            alignment: Alignment.center,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Verify & Reset',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(
              fontSize: 26,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code sent to $_resolvedEmail, then choose a new password.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              color: c.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Demo OTP banner (remove in production)
          if (_demoOtp.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Demo OTP: ',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: c.textSecondary, fontSize: 12),
                        children: [
                          TextSpan(
                            text: _demoOtp,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 3,
                            ),
                          ),
                          TextSpan(
                            text:
                                '  (In production this is sent to your email)',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: c.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // OTP field
          TextFormField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: AppTextStyles.bodyMedium.copyWith(
              color: c.textPrimary,
              fontSize: 20,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            decoration: _inputDecoration(
              context: context,
              hint: '• • • • • •',
              icon: Icons.pin_outlined,
              c: c,
            ).copyWith(counterText: ''),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter the OTP';
              if (v.trim().length != 6) return 'OTP must be 6 digits';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // New password field
          ValueListenableBuilder<bool>(
            valueListenable: _newPasswordVisible,
            builder: (context, isVisible, _) {
              return TextFormField(
                controller: _newPasswordCtrl,
                obscureText: !isVisible,
                style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary),
                decoration: _inputDecoration(
                  context: context,
                  hint: 'New Password',
                  icon: Icons.lock_outline,
                  c: c,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: c.textSecondary,
                    ),
                    onPressed: () =>
                        _newPasswordVisible.value = !isVisible,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a new password';
                  if (v.length < 6) return 'At least 6 characters required';
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Confirm password field
          ValueListenableBuilder<bool>(
            valueListenable: _confirmPasswordVisible,
            builder: (context, isVisible, _) {
              return TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: !isVisible,
                style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary),
                decoration: _inputDecoration(
                  context: context,
                  hint: 'Confirm New Password',
                  icon: Icons.lock_outline,
                  c: c,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: c.textSecondary,
                    ),
                    onPressed: () =>
                        _confirmPasswordVisible.value = !isVisible,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm password';
                  if (v != _newPasswordCtrl.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 32),

          // Reset button
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Reset Password',
                      style: AppTextStyles.buttonText.copyWith(fontSize: 16),
                    ),
                  ),
                ),

          const SizedBox(height: 16),

          // Resend OTP link
          Center(
            child: TextButton(
              onPressed: isLoading ? null : _resendOtp,
              child: Text(
                "Didn't receive code? Resend",
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hint,
    required IconData icon,
    required dynamic c,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
      prefixIcon: Icon(icon, color: c.textSecondary),
      filled: true,
      fillColor: c.inputFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}
