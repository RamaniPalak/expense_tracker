import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/theme_provider.dart';
import 'package:expense_tracker/features/profile/presentation/widgets/profile_helper.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/common_widgets/budget_dialog.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/features/profile/presentation/widgets/change_password_dialog.dart';

import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = await sl<IAuthRepository>().getUserEmail();
    if (mounted) {
      setState(() {
        _userEmail = email;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await sl<IAuthRepository>().logout();
    if (context.mounted) {
      context.go(RoutePaths.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            ProfileHelper.buildHeader(context),

            const SizedBox(height: 60),

            // Name and Handle
            Text(
              _userEmail?.split('@')[0] ?? "User",
              style: AppTextStyles.heading2.copyWith(
                fontSize: 22,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userEmail ?? "@unknown",
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),

            // Menu Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ProfileHelper.buildMenuItem(
                    context: context,
                    icon: Icons.diamond_outlined,
                    title: "Invite Friends",
                    iconColor: Colors.white,
                    iconBgColor: AppColors.primary,
                  ),
                  const Divider(height: 30),
                  ProfileHelper.buildMenuItem(
                      context: context,
                      icon: Icons.person,
                      title: "Account info"),
                  const SizedBox(height: 24),
                  ProfileHelper.buildMenuItem(
                      context: context,
                      icon: Icons.people,
                      title: "Personal profile"),
                  const SizedBox(height: 24),
                  ProfileHelper.buildMenuItem(
                    context: context,
                    icon: Icons.security,
                    title: "Change Password",
                    onTap: () {
                      if (_userEmail != null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => ChangePasswordDialog(userEmail: _userEmail!),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("User details not loaded yet. Please try again."),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ProfileHelper.buildMenuItem(
                    context: context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Monthly Budgeting",
                    iconColor: Colors.white,
                    iconBgColor: AppColors.secondary,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => BudgetDialog(userEmail: _userEmail),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ProfileHelper.buildMenuItem(
                      context: context,
                      icon: Icons.lock_outline,
                      title: "Data and privacy"),
                  const SizedBox(height: 24),

                  // ── Dark Mode Toggle ──────────────────────────────────────
                  _buildDarkModeToggle(context, isDark, themeProvider),

                  const Divider(height: 30),

                  ProfileHelper.buildMenuItem(
                    context: context,
                    icon: Icons.logout,
                    title: "Logout",
                    iconColor: Colors.white,
                    iconBgColor: AppColors.expenseRed,
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(
    BuildContext context,
    bool isDark,
    ThemeProvider themeProvider,
  ) {
    return InkWell(
      onTap: () => themeProvider.toggleTheme(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1C1E2A), Color(0xFF252836)],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06),
                    AppColors.secondary.withValues(alpha: 0.04),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.greyLight,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? AppColors.primary : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dark Mode",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    isDark ? "On — enjoying the dark side" : "Off — using light mode",
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Animated switch
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
