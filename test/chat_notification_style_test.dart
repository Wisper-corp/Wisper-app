import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/services/notifications/rich_notification.dart';

/// A chat notification showed the Wisper logo big on the left and the sender's
/// photo as a small square on the right — Android always puts a largeIcon on
/// the right. Every messaging app does the opposite: the sender's photo is the
/// round icon, with the app's logo badged onto its corner. That layout is
/// MessagingStyle, and only a chat message gets it.
void main() {
  final source = File(
    'lib/app/core/services/notifications/rich_notification.dart',
  ).readAsStringSync();

  group('notification ids', () {
    test('messages from one chat share an id, so they update in place', () {
      final first = RichNotification.notificationId('message', 'chat-abc');
      final second = RichNotification.notificationId('message', 'chat-abc');
      expect(first, second);
    });

    test('different chats do not collide', () {
      expect(
        RichNotification.notificationId('message', 'chat-abc'),
        isNot(RichNotification.notificationId('message', 'chat-xyz')),
      );
    });

    test('the id is positive and fits where Android needs it', () {
      for (final chat in ['a', 'chat-abc', 'x' * 64, '9f2b-40aa']) {
        final id = RichNotification.notificationId('message', chat);
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThanOrEqualTo(0x7fffffff));
      }
    });

    test('anything else gets its own id and stands alone', () {
      // A forum reply and an activity update should not overwrite each other.
      expect(
        RichNotification.notificationId('forum', 'post-1'),
        isNot(RichNotification.notificationId('message', 'post-1')),
      );
    });

    test('a message with no chat id still gets a usable id', () {
      final id = RichNotification.notificationId('message', null);
      expect(id, greaterThan(0));
    });
  });

  group('only a chat message uses the messaging layout', () {
    test('MessagingStyle is built for messages', () {
      expect(source, contains('MessagingStyleInformation'));
      expect(source, contains("final bool isMessage = kind == 'message'"));
    });

    test('the face is not also set as a largeIcon', () {
      // That would put a second copy of the photo on the right.
      expect(source, contains('(avatar == null || isMessage)'));
    });

    test('the badge is tinted rather than left grey', () {
      expect(source, contains('color: const Color(0xff1F7DE9)'));
    });

    test('forum and the rest keep their own shapes', () {
      expect(source, contains("kind == 'forum'"));
      expect(source, contains('BigTextStyleInformation'));
      expect(source, contains('DefaultStyleInformation'));
    });
  });
}
