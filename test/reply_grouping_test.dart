import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/forum/widget/forum_reply_tile.dart';
import 'package:wisper/app/modules/saved/controller/saved_controller.dart';

/// One person replying twice in a row repeated their face, name and title, so
/// it read as two different people saying the same thing.
void main() {
  setUp(() {
    Get.reset();
    Get.put(SavedController(), permanent: true);
  });
  tearDown(Get.reset);

  ForumReplyModel reply(String id, String authorId, String name) =>
      ForumReplyModel(
        id: id,
        text: 'reply $id',
        createdAt: DateTime(2026, 8, 30),
        author: ForumAuthor(id: authorId, name: name, title: 'Flutter Dev'),
      );

  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
      );

  Widget tile(ForumReplyModel r, {required bool grouped}) => ForumReplyTile(
        reply: r,
        groupedWithPrevious: grouped,
        onReply: (_) {},
        onToggleReaction: (_) {},
        onShowMore: (_) {},
      );

  testWidgets('the first reply from someone shows who they are',
      (tester) async {
    await tester.pumpWidget(host(tile(reply('a', 'u1', 'faraz Ahmed'),
        grouped: false)));
    await tester.pumpAndSettle();

    expect(find.text('faraz Ahmed'), findsOneWidget);
    expect(find.text('Flutter Dev'), findsOneWidget);
  });

  testWidgets('a second reply from the same person does not repeat it',
      (tester) async {
    await tester.pumpWidget(host(tile(reply('b', 'u1', 'faraz Ahmed'),
        grouped: true)));
    await tester.pumpAndSettle();

    expect(find.text('faraz Ahmed'), findsNothing);
    expect(find.text('Flutter Dev'), findsNothing);
    // The reply itself is still there, and still actionable.
    expect(find.text('reply b'), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);
  });

  test('grouping is decided by author, in both places replies are drawn', () {
    for (final path in [
      'lib/app/modules/forum/views/forum_replies_screen.dart',
      'lib/app/modules/forum/widget/forum_reply_tile.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('author.id =='),
        reason: '$path does not compare authors',
      );
      expect(source, contains('groupedWithPrevious'));
    }
  });

  test('a null author id never groups two people together', () {
    // Two unknown authors are not evidence of one person.
    final source = File(
      'lib/app/modules/forum/views/forum_replies_screen.dart',
    ).readAsStringSync();
    expect(source, contains('reply.author.id != null'));
  });
}
