import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_card.dart';

ForumPostModel post({required String text}) {
  final raw = jsonDecode(File('test/_live_forum.json').readAsStringSync());
  final base = ForumPostModel.fromJson(
      (raw['data']['posts'] as List).first as Map<String, dynamic>);
  return ForumPostModel(
    id: base.id,
    text: text,
    images: const [],
    createdAt: base.createdAt,
    author: base.author,
    replyCount: 3,
    reactionCount: 1,
    hasReacted: false,
    isMine: false,
    canDelete: false,
    replyAvatars: const [],
  );
}

/// Long enough to be truncated at four lines.
const long =
    'We had a weird one this week: the API response time dropped from 600ms '
    'to 80ms after we removed a redundant database index. The index looked '
    'useful in the docs but the query planner never touched it. Anyone else '
    'found optimizations that were quietly making things slower instead?';

Future<Map<String, int>> pump(WidgetTester tester, String text,
    {bool showActions = true}) async {
  final counts = {'replies': 0};
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(360, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ForumPostCard(
              post: post(text: text),
              showActions: showActions,
              onOpenReplies: () => counts['replies'] = counts['replies']! + 1,
              onToggleReaction: () {},
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
  testWidgets('tapping the body opens the replies', (tester) async {
    final counts = await pump(tester, 'Short post about deploys.');
    await tester.tap(find.textContaining('Short post'));
    await tester.pump();
    expect(counts['replies'], 1);
  });

  testWidgets('tapping "Show more" expands instead of navigating',
      (tester) async {
    final counts = await pump(tester, long);
    expect(find.textContaining('Show more'), findsOneWidget);

    final height = tester.getSize(find.byType(ForumPostCard)).height;
    // The link sits at the end of the last visible line.
    final rect = tester.getRect(find.byType(RichText).at(2));
    var expanded = false;
    for (var x = rect.right - 8; x > rect.left; x -= 12) {
      await tester.tapAt(Offset(x, rect.bottom - 8));
      await tester.pumpAndSettle();
      if (tester.getSize(find.byType(ForumPostCard)).height != height) {
        expanded = true;
        break;
      }
    }
    expect(expanded, isTrue, reason: '"Show more" must expand the text');
    expect(counts['replies'], 0,
        reason: 'expanding must not also open the replies screen');
  });

  testWidgets('the original post on the replies screen is not tappable',
      (tester) async {
    // showActions:false is the quiet header at the top of the replies screen -
    // tapping it to "open replies" from inside the replies would be a loop.
    final counts = await pump(tester, 'Header post', showActions: false);
    await tester.tap(find.textContaining('Header post'));
    await tester.pump();
    expect(counts['replies'], 0);
  });
}
