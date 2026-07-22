import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/urls.dart';

// Background handler — must be top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message: ${message.notification?.title}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'wisper_messages',
    'Wisper Messages',
    description: 'Notifications for new messages on Wisper',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
    await _requestPermission();

    // Init local notifications
    await _initLocalNotifications();

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // App opened from background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 Opened from notification: ${message.notification?.title}');
    });

    // Get and save FCM token
    await _saveFcmToken();

    // Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      _updateFcmTokenOnServer(newToken);
    });
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _initLocalNotifications() async {
    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
      },
    );

    // Show foreground notifications on iOS
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'Wisper',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['chatId'],
    );
  }

  Future<void> _saveFcmToken() async {
    try {
      String? token;
      if (Platform.isIOS) {
        // Wait for APNs token on iOS
        token = await FirebaseMessaging.instance.getAPNSToken()
            .timeout(const Duration(seconds: 5))
            .catchError((_) => null);
        if (token != null) {
          token = await FirebaseMessaging.instance.getToken();
        }
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token != null) {
        debugPrint('✅ FCM Token: ${token.substring(0, 20)}...');
        await StorageUtil.saveFcmToken(token);
        await _updateFcmTokenOnServer(token);
      }
    } catch (e) {
      debugPrint('❌ FCM Token error: $e');
    }
  }

  Future<void> _updateFcmTokenOnServer(String token) async {
    try {
      final accessToken = StorageUtil.getData(StorageUtil.userAccessToken);
      if (accessToken == null || accessToken.isEmpty) return;

      await Get.find<NetworkCaller>().patchRequest(
        Urls.updateFcmTokenUrl,
        body: {'fcmToken': token},
        accessToken: accessToken,
      );
      debugPrint('✅ FCM token saved to server');
    } catch (e) {
      debugPrint('⚠️ Could not save FCM token to server: $e');
    }
  }
}
