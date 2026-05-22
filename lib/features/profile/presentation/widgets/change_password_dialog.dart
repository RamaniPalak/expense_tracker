import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String userEmail;

  const ChangePasswordDialog({super.key, required this.userEmail});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _isOldVisible = ValueNotifier<bool>(false);
  final _isNewVisible = ValueNotifier<bool>(false);
  final _isConfirmVisible = ValueNotifier<bool>(false);

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _isOldVisible.dispose();
    _isNewVisible.dispose();
    _isConfirmVisible.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await sl<IAuthRepository>().changePassword(
      widget.userEmail,
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    if (mounted) {
      result.fold(
        (err) => setState(() {
          _isLoading = false;
          _errorMessage = err;
        }),
        (_) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Password changed successfully!"),
              backgroundColor: AppColors.incomeGreen,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Change Password",
        style: AppTextStyles.heading2.copyWith(color: c.textPrimary, fontSize: 20),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withAlpha(60)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Old Password
              ValueListenableBuilder<bool>(
                valueListenable: _isOldVisible,
                builder: (context, isVisible, _) {
                  return TextFormField(
                    controller: _oldPasswordController,
                    obscureText: !isVisible,
                    style: TextStyle(color: c.textPrimary),
                    decoration: _inputDecoration(
                      context: context,
                      hint: "Current Password",
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          isVisible ? Icons.visibility : Icons.visibility_off,
                          color: c.textSecondary,
                        ),
                        onPressed: () => _isOldVisible.value = !isVisible,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Please enter your current password";
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // New Password
              ValueListenableBuilder<bool>(
                valueListenable: _isNewVisible,
                builder: (context, isVisible, _) {
                  return TextFormField(
                    controller: _newPasswordController,
                    obscureText: !isVisible,
                    style: TextStyle(color: c.textPrimary),
                    decoration: _inputDecoration(
                      context: context,
                      hint: "New Password",
                      icon: Icons.vpn_key_outlined,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          isVisible ? Icons.visibility : Icons.visibility_off,
                          color: c.textSecondary,
                        ),
                        onPressed: () => _isNewVisible.value = !isVisible,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Please enter your new password";
                      }
                      if (val.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Confirm Password
              ValueListenableBuilder<bool>(
                valueListenable: _isConfirmVisible,
                builder: (context, isVisible, _) {
                  return TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !isVisible,
                    style: TextStyle(color: c.textPrimary),
                    decoration: _inputDecoration(
                      context: context,
                      hint: "Confirm New Password",
                      icon: Icons.check_circle_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          isVisible ? Icons.visibility : Icons.visibility_off,
                          color: c.textSecondary,
                        ),
                        onPressed: () => _isConfirmVisible.value = !isVisible,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Please confirm your new password";
                      }
                      if (val != _newPasswordController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: TextStyle(color: c.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Update",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hint,
    required IconData icon,
  }) {
    final c = context.appColors;
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
      prefixIcon: Icon(icon, color: c.textSecondary),
      filled: true,
      fillColor: c.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
