import 'dart:typed_data';

import 'package:flutter/material.dart';
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

  /// The id a notification is posted under.
  ///
  /// Messages from one chat share an id, so a second message updates that
  /// conversation instead of stacking a duplicate of the same person beneath
  /// the first. Everything else gets a fresh id and stands on its own.
  static int notificationId(String? kind, String? payload) {
    if (kind == 'message' && payload != null && payload.isNotEmpty) {
      // Positive and within the 32-bit range Android allows.
      return payload.hashCode & 0x7fffffff;
    }
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
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

    // A chat message is drawn the way every messaging app draws one:
    // MessagingStyle promotes the sender's photo to the round icon on the
    // left and badges the app icon onto it. A plain largeIcon cannot do that
    // — Android always puts it on the right, with the app icon taking the
    // left, which is backwards for a message from a person.
    final bool isMessage = kind == 'message';

    final Person? sender = isMessage
        ? Person(
            name: title,
            // Keyed by name so replies from the same person are recognised as
            // the same conversation rather than a new one each time.
            key: title,
            icon: avatar == null ? null : ByteArrayAndroidIcon(avatar),
            important: true,
          )
        : null;

    final StyleInformation style = isMessage
        ? MessagingStyleInformation(
            sender!,
            // One-to-one: naming the conversation would repeat the sender.
            groupConversation: false,
            messages: [Message(body, DateTime.now(), sender)],
          )
        : kind == 'forum'
            ? BigTextStyleInformation(
                body,
                contentTitle: title,
                summaryText: 'Forum',
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
        //
        // The bare resource name, not "@drawable/...": the plugin resolves it
        // with getIdentifier(name, "drawable", package), which returns 0 for a
        // prefixed name and makes initialize() fail outright.
        icon: 'ic_notification',
        // The badge Android stamps onto the sender's photo is the small icon,
        // tinted with this. Left unset it comes out grey; WhatsApp's is its
        // own green, so ours is Wisper blue.
        color: const Color(0xff1F7DE9),
        // MessagingStyle carries the face itself; setting largeIcon as well
        // would put a second copy of it on the right.
        largeIcon: (avatar == null || isMessage)
            ? null
            : ByteArrayAndroidBitmap(avatar),
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
      notificationId(kind, payload),
      title,
      body,
      details,
      payload: payload,
    );
  }
}
