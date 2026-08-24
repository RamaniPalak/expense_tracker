import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/features/notifications/data/models/app_notification_model.dart';

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

    await _createNotificationChannels();

    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('[NotificationService] Local timezone initialized to: $timeZoneName');
    } catch (e) {
      debugPrint('[NotificationService] Could not set local timezone, fallback: $e');
    }

    await requestPermissions();

    // Auto-restore daily reminder on app start if it was enabled
    await _restoreDailyReminderIfEnabled();
  }

  // ── Create Notification Channels for Android ───────────────────────────
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    const dailyChannel = AndroidNotificationChannel(
      'daily_reminder_channel',
      'Daily Reminders',
      description: 'Daily expense logging reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const billChannel = AndroidNotificationChannel(
      'bill_reminders_channel',
      'Bill Reminders',
      description: 'Notifications for upcoming bills and rent',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const budgetChannel = AndroidNotificationChannel(
      'budget_alerts_channel',
      'Budget & Overspending Alerts',
      description: 'Alerts when approaching or exceeding category budget limits',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidImpl?.createNotificationChannel(dailyChannel);
    await androidImpl?.createNotificationChannel(billChannel);
    await androidImpl?.createNotificationChannel(budgetChannel);
  }

  // ── Permissions ───────────────────────────────────────────────────────────────
  Future<void> requestPermissions() async {
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('[NotificationService] permission_handler request error: $e');
    }

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImpl =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
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

  /// Instantly show a test notification banner (useful for immediate local verification)
  Future<void> showInstantTestNotification({
    String title = '💰 Daily Expense Check-In (Test)',
    String body = "Don't forget to log today's expenses. Stay on top of your budget!",
  }) async {
    await _notificationsPlugin.show(
      999,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily expense logging reminders',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    // Save to in-app notification center
    await DatabaseHelper.instance.insertNotification(
      AppNotificationModel(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: body,
        timestamp: DateTime.now(),
        type: NotificationType.reminder,
        actionRoute: '/add-expense',
        userEmail: '',
      ),
    );

    debugPrint('[NotificationService] Instant test notification displayed');
  }

  // ── Show Budget Alert Notification ─────────────────────────────────────────
  Future<void> showBudgetAlertNotification({
    required String title,
    required String body,
    required String userEmail,
  }) async {
    final notifId = DateTime.now().millisecondsSinceEpoch % 100000;
    await _notificationsPlugin.show(
      notifId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts_channel',
          'Budget & Overspending Alerts',
          channelDescription: 'Notifications for budget alerts and spending limits',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    // Save to in-app notification center
    await DatabaseHelper.instance.insertNotification(
      AppNotificationModel(
        id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: body,
        timestamp: DateTime.now(),
        type: NotificationType.budget,
        actionRoute: '/statistics',
        userEmail: userEmail,
      ),
    );

    debugPrint('[NotificationService] Budget alert notification displayed: $title');
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
    
    // If the scheduled time is earlier than or equal to current local time, schedule for tomorrow
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
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
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('[NotificationService] Daily reminder scheduled exact at $scheduled (Local: ${tz.local.name})');
    } catch (e) {
      // Fallback if exact alarms permission is disabled by user in OS settings
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
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('[NotificationService] Daily reminder scheduled inexact fallback: $e');
    }
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
