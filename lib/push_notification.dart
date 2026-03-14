import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────
// BACKGROUND HANDLER — top-level function (must be outside class)
// App killed বা background এ থাকলে এই function call হবে
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Incoming call notification এলে callkit দেখাও ──
  if (message.data['type'] == 'incoming_call') {
    await showCallkitIncoming(message.data);
    return;
  }

  // ── Regular notification ──
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
// CALLKIT SHOW — background ও foreground দুই জায়গায় ব্যবহার হবে
// ─────────────────────────────────────────────────────────────
Future<void> showCallkitIncoming(Map<String, dynamic> data) async {
  // call_id না থাকলে একটা generate করো
  final callId = data['call_id'] ?? const Uuid().v4();
  final callerName = data['caller_name'] ?? 'Unknown';
  final callerImage = data['caller_image'] ?? '';
  final callType = data['call_type'] == 'VIDEO' ? 1 : 0; // 0=audio, 1=video
  final channelName = data['channel_name'] ?? '';
  final agoraToken = data['agora_token'] ?? '';

  final params = CallKitParams(
    id: callId,
    nameCaller: callerName,
    appName: 'Wisper',
    avatar: callerImage.isNotEmpty ? callerImage : null,
    handle: callerName,
    type: callType,
    textAccept: 'Accept',
    textDecline: 'Decline',
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: true,
      subtitle: 'Missed call',
      callbackText: 'Call back',
    ),
    duration: 45000, // 45 seconds ring
    extra: {
      'call_id': callId,
      'channel_name': channelName,
      'agora_token': agoraToken,
      'call_type': data['call_type'] ?? 'AUDIO',
      'caller_id': data['caller_id'] ?? '',
      'caller_name': callerName,
      'caller_image': callerImage,
    },
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#1E1E1E',
      actionColor: '#4CAF50',
      textColor: '#ffffff',
      isShowCallID: false,
    ),
    ios: const IOSParams(
      iconName: 'AppIcon',
      handleType: 'generic',
      supportsVideo: true,
      maximumCallGroups: 1,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
    ),
  );

  await FlutterCallkitIncoming.showCallkitIncoming(params);
  debugPrint('📞 Callkit shown for: $callerName | callId: $callId');
}

// ─────────────────────────────────────────────────────────────
// PUSH NOTIFICATION SERVICE CLASS
// ─────────────────────────────────────────────────────────────
class PushNotificationService { 
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification tap callback (non-call notifications এর জন্য)
  Function(String? payload)? onNotificationTap;

  // VoIP token callback — server এ পাঠানোর জন্য
  Function(String token)? onVoipToken;

  Future<void> init({
    Function(String? payload)? onTap,
    Function(String token)? onVoipToken,
  }) async {
    onNotificationTap = onTap;
    this.onVoipToken = onVoipToken;

    await _requestPermission();
    await _initLocalNotifications();

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // ── Foreground message ──
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📩 Foreground FCM: ${message.data}');

      // Incoming call → callkit দেখাও (socket না থাকলে fallback হিসেবে)
      // সাধারণত app open থাকলে socket handle করবে, তবুও safeguard
      if (message.data['type'] == 'incoming_call') {
        debugPrint('📞 Foreground call notification — socket should handle this');
        // socket service handle করবে, তাই এখানে কিছু করছি না
        return;
      }

      _showNotification(
        title: message.notification?.title,
        body: message.notification?.body,
        payload: message.data['route'],
      );
    });

    // ── App opened from background (notification tap) ──
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('📲 Opened from background: ${message.data}');
      if (message.data['type'] != 'incoming_call') {
        onNotificationTap?.call(message.data['route']);
      }
    });

    // ── App opened from terminated state ──
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('💀 Opened from terminated: ${initialMessage.data}');
      if (initialMessage.data['type'] != 'incoming_call') {
        onNotificationTap?.call(initialMessage.data['route']);
      }
    }

    await _initFCMToken();

    // ── iOS VoIP token ──
    if (Platform.isIOS) {
      await _initVoipToken();
    }
  }

  // ── iOS VoIP token নাও ──
  Future<void> _initVoipToken() async {
    try {
      final voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      if (voipToken != null && voipToken.isNotEmpty) {
        debugPrint('📱 VoIP Token: $voipToken');
        onVoipToken?.call(voipToken);
      } else {
        debugPrint('⚠️ VoIP token empty, will retry on refresh');
      }
    } catch (e) {
      debugPrint('❌ VoIP token error: $e');
    }
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
          // TODO: server এ পাঠাও
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