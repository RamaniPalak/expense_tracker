import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/features/notifications/data/models/app_notification_model.dart';

// ── SharedPreferences Key for FCM Token ────────────────────────────────────────
const String kFcmTokenKey = 'fcm_device_token';

// ── Top-level background message handler ───────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background processing
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[FCMService] Background Firebase init error: $e');
  }
  debugPrint('[FCMService] Background message received: ${message.messageId}');
  debugPrint('[FCMService] Payload data: ${message.data}');
}

class FCMService {
  static final FCMService instance = FCMService._internal();
  factory FCMService() => instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _token;
  String? get fcmToken => _token;

  // ── Notification Channel for FCM High Priority Banners ─────────────────────
  static const AndroidNotificationChannel _fcmChannel = AndroidNotificationChannel(
    'fcm_push_channel',
    'Remote Notifications',
    description: 'High priority channel for remote push notifications (Saving Goals, Reminders)',
    importance: Importance.max,
    playSound: true,
  );

  /// Initialize Firebase Cloud Messaging listeners & local notification channel
  Future<void> init() async {
    // 1. Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request Notification Permissions
    await requestPermissions();

    // 3. Create Android notification channel for foreground banners
    await _createNotificationChannel();

    // 4. Fetch & store FCM Device Token
    await fetchToken();

    // 5. Listen for token refresh events
    _fcm.onTokenRefresh.listen((newToken) async {
      _token = newToken;
      debugPrint('[FCMService] Token refreshed: $newToken');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kFcmTokenKey, newToken);
    });

    // 6. Setup Foreground Message Handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Setup Background Click Handler (App running in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // 8. Check if App was opened from a terminated state notification click
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }

    // Auto-subscribe user to default topics
    await subscribeToTopic('saving_goals');
    await subscribeToTopic('reminders');
  }

  /// Request permissions for iOS & Android 13+
  Future<NotificationSettings> requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCMService] Permission status: ${settings.authorizationStatus}');
    return settings;
  }

  /// Fetch FCM Token and persist to SharedPreferences
  Future<String?> fetchToken() async {
    try {
      _token = await _fcm.getToken();
      debugPrint('[FCMService] FCM Token: $_token');
      if (_token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kFcmTokenKey, _token!);
      }
    } catch (e) {
      debugPrint('[FCMService] FCM Token fetch note: Firebase app default initialization needed when google-services.json is configured: $e');
    }
    return _token;
  }

  /// Create local notification channel for Android foreground display
  Future<void> _createNotificationChannel() async {
    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_fcmChannel);
  }

  /// Handle incoming foreground messages by displaying a local notification banner
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCMService] Foreground message received: ${message.notification?.title}');
    final title = message.notification?.title ?? message.data['title'] ?? message.data['subject'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';
    final android = message.notification?.android;

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _fcmChannel.id,
          _fcmChannel.name,
          channelDescription: _fcmChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );

    // Save to in-app notification center
    final typeStr = message.data['type'] as String? ?? 'system';
    NotificationType nType = NotificationType.system;
    String? route;
    if (typeStr == 'SAVING_GOAL') {
      nType = NotificationType.goal;
      route = '/goals';
    } else if (typeStr == 'BILL_REMINDER') {
      nType = NotificationType.bill;
      route = '/bills';
    } else if (typeStr == 'DAILY_REMINDER') {
      nType = NotificationType.reminder;
      route = '/add-expense';
    }

    DatabaseHelper.instance.insertNotification(
      AppNotificationModel(
        id: 'fcm_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: body,
        timestamp: DateTime.now(),
        type: nType,
        actionRoute: route,
        userEmail: '',
      ),
    );
  }

  /// Handle user clicking a push notification (Navigating based on payload data)
  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('[FCMService] Notification clicked with data: ${message.data}');
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'SAVING_GOAL':
        final goalId = data['goalId'];
        debugPrint('[FCMService] Navigate to Saving Goal detail for ID: $goalId');
        break;
      case 'BILL_REMINDER':
        debugPrint('[FCMService] Navigate to Bills screen');
        break;
      case 'DAILY_REMINDER':
        debugPrint('[FCMService] Navigate to Home/Add Transaction screen');
        break;
      default:
        debugPrint('[FCMService] General notification clicked');
        break;
    }
  }

  /// Subscribe to specific FCM topic (e.g. "saving_goals", "reminders")
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('[FCMService] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCMService] Could not subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from specific FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('[FCMService] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCMService] Could not unsubscribe from topic $topic: $e');
    }
  }
}
