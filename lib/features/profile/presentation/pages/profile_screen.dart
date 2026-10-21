import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/common_widgets/budget_dialog.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/theme/theme_provider.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/profile/presentation/widgets/change_password_dialog.dart';
import 'package:expense_tracker/features/profile/presentation/widgets/edit_profile_dialog.dart';
import 'package:expense_tracker/features/profile/presentation/widgets/profile_header.dart';
import 'package:expense_tracker/features/profile/presentation/widgets/profile_menu_widgets.dart';
import 'package:expense_tracker/features/profile/presentation/widgets/profile_notifications_section.dart';
import 'package:expense_tracker/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/services/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userEmail;
  String? _userName;
  String? _userImagePath;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = await sl<IAuthRepository>().getUserEmail();
    final name = await sl<IAuthRepository>().getUserName();
    final imagePath = await sl<IAuthRepository>().getUserImagePath();
    if (mounted) {
      setState(() {
        _userEmail = email;
        _userName = name;
        _userImagePath = imagePath;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Logout",
          style: AppTextStyles.heading2
              .copyWith(color: context.appColors.textPrimary),
        ),
        content: Text(
          "Are you sure you want to log out of your account?",
          style: AppTextStyles.bodyMedium
              .copyWith(color: context.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel",
                style: TextStyle(color: context.appColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Logout",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<AuthBloc>().add(LogoutRequested());
      if (context.mounted) {
        context.go(RoutePaths.login);
      }
    }
  }

  String _getDisplayName() {
    if (_userName != null && _userName!.isNotEmpty) {
      return _userName!;
    }
    if (_userEmail != null && _userEmail!.isNotEmpty) {
      final part = _userEmail!.split('@')[0];
      if (part.isNotEmpty) {
        return part[0].toUpperCase() + part.substring(1);
      }
    }
    return "User";
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          // 1. Sticky curved header
          ProfileHeader(
            userImagePath: _userImagePath,
            onAvatarTap: () async {
              final result = await showDialog(
                context: context,
                builder: (ctx) => EditProfileDialog(
                  initialName: _getDisplayName(),
                  initialImagePath: _userImagePath,
                ),
              );
              if (result == true) {
                _loadUser(); // Refresh the profile details!
              }
            },
          ),

          // 2. Scrollable Body: scroll view starts below the avatar and scrolls smoothly
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Profile Name & Email
                  Text(
                    _getDisplayName(),
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 22,
                      color: c.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail ?? "guest@expensetracker.com",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Stats Row
                  const ProfileStatsRow(),

                  const SizedBox(height: 24),

                  // Menu settings list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ACCOUNT & BUDGET",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: c.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ProfileSectionCard(
                          children: [
                            ProfileMenuItem(
                              icon: Icons.account_balance_wallet_outlined,
                              title: "Monthly Budgeting",
                              subtitle: "Track your monthly spending limits",
                              color: AppColors.incomeGreen,
                              onTap: () async {
                                final now = DateTime.now();
                                final allBudgets = await sl<DatabaseHelper>()
                                    .getBudgets(_userEmail);
                                final existingBudget = allBudgets
                                    .where((b) =>
                                        b.category == AppStrings.total &&
                                        b.month == now.month &&
                                        b.year == now.year)
                                    .firstOrNull;

                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => BudgetDialog(
                                      userEmail: _userEmail,
                                      month: now.month,
                                      year: now.year,
                                      initialBudget: existingBudget,
                                    ),
                                  );
                                }
                              },
                            ),
                            ProfileMenuItem(
                              icon: Icons.category_outlined,
                              title: "Categories",
                              subtitle:
                                  "Add, edit or delete expense & income categories",
                              color: Colors.teal,
                              onTap: () {
                                context.push(RoutePaths.editCategories);
                              },
                            ),
                            const ProfileDivider(),
                            ProfileMenuItem(
                              icon: Icons.lock_outline_rounded,
                              title: "Change Password",
                              subtitle: "Update account authentication settings",
                              color: Colors.orange,
                              onTap: () {
                                if (_userEmail != null) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => ChangePasswordDialog(
                                        userEmail: _userEmail!),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "User details not loaded yet. Please try again."),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── NOTIFICATIONS ──────────────────────────────────
                        ProfileNotificationsSection(userEmail: _userEmail),

                        const SizedBox(height: 24),

                        Text(
                          "PREFERENCES & ACTIONS",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: c.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ProfileSectionCard(
                          children: [
                            ProfileMenuItem(
                              icon: isDark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              title: "Dark Mode",
                              subtitle: isDark
                                  ? "On — using dark colors"
                                  : "Off — using light colors",
                              color: Colors.deepPurple,
                              trailing: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: isDark,
                                  onChanged: (_) =>
                                      themeProvider.toggleTheme(),
                                  activeColor: AppColors.primary,
                                  activeTrackColor:
                                      AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                            ),
                            const ProfileDivider(),
                            ProfileMenuItem(
                              icon: Icons.logout_rounded,
                              title: "Logout",
                              subtitle: "Safely sign out of your account",
                              color: AppColors.expenseRed,
                              trailing: const SizedBox.shrink(),
                              onTap: () => _handleLogout(context),
                            ),
                          ],
                        ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
