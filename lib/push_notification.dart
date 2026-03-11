import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─────────────────────────────────────────────────────────────
// BACKGROUND HANDLER — top-level function (must be outside class)
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  final plugin = FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await plugin.initialize(initSettings);

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.notification?.title ?? 'New Notification',
    message.notification?.body ?? '',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel_id',
        'Default Channel',
        channelDescription: 'General notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}
// ─────────────────────────────────────────────────────────────
// PUSH NOTIFICATION SERVICE CLASS
// পরে এই class টা আলাদা file এ নিতে পারবে:
// lib/app/core/services/push_notification/push_notification_service.dart
// ─────────────────────────────────────────────────────────────

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Optional: notification tap callback
  Function(String? payload)? onNotificationTap;

  Future<void> init({Function(String? payload)? onTap}) async {
    onNotificationTap = onTap;

    await _requestPermission();
    await _initLocalNotifications();

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📩 Foreground: ${message.notification?.title}');
      _showNotification(
        title: message.notification?.title,
        body: message.notification?.body,
        payload: message.data['route'],
      );
    });

    // App opened from background (notification tap)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('📲 Opened from background: ${message.notification?.title}');
      onNotificationTap?.call(message.data['route']);
    });

    // App opened from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '💀 Opened from terminated: ${initialMessage.notification?.title}',
      );
      onNotificationTap?.call(initialMessage.data['route']);
    }

    await _initFCMToken();
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Permission: ${settings.authorizationStatus}');
  }

  Future<void> _initFCMToken() async {
    if (Platform.isIOS) {
      String? apnsToken;
      for (int i = 0; i < 3; i++) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) break;
        await Future.delayed(const Duration(seconds: 2));
      }
      if (apnsToken == null) {
        debugPrint('⚠️ APNs token not available, listening for refresh...');
        FirebaseMessaging.instance.onTokenRefresh.listen((t) {
          debugPrint('📱 FCM Token (refresh): $t');
        });
        return;
      }
    }

    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('📱 FCM Token: $token');

    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      debugPrint('🔄 FCM Token refreshed: $t');
      // TODO: নতুন token backend এ পাঠাও
    });
  }

  Future<String?> getToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  Future<void> _initLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('🔔 Tapped, payload: ${response.payload}');
        onNotificationTap?.call(response.payload);
      },
    );

    // Android 8+ channel
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'default_channel_id',
        'Default Channel',
        description: 'General notifications',
        importance: Importance.max,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _showNotification({
    String? title,
    String? body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title ?? 'Notification',
      body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel_id',
          'Default Channel',
          channelDescription: 'General notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}
