import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/chat/widgets/member_list_title.dart';

/// A community with no messages yet showed its name on one line and the time
/// stranded on the next, with empty space between them. The time belongs
/// beside the name, the way every chat list does it.
/// The tile is sized with ScreenUtil, which scales against the real surface —
/// so the test surface has to be the design size or every .sp doubles.
Future<void> pumpTile(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      // Column(min) so the tile is measured by its content rather than
      // stretched to the height of the screen.
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Column(mainAxisSize: MainAxisSize.min, children: [child]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MemberListTile tile({
  String message = '',
  String time = '5 days ago',
  String unread = '0',
}) =>
    MemberListTile(
      isGroup: true,
      isClass: false,
      isOnline: false,
      imagePath: '',
      name: 'Writers Space STY',
      message: message,
      time: time,
      unreadMessageCount: unread,
    );

void main() {
  testWidgets('the time sits on the name line', (tester) async {
    await pumpTile(tester, tile());

    final name = tester.getRect(find.text('Writers Space STY'));
    final when = tester.getRect(find.text('5 days ago'));

    // Same line: their vertical centres agree, and the time is to the right.
    expect(when.center.dy, closeTo(name.center.dy, 6));
    expect(when.left, greaterThan(name.right));
  });

  testWidgets('the pill still sits between them', (tester) async {
    await pumpTile(tester, tile());

    final pill = tester.getRect(find.text('Community'));
    final when = tester.getRect(find.text('5 days ago'));
    expect(pill.center.dy, closeTo(when.center.dy, 6));
    expect(when.left, greaterThan(pill.right));
  });

  testWidgets('with a message, the message keeps the second line',
      (tester) async {
    await pumpTile(tester, tile(message: 'checking'));

    final name = tester.getRect(find.text('Writers Space STY'));
    final body = tester.getRect(find.text('checking'));
    final when = tester.getRect(find.text('5 days ago'));

    expect(body.top, greaterThan(name.bottom - 1));
    expect(when.center.dy, closeTo(name.center.dy, 6));
  });

  testWidgets('an unread badge rides with the message, not the name',
      (tester) async {
    await pumpTile(tester, tile(message: 'checking', unread: '3'));

    final badge = tester.getRect(find.text('3'));
    final body = tester.getRect(find.text('checking'));
    expect(badge.center.dy, closeTo(body.center.dy, 6));
  });

  testWidgets('no message and nothing unread leaves no empty second line',
      (tester) async {
    // The tile's overall height is set by the avatar, so measure the text
    // column itself — that is where the stray blank line would show up.
    final column = find.descendant(
      of: find.byType(MemberListTile),
      matching: find.byType(Column),
    );

    await pumpTile(tester, tile());
    final bare = tester.getSize(column).height;

    await pumpTile(tester, tile(message: 'checking'));
    final withMessage = tester.getSize(column).height;

    expect(bare, lessThan(withMessage));
  });
}
