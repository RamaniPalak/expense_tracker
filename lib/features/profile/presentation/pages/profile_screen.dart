import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/features/profile/presentation/widgets/profile_helper.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/common_widgets/budget_dialog.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            ProfileHelper.buildHeader(context),

            const SizedBox(height: 60), // Spacing for the profile image

            // Name and Handle
            Text(
              _userEmail?.split('@')[0] ?? "User",
              style: AppTextStyles.heading2
                  .copyWith(fontSize: 22, color: AppColors.textPrimary),
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
                    icon: Icons.diamond_outlined,
                    title: "Invite Friends",
                    iconColor: Colors.white,
                    iconBgColor: AppColors.primary,
                  ),
                  const Divider(height: 30, color: AppColors.greyLight),
                  ProfileHelper.buildMenuItem(
                      icon: Icons.person, title: "Account info"),
                  const SizedBox(height: 24),
                  ProfileHelper.buildMenuItem(
                      icon: Icons.people, title: "Personal profile"),
                  const SizedBox(height: 24),
                  ProfileHelper.buildMenuItem(
                      icon: Icons.security, title: "Login and security"),
                  const SizedBox(height: 24),
                  ProfileHelper.buildMenuItem(
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
                      icon: Icons.lock_outline, title: "Data and privacy"),
                  const SizedBox(height: 24),
                  ProfileHelper.buildMenuItem(
                    icon: Icons.logout,
                    title: "Logout",
                    iconColor: Colors.white,
                    iconBgColor: AppColors.expenseRed,
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Bottom padding for scrolling
          ],
        ),
      ),
    );
  }
}
