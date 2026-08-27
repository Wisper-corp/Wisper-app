import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_card.dart';

ForumPostModel livePost() {
  final raw = jsonDecode(File('test/_live_forum.json').readAsStringSync());
  return ForumPostModel.fromJson(
      (raw['data']['posts'] as List).first as Map<String, dynamic>);
}

/// A post long enough to be truncated, so the "Show more" link exists.
ForumPostModel longPost() {
  final live = livePost();
  return ForumPostModel(
    id: live.id,
    text: 'Anyone else hit that moment where Flutter hot reload works '
        'perfectly in debug, then the release build crashes on a null safety '
        'issue you never saw? I spent Tuesday chasing one that only showed up '
        'on a Pixel 6 with the screen off. Am I missing a lint rule that '
        'catches this before CI runs and wastes everyone an afternoon?',
    images: const [],
    createdAt: live.createdAt,
    author: live.author,
    replyCount: 1,
    reactionCount: 0,
    hasReacted: false,
    isMine: false,
    canDelete: false,
    replyAvatars: const [],
  );
}

Future<Map<String, int>> pump(WidgetTester tester, ForumPostModel post) async {
  final counts = {'replies': 0, 'react': 0};
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ForumPostCard(
              post: post,
              onOpenReplies: () => counts['replies'] = counts['replies']! + 1,
              onToggleReaction: () => counts['react'] = counts['react']! + 1,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return counts;
}

void main() {
  testWidgets('tapping the body opens the replies screen', (tester) async {
    final counts = await pump(tester, longPost());
    // Tap the body specifically. Every Text renders as a RichText, so the
    // first one is the author's name - find the one holding the post.
    final body = find.byWidgetPredicate((w) =>
        w is RichText && w.text.toPlainText().contains('hot reload'));
    await tester.tapAt(tester.getCenter(body));
    await tester.pumpAndSettle();
    expect(counts['replies'], 1, reason: 'the body must open replies');
    expect(counts['react'], 0, reason: 'and must not toggle the heart');
  });

  testWidgets('tapping the heart does NOT open replies', (tester) async {
    final counts = await pump(tester, longPost());
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(counts['react'], 1);
    expect(counts['replies'], 0,
        reason: 'a child gesture must win over the card');
  });

  testWidgets('tapping the reply pill opens replies once, not twice',
      (tester) async {
    final counts = await pump(tester, longPost());
    await tester.tap(find.textContaining('reply'));
    await tester.pumpAndSettle();
    expect(counts['replies'], 1,
        reason: 'the pill and the card must not both fire');
  });

  testWidgets('the original post on the replies screen is not tappable',
      (tester) async {
    var opened = 0;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ForumPostCard(
                post: longPost(),
                showActions: false,
                onOpenReplies: () => opened++,
                onToggleReaction: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byWidgetPredicate((w) =>
        w is RichText && w.text.toPlainText().contains('hot reload'))));
    await tester.pumpAndSettle();
    expect(opened, 0,
        reason: 'already on the replies screen — tapping should do nothing');
  });

  testWidgets('"Show more" expands the text instead of opening replies',
      (tester) async {
    final counts = await pump(tester, longPost());
    expect(find.textContaining('Show more'), findsOneWidget,
        reason: 'the post must be long enough to truncate');

    final before = tester.getSize(find.byType(ForumPostCard)).height;

    // The link is painted at the end of the last visible line; scan it.
    final rect = tester.getRect(find.byWidgetPredicate((w) =>
        w is RichText && w.text.toPlainText().contains('Show more')));
    var expanded = false;
    for (var x = rect.right - 8; x > rect.left; x -= 12) {
      await tester.tapAt(Offset(x, rect.bottom - 8));
      await tester.pumpAndSettle();
      if (tester.getSize(find.byType(ForumPostCard)).height != before) {
        expanded = true;
        break;
      }
      // A tap that landed on the body would have opened replies - stop early
      // so the assertion below reports that rather than a scan artefact.
      if (counts['replies']! > 0) break;
    }

    expect(expanded, isTrue, reason: '"Show more" must grow the card');
    expect(counts['replies'], 0,
        reason: 'expanding must not also open the replies screen');
    expect(find.textContaining('Show less'), findsOneWidget);
  });
}
