import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

/// Builds the notifications the user actually sees.
///
/// The server carries text plus a URL; everything about how a notification
/// *looks* is decided here. Three shapes, because three kinds of news deserve
/// to look different:
///
/// * **message** - the sender's face as the large icon, the way a chat app does
///   it, so a message is recognisable before it is read.
/// * **forum** - the author's picture beside the text, the app icon still the
///   badge, which is how a feed notification reads.
/// * **activity / call_missed** - the app icon alone. There is no single face
///   behind a system update, and a missed call needs urgency, not decoration.
class RichNotification {
  RichNotification(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// One channel per kind, so the phone can sound, group and silence them
  /// separately. A missed call must not arrive sounding like a forum reply.
  static const Map<String, List<String>> _channels = {
    'messages_channel': ['Messages', 'New direct and community messages'],
    'forum_channel': ['Forum', 'Replies on posts you follow'],
    'activity_channel': ['Activity', 'Updates about your account'],
    'calls_channel': ['Calls', 'Missed voice and video calls'],
  };

  /// Android needs channels to exist before the first notification arrives,
  /// otherwise it falls back to a default with the wrong importance and the
  /// sound settings are silently ignored.
  Future<void> createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    for (final entry in _channels.entries) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          entry.key,
          entry.value[0],
          description: entry.value[1],
          importance: Importance.max,
        ),
      );
    }
  }

  /// Downloads the avatar. Returns null on any failure - a notification
  /// without a picture is fine, one that never arrives is not.
  Future<Uint8List?> _fetchAvatar(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
      // A huge image must not hold up the notification.
      if (res.bodyBytes.lengthInBytes > 2 * 1024 * 1024) return null;
      return res.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  static String channelFor(String? kind) {
    switch (kind) {
      case 'message':
        return 'messages_channel';
      case 'forum':
        return 'forum_channel';
      case 'call_missed':
        return 'calls_channel';
      default:
        return 'activity_channel';
    }
  }

  Future<void> show({
    required String title,
    required String body,
    String? kind,
    String? avatarUrl,
    String? payload,
  }) async {
    final channelId = channelFor(kind);
    final channel = _channels[channelId]!;

    // Only the kinds with a person behind them carry a face.
    final wantsAvatar = kind == 'message' || kind == 'forum';
    final avatar = wantsAvatar ? await _fetchAvatar(avatarUrl) : null;

    final StyleInformation style = (kind == 'message' || kind == 'forum')
        ? BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: kind == 'message' ? 'Message' : 'Forum',
          )
        : const DefaultStyleInformation(false, false);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channel[0],
        channelDescription: channel[1],
        importance: Importance.max,
        priority: Priority.high,
        // A monochrome silhouette, not the launcher icon: Android throws away
        // a small icon's colour and keeps only its alpha, so a fully opaque
        // launcher PNG is drawn as a solid white square.
        icon: '@drawable/ic_notification',
        largeIcon: avatar == null ? null : ByteArrayAndroidBitmap(avatar),
        styleInformation: style,
        // A missed call is time-sensitive; the rest can wait to be read.
        category: kind == 'call_missed'
            ? AndroidNotificationCategory.missedCall
            : AndroidNotificationCategory.message,
        // Messages collapse together instead of stacking up one per line.
        groupKey: kind == 'message' ? 'wisper_messages' : null,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
