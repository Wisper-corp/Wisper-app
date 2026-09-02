import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/chat/model/forum_post_ref.dart';
import 'package:wisper/app/modules/chat/widgets/forum_post_ref_card.dart';

/// Replying privately to a forum post opened a bare chat, so the recipient got
/// a message with no subject. The post now travels with the message: shown
/// above the composer while you write, drawn on the message once sent, and
/// tappable to open the post itself.

/// The shape the server really sends, taken from a live private reply.
const live = {
  'id': '56e5e4a7-6407-4ffc-82ce-88034a486a3f',
  'groupId': '3f519069-371c-4994-97b8-3f4464e2fe76',
  'text': 'testing video',
  'isTrimmed': false,
  'image': 'https://example.test/wisper/1788193246000-1579.mp4',
  'createdAt': '2026-08-31T16:20:47.775Z',
  'author': {
    'id': 'b4014be4-c625-4ae7-b949-11b77c8020a0',
    'name': 'Chisom Alaoma',
    'image': 'https://example.test/wisper/avatar.jpg',
  },
};

Future<void> pumpCard(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: SizedBox(width: 320, child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('reading what the server sends', () {
    test('a private reply carries the post', () {
      final ref = ForumPostRef.fromJson(live)!;
      expect(ref.id, '56e5e4a7-6407-4ffc-82ce-88034a486a3f');
      expect(ref.groupId, '3f519069-371c-4994-97b8-3f4464e2fe76');
      expect(ref.text, 'testing video');
      expect(ref.authorName, 'Chisom Alaoma');
    });

    test('an ordinary message carries nothing', () {
      for (final nothing in [null, {}, 'nope', 42, {'id': ''}]) {
        expect(ForumPostRef.fromJson(nothing), isNull);
      }
    });

    test('a clip is not mistaken for a picture', () {
      // The post that prompted this has a video on it. Handing an .mp4 to an
      // image loader draws nothing at all.
      final ref = ForumPostRef.fromJson(live)!;
      expect(ref.hasVideo, isTrue);
      expect(ref.thumbnail, isNull);
    });

    test('a real picture is used as the thumbnail', () {
      final ref = ForumPostRef.fromJson({
        ...live,
        'image': 'https://example.test/wisper/photo.jpg',
      })!;
      expect(ref.hasVideo, isFalse);
      expect(ref.thumbnail, 'https://example.test/wisper/photo.jpg');
    });

    test('it survives the trip through the message map', () {
      final there = ForumPostRef.fromJson(live)!;
      final back = ForumPostRef.fromJson(there.toJson())!;
      expect(back.id, there.id);
      expect(back.groupId, there.groupId);
      expect(back.authorName, there.authorName);
      expect(back.attachment, there.attachment);
    });
  });

  group('the card', () {
    testWidgets('names the author and quotes the post', (tester) async {
      await pumpCard(tester, ForumPostRefCard(post: ForumPostRef.fromJson(live)!));
      expect(find.text('Chisom Alaoma'), findsOneWidget);
      expect(find.text('testing video'), findsOneWidget);
    });

    testWidgets('a clip shows a play badge, not a broken image',
        (tester) async {
      await pumpCard(tester, ForumPostRefCard(post: ForumPostRef.fromJson(live)!));
      expect(find.bySemanticsLabel('Video'), findsOneWidget);
    });

    testWidgets('in the composer it can be taken off again', (tester) async {
      var dismissed = false;
      await pumpCard(
        tester,
        ForumPostRefCard(
          post: ForumPostRef.fromJson(live)!,
          onDismiss: () => dismissed = true,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Remove the post from this reply'));
      expect(dismissed, isTrue);
    });

    testWidgets('on a message there is no way to take it off', (tester) async {
      // Once sent, the context is part of the message.
      await pumpCard(tester, ForumPostRefCard(post: ForumPostRef.fromJson(live)!));
      expect(find.bySemanticsLabel('Remove the post from this reply'), findsNothing);
    });

    testWidgets('tapping it opens the post', (tester) async {
      var opened = false;
      await pumpCard(
        tester,
        ForumPostRefCard(
          post: ForumPostRef.fromJson(live)!,
          onTap: () => opened = true,
        ),
      );
      await tester.tap(find.byType(ForumPostRefCard));
      expect(opened, isTrue);
    });

    testWidgets('an empty post still says something', (tester) async {
      final ref = ForumPostRef.fromJson({...live, 'text': ''})!;
      await pumpCard(tester, ForumPostRefCard(post: ref));
      expect(find.text('Forum post'), findsOneWidget);
    });
  });

  group('the wiring', () {
    final section =
        File('lib/app/modules/forum/views/forum_section.dart').readAsStringSync();
    final controller = File(
      'lib/app/modules/chat/controller/message_controller.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/app/modules/chat/views/person/message_screen.dart',
    ).readAsStringSync();
    final bubble = File(
      'lib/app/modules/chat/widgets/message_bubble.dart',
    ).readAsStringSync();

    test('replying privately hands the post to the chat', () {
      expect(section, contains('replyingToPost: ForumPostRef('));
    });

    test('the chat shows it above the composer', () {
      expect(screen, contains('ctrl.pendingForumPost.value = widget.replyingToPost'));
      expect(screen, contains('ForumPostRefCard('));
      expect(screen, contains('onDismiss: () => ctrl.pendingForumPost.value = null'));
    });

    test('sending attaches it', () {
      expect(controller, contains('"forumPostId": attached.id'));
    });

    test('only the first message quotes the post', () {
      // Otherwise every later message in the conversation repeats the card.
      expect(controller, contains('pendingForumPost.value = null'));
    });

    test('the message draws it, and tapping opens the post', () {
      expect(bubble, contains('ForumPostRefCard('));
      expect(bubble, contains('openForumPostById(post.id)'));
    });
  });
}
