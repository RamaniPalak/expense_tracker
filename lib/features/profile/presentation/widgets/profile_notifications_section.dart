import 'package:flutter/material.dart';

import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/profile/presentation/widgets/profile_menu_widgets.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/services/notification_service.dart';

/// Section widget for profile notification toggles (Daily Reminders & Bill Due Reminders).
class ProfileNotificationsSection extends StatefulWidget {
  final String? userEmail;

  const ProfileNotificationsSection({
    super.key,
    required this.userEmail,
  });

  @override
  State<ProfileNotificationsSection> createState() =>
      _ProfileNotificationsSectionState();
}

class _ProfileNotificationsSectionState
    extends State<ProfileNotificationsSection> {
  bool _dailyReminderEnabled = false;
  bool _billReminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _notifSettingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final ns = NotificationService.instance;
    final daily = await ns.isDailyReminderEnabled();
    final bill = await ns.isBillReminderEnabled();
    final hour = await ns.getDailyReminderHour();
    final minute = await ns.getDailyReminderMinute();
    if (mounted) {
      setState(() {
        _dailyReminderEnabled = daily;
        _billReminderEnabled = bill;
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
        _notifSettingsLoaded = true;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: 'SELECT DAILY REMINDER TIME',
    );
    if (picked != null && mounted) {
      setState(() => _reminderTime = picked);
      await NotificationService.instance.setDailyReminderTime(
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTIFICATIONS',
          style: AppTextStyles.bodySmall.copyWith(
            color: c.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ProfileSectionCard(
          children: [
            // Daily reminder toggle
            ProfileMenuItem(
              icon: Icons.alarm_rounded,
              title: 'Daily Expense Reminder',
              subtitle: 'Get a nudge to log your expenses every day',
              color: AppColors.primary,
              trailing: _notifSettingsLoaded
                  ? Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _dailyReminderEnabled,
                        onChanged: (val) async {
                          setState(() => _dailyReminderEnabled = val);
                          await NotificationService.instance
                              .setDailyReminderEnabled(enabled: val);
                        },
                        activeColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withOpacity(0.3),
                      ),
                    )
                  : const SizedBox(
                      width: 36,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            // Reminder time row — only visible when daily is ON
            if (_dailyReminderEnabled) ...[
              const ProfileDivider(),
              ProfileMenuItem(
                icon: Icons.schedule_rounded,
                title: 'Reminder Time',
                subtitle: _reminderTime.format(context),
                color: Colors.deepOrange,
                onTap: _pickReminderTime,
              ),
              const ProfileDivider(),
              ProfileMenuItem(
                icon: Icons.notifications_active_rounded,
                title: 'Test Notification Now',
                subtitle: 'Tap to trigger instant local notification banner',
                color: Colors.teal,
                onTap: () async {
                  await NotificationService.instance.requestPermissions();
                  await NotificationService.instance
                      .showInstantTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Instant test notification triggered! Check status bar & notification bell.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
            const ProfileDivider(),
            // Bill reminders toggle
            ProfileMenuItem(
              icon: Icons.receipt_long_rounded,
              title: 'Bill Due Reminders',
              subtitle: 'Notify 1 day before a bill is due',
              color: Colors.orange,
              trailing: _notifSettingsLoaded
                  ? Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _billReminderEnabled,
                        onChanged: (val) async {
                          setState(() => _billReminderEnabled = val);
                          await NotificationService.instance
                              .setBillReminderEnabled(enabled: val);
                          // If turning back ON, reschedule all existing unpaid bills
                          if (val && widget.userEmail != null) {
                            final bills = await sl<DatabaseHelper>()
                                .getBills(widget.userEmail);
                            for (final bill in bills) {
                              if (!bill.isPaid && bill.id != null) {
                                final dueDate = bill.dueDate;
                                final reminderDate = DateTime(
                                  dueDate.year,
                                  dueDate.month,
                                  dueDate.day,
                                  9,
                                  0,
                                ).subtract(const Duration(days: 1));
                                await NotificationService.instance
                                    .scheduleBillReminder(
                                  id: bill.id!,
                                  title: 'Upcoming Bill: ${bill.title}',
                                  body:
                                      'Your bill of ₹${bill.amount.toStringAsFixed(2)} is due tomorrow.',
                                  scheduledDate: reminderDate,
                                );
                              }
                            }
                          }
                        },
                        activeColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withOpacity(0.3),
                      ),
                    )
                  : const SizedBox(
                      width: 36,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
