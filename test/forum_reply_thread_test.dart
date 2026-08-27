import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/forum/widget/forum_reply_tile.dart';

/// Parsed from a real response captured off production, so the model is
/// checked against the shape the server actually sends.
List<ForumReplyModel> liveReplies() {
  final raw = jsonDecode(File('test/_live_thread.json').readAsStringSync());
  return (raw['data']['replies'] as List)
      .map((e) => ForumReplyModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<Map<String, dynamic>> pump(
  WidgetTester tester,
  ForumReplyModel reply, {
  double width = 390,
}) async {
  final calls = <String, dynamic>{'reply': 0, 'like': 0, 'more': 0};
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ForumReplyTile(
                reply: reply,
                onReply: (_) => calls['reply'] = calls['reply']! + 1,
                onToggleReaction: (_) => calls['like'] = calls['like']! + 1,
                onShowMore: (_) => calls['more'] = calls['more']! + 1,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return calls;
}

void main() {
  test('the live thread parses into a tree', () {
    final replies = liveReplies();
    expect(replies.length, 1);
    final r = replies.first;
    expect(r.replyCount, 3, reason: 'three children exist');
    expect(r.replies.length, 2, reason: 'only two arrive inline');
    expect(r.hasHiddenReplies, isTrue, reason: 'so one is hidden');
    expect(r.reactionCount, 1);
    expect(r.hasReacted, isTrue);
    expect(r.replies.first.parentId, r.id,
        reason: 'a child points back at its parent');
  });

  testWidgets('a nested reply renders under a vertical rule', (tester) async {
    await pump(tester, liveReplies().first);
    expect(tester.takeException(), isNull);
    // The rule is a left border on the nested block.
    final ruled = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).border?.bottom != null &&
            ((c.decoration as BoxDecoration).border as Border).left.width == 2);
    expect(ruled.length, greaterThanOrEqualTo(1),
        reason: 'nested replies must be drawn against the thread rule');
  });

  testWidgets('children are indented further than their parent',
      (tester) async {
    final r = liveReplies().first;
    await pump(tester, r);
    final parent = tester.getRect(find.text(r.text));
    final child = tester.getRect(find.text(r.replies.first.text));
    expect(child.left, greaterThan(parent.left),
        reason: 'a reply to a reply must sit further in');
  });

  testWidgets('"Show more replies" appears only when children are hidden',
      (tester) async {
    await pump(tester, liveReplies().first);
    expect(find.text('Show more replies'), findsOneWidget);

    final r = liveReplies().first;
    // A reply whose children are all present should not offer it.
    final complete = ForumReplyModel(
      id: r.id,
      text: r.text,
      createdAt: r.createdAt,
      author: r.author,
      replyCount: r.replies.length,
      replies: r.replies,
    );
    await pump(tester, complete);
    expect(find.text('Show more replies'), findsNothing);
  });

  testWidgets('tapping Show more asks for the rest', (tester) async {
    final calls = await pump(tester, liveReplies().first);
    await tester.tap(find.text('Show more replies'));
    await tester.pump();
    expect(calls['more'], 1);
  });

  testWidgets('the reply chip shows the count and fires', (tester) async {
    final calls = await pump(tester, liveReplies().first);
    expect(find.text('3 Replies'), findsOneWidget);
    await tester.tap(find.text('3 Replies'));
    await tester.pump();
    expect(calls['reply'], 1);
    expect(calls['like'], 0, reason: 'replying must not also like');
  });

  testWidgets('a childless reply says Reply, not "0 Replies"', (tester) async {
    final child = liveReplies().first.replies.first;
    await pump(tester, child);
    expect(find.text('Reply'), findsOneWidget);
    expect(find.textContaining('0 Replies'), findsNothing);
  });

  testWidgets('a liked reply shows a filled heart and its count',
      (tester) async {
    final calls = await pump(tester, liveReplies().first);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pump();
    expect(calls['like'], 1);
    expect(calls['reply'], 0, reason: 'liking must not also open replies');
  });

  testWidgets('the thread holds up on a narrow phone', (tester) async {
    await pump(tester, liveReplies().first, width: 320);
    expect(tester.takeException(), isNull,
        reason: 'nesting must not overflow at 320dp');
  });
}
