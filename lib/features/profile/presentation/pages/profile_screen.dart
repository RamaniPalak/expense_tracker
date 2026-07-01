import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/theme_provider.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/common_widgets/budget_dialog.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'dart:io';
import 'package:expense_tracker/features/profile/presentation/widgets/change_password_dialog.dart';
import 'package:expense_tracker/features/profile/presentation/widgets/edit_profile_dialog.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

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
          style: AppTextStyles.heading2.copyWith(color: context.appColors.textPrimary),
        ),
        content: Text(
          "Are you sure you want to log out of your account?",
          style: AppTextStyles.bodyMedium.copyWith(color: context.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: TextStyle(color: context.appColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await sl<IAuthRepository>().logout();
      if (context.mounted) {
        context.go(RoutePaths.onboarding);
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
          // 1. Sticky curved header (using the original custom clipper design)
          _buildStickyCurvedHeader(context),

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
                  _buildStatsRow(),

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
                        _buildSectionCard([
                          _buildMenuItem(
                            icon: Icons.account_balance_wallet_outlined,
                            title: "Monthly Budgeting",
                            subtitle: "Track your monthly spending limits",
                            color: AppColors.incomeGreen,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => BudgetDialog(userEmail: _userEmail),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.lock_outline_rounded,
                            title: "Change Password",
                            subtitle: "Update account authentication settings",
                            color: Colors.orange,
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
                        ]),

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
                        _buildSectionCard([
                          _buildMenuItem(
                            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            title: "Dark Mode",
                            subtitle: isDark ? "On — using dark colors" : "Off — using light colors",
                            color: Colors.deepPurple,
                            trailing: Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: isDark,
                                onChanged: (_) => themeProvider.toggleTheme(),
                                activeColor: AppColors.primary,
                                activeTrackColor: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.logout_rounded,
                            title: "Logout",
                            subtitle: "Safely sign out of your account",
                            color: AppColors.expenseRed,
                            trailing: const SizedBox.shrink(),
                            onTap: () => _handleLogout(context),
                          ),
                        ]),

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

  Widget _buildStickyCurvedHeader(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: 236, // height of header container (190 curved background + offset avatar)
      width: double.infinity,
      color: c.background,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Original Curved Top Header with mainGradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: ProfileHeaderClipper(),
              child: Container(
                height: 190,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.mainGradient,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 38), // Balance notification icon size to keep title centered
                            Expanded(
                              child: Center(
                                child: Text(
                                  "Profile Settings",
                                  style: AppTextStyles.heading2.copyWith(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.notifications_none_rounded,
                                  color: AppColors.white, size: 22),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Circle Avatar Centered at the Bottom of the curve (With Edit overlay)
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: () async {
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
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: c.background,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: c.inputFill,
                      backgroundImage: _userImagePath != null && File(_userImagePath!).existsSync()
                          ? FileImage(File(_userImagePath!)) as ImageProvider
                          : const NetworkImage('https://i.pravatar.cc/300?img=5'),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.background, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 14,
                      ),
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

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.account_balance_wallet_outlined,
              label: "Budget",
              value: "Active",
              color: AppColors.incomeGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatItem(
              icon: Icons.stars_outlined,
              label: "Plan",
              value: "Free Tier",
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.border.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: c.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> items) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: c.border.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: c.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right_rounded,
              color: c.textSecondary.withOpacity(0.6),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final c = context.appColors;
    return Divider(
      height: 1,
      thickness: 1,
      color: c.divider.withOpacity(0.5),
      indent: 64,
    );
  }
}

class ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);

    var controlPoint = Offset(size.width / 2, size.height + 20);
    var endPoint = Offset(size.width, size.height - 50);

    path.quadraticBezierTo(
        controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
