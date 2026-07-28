import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'dart:io';

// ── SharedPreferences keys ─────────────────────────────────────────────────────
const String _kDailyReminderEnabled = 'notif_daily_reminder_enabled';
const String _kDailyReminderHour    = 'notif_daily_reminder_hour';
const String _kDailyReminderMinute  = 'notif_daily_reminder_minute';
const String _kBillReminderEnabled  = 'notif_bill_reminder_enabled';

// ── Notification IDs ───────────────────────────────────────────────────────────
const int _kDailyReminderId = 0; // reserved for the daily reminder

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ── Initialise ────────────────────────────────────────────────────────────────
  Future<void> init() async {
    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    tz.initializeTimeZones();
    await requestPermissions();

    // Auto-restore daily reminder on app start if it was enabled
    await _restoreDailyReminderIfEnabled();
  }

  // ── Permissions ───────────────────────────────────────────────────────────────
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImpl =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SETTINGS GETTERS  (all backed by SharedPreferences)
  // ────────────────────────────────────────────────────────────────────────────

  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDailyReminderEnabled) ?? false;
  }

  Future<int> getDailyReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kDailyReminderHour) ?? 20; // default 8 PM
  }

  Future<int> getDailyReminderMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kDailyReminderMinute) ?? 0;
  }

  Future<bool> isBillReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBillReminderEnabled) ?? true; // on by default
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DAILY REMINDER
  // ────────────────────────────────────────────────────────────────────────────

  /// Enable / disable the daily expense logging reminder.
  /// When enabling, schedules it at the persisted (or default) time.
  /// When disabling, cancels the pending notification.
  Future<void> setDailyReminderEnabled({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyReminderEnabled, enabled);

    if (enabled) {
      final hour   = await getDailyReminderHour();
      final minute = await getDailyReminderMinute();
      await _scheduleDailyReminder(hour: hour, minute: minute);
    } else {
      await _notificationsPlugin.cancel(_kDailyReminderId);
    }
  }

  /// Update the daily reminder time. Only reschedules if the reminder is enabled.
  Future<void> setDailyReminderTime({
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDailyReminderHour, hour);
    await prefs.setInt(_kDailyReminderMinute, minute);

    final enabled = await isDailyReminderEnabled();
    if (enabled) {
      await _scheduleDailyReminder(hour: hour, minute: minute);
    }
  }

  /// Enable / disable bill notifications. Does NOT reschedule existing bills —
  /// that is handled by DatabaseHelper when bills are inserted / updated.
  Future<void> setBillReminderEnabled({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBillReminderEnabled, enabled);

    if (!enabled) {
      // Cancel all bill notifications (IDs >= 1)
      // We can't enumerate them, so we cancel a broad range.
      // Bill IDs are SQLite row IDs starting at 1; we cancel up to a large cap.
      await _cancelAllBillNotifications();
    }
    // Re-enabling: individual bills must be rescheduled by DatabaseHelper
    // (called from outside when the toggle turns ON).
  }

  // ── internal: actually schedule the recurring daily notification ───────────
  Future<void> _scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // Cancel any previous daily notification first
    await _notificationsPlugin.cancel(_kDailyReminderId);

    final now       = tz.TZDateTime.now(tz.local);
    var scheduled   = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    // If the time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      _kDailyReminderId,
      '💰 Daily Expense Check-In',
      "Don't forget to log today's expenses. Stay on top of your budget!",
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily expense logging reminders',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Repeats every day at the same time
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint(
        '[NotificationService] Daily reminder scheduled at $hour:$minute');
  }

  /// Called on app launch — silently restores daily reminder if it was set.
  Future<void> _restoreDailyReminderIfEnabled() async {
    final enabled = await isDailyReminderEnabled();
    if (enabled) {
      final hour   = await getDailyReminderHour();
      final minute = await getDailyReminderMinute();
      await _scheduleDailyReminder(hour: hour, minute: minute);
    }
  }

  // ── Cancel all bill reminders (IDs 1 … 9999) ──────────────────────────────
  Future<void> _cancelAllBillNotifications() async {
    // SQLite auto-increment IDs start at 1.
    // Cancel up to 9999 — a safe upper bound for any real app.
    for (int id = 1; id <= 9999; id++) {
      await _notificationsPlugin.cancel(id);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BILL REMINDERS  (called from DatabaseHelper)
  // ────────────────────────────────────────────────────────────────────────────

  /// Schedule a bill reminder 1 day before [scheduledDate] at 09:00.
  /// Guards against past dates and respects the user's bill-reminder toggle.
  Future<void> scheduleBillReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Respect the user's bill reminder toggle
    final billEnabled = await isBillReminderEnabled();
    if (!billEnabled) return;

    // Don't schedule if date is in the past
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders_channel',
          'Bill Reminders',
          channelDescription: 'Notifications for upcoming bills and rent',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint(
        '[NotificationService] Bill reminder scheduled id=$id for $scheduledDate');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CANCEL HELPERS  (used by DatabaseHelper)
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
