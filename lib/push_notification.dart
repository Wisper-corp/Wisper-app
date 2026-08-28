import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/urls.dart';
import 'package:wisper/app/core/services/notifications/rich_notification.dart';
import 'package:uuid/uuid.dart';
import 'package:wisper/app/core/others/get_storage.dart';

// ─────────────────────────────────────────────────────────────
// BACKGROUND HANDLER — top-level function (must be outside class)
// Android pushes arrive data-only so that this app, not the system tray, draws
// them - only a notification we build ourselves can carry the sender's photo as
// its large icon. Title and body therefore come out of `data`; the
// `notification` block is only still read as a fallback.
String _pushTitle(RemoteMessage m) =>
    (m.data['title'] as String?)?.trim().isNotEmpty == true
        ? m.data['title'] as String
        : (m.notification?.title ?? 'Wisper');

String _pushBody(RemoteMessage m) =>
    (m.data['body'] as String?)?.trim().isNotEmpty == true
        ? m.data['body'] as String
        : (m.notification?.body ?? '');

// ─────────────────────────────────────────────────────────────
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
    android: AndroidInitializationSettings('@drawable/ic_notification'),
    iOS: DarwinInitializationSettings(),
  );
  await plugin.initialize(initSettings);

  // The look of a notification is decided here, from the kind and avatar the
  // server sent - a message shows the sender's face, a forum reply the
  // author's, an activity update neither.
  final rich = RichNotification(plugin);
  await rich.createChannels();
  await rich.show(
    title: _pushTitle(message),
    body: _pushBody(message),
    kind: message.data['type'] as String?,
    avatarUrl: message.data['avatar_url'] as String?,
    payload: message.data['chatId'] as String? ??
        message.data['post_id'] as String?,
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
        debugPrint(
          '📞 Foreground call notification — socket should handle this',
        );
        // socket service handle করবে, তাই এখানে কিছু করছি না
        return;
      }

      _showNotification(
        title: _pushTitle(message),
        body: _pushBody(message),
        kind: message.data['type'] as String?,
        avatarUrl: message.data['avatar_url'] as String?,
        payload: message.data['route'] as String? ??
            message.data['chatId'] as String? ??
            message.data['post_id'] as String?,
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
    final voipToken = await getVoipToken();
    if (voipToken != null && voipToken.isNotEmpty) {
      onVoipToken?.call(voipToken);
    }
  }

  Future<String?> getVoipToken() async {
    if (!Platform.isIOS) return null;

    try {
      final voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      if (voipToken != null && voipToken.isNotEmpty) {
        debugPrint('📱 VoIP Token: $voipToken');
        await StorageUtil.setVoipToken(voipToken);
        return voipToken;
      } else {
        debugPrint('⚠️ VoIP token empty, will retry on refresh');
      }
    } catch (e) {
      debugPrint('❌ VoIP token error: $e');
    }

    return StorageUtil.getVoipToken();
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
    try {
      final token = await getToken();
      debugPrint('📱 FCM Token: $token');
      // Storing it locally is not enough: the server sends the notification,
      // so it needs the address. Without this the token column never changes
      // and every push fails with NotRegistered after the first reinstall.
      await syncTokenToServer(token);
    } catch (e) {
      debugPrint('❌ FCM token error: $e');
      return;
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      debugPrint('🔄 FCM Token refreshed: $t');
      await StorageUtil.setFcmToken(t);
      // Firebase rotates tokens on reinstall, restore and clear-data. Each
      // rotation must reach the server or delivery stops silently.
      await syncTokenToServer(t);
    });
  }

  /// Hands the device's token to the server.
  ///
  /// Safe to call repeatedly and safe to call while signed out - without an
  /// access token there is no user to attach it to, so it waits. Call it again
  /// after login, which is why it is public.
  Future<void> syncTokenToServer([String? token]) async {
    try {
      final accessToken = StorageUtil.getData(StorageUtil.userAccessToken);
      if (accessToken == null || accessToken.toString().isEmpty) {
        debugPrint('ℹ️ FCM token not sent: signed out');
        return;
      }

      final value = token ?? await FirebaseMessaging.instance.getToken();
      if (value == null || value.isEmpty) return;

      final res = await Get.find<NetworkCaller>().patchRequest(
        Urls.updateFcmTokenUrl,
        body: {'fcmToken': value},
        accessToken: accessToken,
      );
      debugPrint(res.isSuccess
          ? '✅ FCM token saved to server'
          : '⚠️ FCM token not saved: ${res.errorMessage}');
    } catch (e) {
      // Never let this break startup - a missing notification is bad, a
      // crash on launch is worse.
      debugPrint('⚠️ FCM token sync failed: $e');
    }
  }

  Future<String?> getToken({
    Duration apnsTimeout = const Duration(seconds: 12),
  }) async {
    if (Platform.isIOS) {
      final deadline = DateTime.now().add(apnsTimeout);
      while (DateTime.now().isBefore(deadline)) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null || apnsToken.isEmpty) {
        debugPrint('⚠️ APNs token not available yet after device registration');
        return null;
      }
      debugPrint('🍎 APNs token ready: $apnsToken');
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await StorageUtil.setFcmToken(token);
    }
    return token;
  }

  Future<void> _initLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
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
    String? kind,
    String? avatarUrl,
  }) async {
    await RichNotification(_localNotifications).show(
      title: title ?? 'Wisper',
      body: body ?? '',
      kind: kind,
      avatarUrl: avatarUrl,
      payload: payload,
    );
  }
}
