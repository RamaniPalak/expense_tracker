import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

/// Sticky curved top header with rotating animated gradient avatar ring and edit badge.
class ProfileHeader extends StatelessWidget {
  final String? userImagePath;
  final VoidCallback onAvatarTap;

  const ProfileHeader({
    super.key,
    required this.userImagePath,
    required this.onAvatarTap,
  });

  ImageProvider _buildAvatarImage() {
    if (userImagePath != null && userImagePath!.isNotEmpty) {
      if (userImagePath!.startsWith('http')) {
        return CachedNetworkImageProvider(userImagePath!);
      }
      final file = File(userImagePath!);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return const CachedNetworkImageProvider('https://i.pravatar.cc/300?img=5');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: 236, // 190 curved background + offset avatar
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 38), // Balance spacing
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
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.white,
                                size: 22,
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
          ),

          // Circle Avatar Centered at the Bottom of the curve (With Edit overlay)
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Stack(
                children: [
                  AnimatedGradientRing(
                    ringWidth: 3.5,
                    radius: 46,
                    backgroundColor: c.background,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: c.inputFill,
                      backgroundImage: _buildAvatarImage(),
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
}

/// Animated rotating sweep gradient ring around avatar.
class AnimatedGradientRing extends StatefulWidget {
  final Widget child;
  final double radius;
  final double ringWidth;
  final Color backgroundColor;

  const AnimatedGradientRing({
    super.key,
    required this.child,
    required this.radius,
    required this.ringWidth,
    required this.backgroundColor,
  });

  @override
  State<AnimatedGradientRing> createState() => _AnimatedGradientRingState();
}

class _AnimatedGradientRingState extends State<AnimatedGradientRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(); // Continuously rotate
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSize = (widget.radius + widget.ringWidth + 3) * 2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          width: totalSize,
          height: totalSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              startAngle: 0,
              endAngle: 3.14159 * 2,
              transform: GradientRotation(_controller.value * 3.14159 * 2),
              colors: const [
                Color(0xFF429690), // teal (primary)
                Color(0xFF80CBC4), // light mint
                Color(0xFFFFD700), // warm gold shimmer
                Color(0xFFFFFFFF), // bright white flash
                Color(0xFF2A7C76), // deep teal (secondary)
                Color(0xFF429690), // loop back to teal
              ],
              stops: const [0.0, 0.2, 0.45, 0.6, 0.8, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF429690).withOpacity(0.45),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: totalSize - (widget.ringWidth * 2),
              height: totalSize - (widget.ringWidth * 2),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: widget.child),
            ),
          ),
        );
      },
    );
  }
}

/// Custom clipper for the curved profile header.
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
