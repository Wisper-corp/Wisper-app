import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/core/widgets/common/image_container_widget.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_card.dart';

/// Parsed from a response captured off the live API, so the model is checked
/// against the shape the server really sends rather than a hand-made fixture.
ForumPostModel livePost() {
  final raw = jsonDecode(File('test/_live_forum.json').readAsStringSync());
  return ForumPostModel.fromJson(
      (raw['data']['posts'] as List).first as Map<String, dynamic>);
}

Future<void> pump(WidgetTester tester, ForumPostModel post) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          // The card lives in a ListView in the app; without a scroll parent a
          // tall image post overflows the test surface.
          body: SingleChildScrollView(
            child: ForumPostCard(
            post: post,
            onOpenReplies: () {},
            onToggleReaction: () {},
              onMore: post.isMine ? () {} : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('parses the live API response', () {
    final post = livePost();
    expect(post.author.name, 'faraz Ahmed');
    expect(post.author.title, 'Flutter Developer',
        reason: 'the title under the name must survive parsing');
    expect(post.replyCount, 1);
    expect(post.reactionCount, 1);
    expect(post.hasReacted, isTrue);
    expect(post.isMine, isTrue);
  });

  testWidgets('card shows name, professional title and counts', (tester) async {
    await pump(tester, livePost());
    expect(find.text('faraz Ahmed'), findsOneWidget);
    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.text('1 reply'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // heart count
    expect(tester.takeException(), isNull);
  });

  testWidgets('a reacted post shows a filled heart', (tester) async {
    final post = livePost();
    expect(post.hasReacted, isTrue);
    await pump(tester, post);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('an unreacted post shows an outline heart', (tester) async {
    final post = livePost()..hasReacted = false;
    await pump(tester, post);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('a post with no replies offers Reply instead of a count',
      (tester) async {
    final live = livePost();
    final post = ForumPostModel(
      id: live.id,
      text: live.text,
      images: const [],
      createdAt: live.createdAt,
      author: live.author,
      replyCount: 0,
      reactionCount: 0,
      hasReacted: false,
      isMine: false,
      canDelete: false,
      replyAvatars: const [],
    );
    await pump(tester, post);
    expect(find.text('Reply'), findsOneWidget);
    expect(find.textContaining('replies'), findsNothing);
  });

  test('author colours are stable per person, not per position', () {
    final a = forumNameColor('9e1d1bf7-073f-4546-8d2c-99a1f0298a58');
    final b = forumNameColor('9e1d1bf7-073f-4546-8d2c-99a1f0298a58');
    expect(a, b, reason: 'the same person must keep the same colour');
    expect(forumNameColor(null), Colors.white);
    expect(forumNameColor(''), Colors.white);
  });

  test('compact age reads like the design', () {
    final now = DateTime.now();
    expect(forumShortAge(now.subtract(const Duration(seconds: 5))), 'now');
    expect(forumShortAge(now.subtract(const Duration(minutes: 12))), '12m');
    expect(forumShortAge(now.subtract(const Duration(hours: 3))), '3h');
    expect(forumShortAge(now.subtract(const Duration(days: 2))), '2d');
    expect(forumShortAge(null), '');
  });

  test('canDelete is read from the server, not inferred', () {
    final post = livePost();
    expect(post.canDelete, isTrue, reason: 'own post');
  });

  testWidgets('a moderator sees the menu on someone else\'s post',
      (tester) async {
    final live = livePost();
    final theirs = ForumPostModel(
      id: live.id,
      text: live.text,
      images: const [],
      createdAt: live.createdAt,
      author: live.author,
      replyCount: 0,
      reactionCount: 0,
      hasReacted: false,
      isMine: false,
      canDelete: true, // moderator
      replyAvatars: const [],
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: ForumPostCard(
              post: theirs,
              onOpenReplies: () {},
              onToggleReaction: () {},
              onMore: theirs.canDelete ? () {} : null,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.more_horiz), findsOneWidget,
        reason: 'moderators need the delete affordance on any post');
  });

  testWidgets('a plain member gets no menu on someone else\'s post',
      (tester) async {
    final live = livePost();
    final theirs = ForumPostModel(
      id: live.id,
      text: live.text,
      images: const [],
      createdAt: live.createdAt,
      author: live.author,
      replyCount: 0,
      reactionCount: 0,
      hasReacted: false,
      isMine: false,
      canDelete: false,
      replyAvatars: const [],
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: ForumPostCard(
              post: theirs,
              onOpenReplies: () {},
              onToggleReaction: () {},
              onMore: theirs.canDelete ? () {} : null,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.more_horiz), findsNothing);
  });

  ForumPostModel withImages(int n) {
    final live = livePost();
    return ForumPostModel(
      id: live.id,
      text: 'Look at these',
      images: List.generate(n, (i) => 'https://example.test/p$i.jpg'),
      createdAt: live.createdAt,
      author: live.author,
      replyCount: 0,
      reactionCount: 0,
      hasReacted: false,
      isMine: false,
      canDelete: false,
      replyAvatars: const [],
    );
  }

  for (final n in [1, 2, 3, 4]) {
    testWidgets('a post with $n image(s) actually renders them', (tester) async {
      await pump(tester, withImages(n));
      // The bug: the whole upload pipeline worked but the card never drew the
      // photos, so an image post looked like a text-only post.
      expect(find.byType(ImageContainer), findsOneWidget,
          reason: 'the card must include the image grid');
      expect(find.byType(CachedNetworkImage), findsNWidgets(n + 1),
          reason: '$n photos plus the author avatar');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a text-only post draws no image grid', (tester) async {
    await pump(tester, livePost());
    expect(find.byType(ImageContainer), findsNothing);
  });

  testWidgets('the caption is still shown above the photos', (tester) async {
    await pump(tester, withImages(2));
    expect(find.text('Look at these'), findsOneWidget);
    final caption = tester.getRect(find.text('Look at these'));
    final grid = tester.getRect(find.byType(ImageContainer));
    expect(caption.bottom, lessThanOrEqualTo(grid.top),
        reason: 'caption reads first, then the photos');
  });
}
