import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/routing/app_router.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class SyncOptionsSheet extends StatelessWidget {
  const SyncOptionsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SyncOptionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Sync Transactions',
            style: AppTextStyles.heading2.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how you want to import your transactions.',
            style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 28),

          // Option Cards Row
          Row(
            children: [
              Expanded(
                child: _SyncOptionCard(
                  icon: Icons.sms_outlined,
                  title: 'Bank SMS',
                  subtitle: 'Bank SMS alerts',
                  badge: 'Android',
                  badgeColor: AppColors.incomeGreen,
                  gradientColors: const [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RoutePaths.smsSyncReview);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SyncOptionCard(
                  icon: Icons.email_outlined,
                  title: 'Email Sync',
                  subtitle: 'Bank email alerts',
                  badge: 'OAuth/IMAP',
                  badgeColor: const Color(0xFF9C27B0),
                  gradientColors: const [
                    Color(0xFF8E24AA),
                    Color(0xFF512DA8),
                  ],
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RoutePaths.emailSyncReview);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SyncOptionCard(
                  icon: Icons.upload_file_outlined,
                  title: 'Import File',
                  subtitle: 'PDF / CSV statement',
                  badge: 'All Devices',
                  badgeColor: const Color(0xFF5B8DEF),
                  gradientColors: const [
                    Color(0xFF5B8DEF),
                    Color(0xFF3B6CD4),
                  ],
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RoutePaths.fileSyncReview);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 16),

          // Manual Entry Link
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push(RoutePaths.addExpense);
              },
              child: Text(
                'Add Transaction Manually',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncOptionCard extends StatefulWidget {
  const _SyncOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.gradientColors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  State<_SyncOptionCard> createState() => _SyncOptionCardState();
}

class _SyncOptionCardState extends State<_SyncOptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.badge,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                widget.title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                widget.subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withAlpha(204),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
