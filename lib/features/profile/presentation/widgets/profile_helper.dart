import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';

class ProfileHelper {
  static Widget buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ClipPath(
          clipper: ProfileHeaderClipper(),
          child: Container(
            height: 240,
            width: double.infinity,
            color: AppColors.primary,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: AppColors.white, size: 20),
                          onPressed: () {
                            // Handle back if needed
                          },
                        ),
                        const Text(
                          "Profile",
                          style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withAlpha(26), // 0.1 * 255
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              const Icon(Icons.notifications_none,
                                  color: AppColors.white),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.expenseRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Profile Image
        Positioned(
          bottom: -50,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26), // 0.1 * 255
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.white,
              backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/300?img=5'), // Placeholder
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildMenuItem({
    required IconData icon,
    required String title,
    Color iconColor = AppColors.textSecondary,
    Color? iconBgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            if (iconBgColor != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor.withAlpha(26), // 0.1 * 255
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconBgColor, size: 24),
              )
            else
              Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
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
