import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/chat/widgets/swipe_to_reply.dart';

/// Dragging a message sideways replies to it, the shortcut every chat app has.
Future<int> swipe(
  WidgetTester tester,
  double distance, {
  bool enabled = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  var replies = 0;
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SwipeToReply(
              enabled: enabled,
              onReply: () => replies++,
              child: Container(
                key: const ValueKey('bubble'),
                width: 200,
                height: 60,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.drag(find.byKey(const ValueKey('bubble')), Offset(distance, 0));
  await tester.pumpAndSettle();
  return replies;
}

void main() {
  testWidgets('a full swipe replies', (tester) async {
    expect(await swipe(tester, 70), 1);
  });

  testWidgets('a short swipe does not', (tester) async {
    // Otherwise a brush against the screen while scrolling starts a reply.
    expect(await swipe(tester, 20), 0);
  });

  testWidgets('swiping the wrong way does nothing', (tester) async {
    expect(await swipe(tester, -70), 0);
  });

  testWidgets('the message springs back either way', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SwipeToReply(
                onReply: () {},
                child: Container(
                  key: const ValueKey('bubble'),
                  width: 200,
                  height: 60,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byKey(const ValueKey('bubble')));

    await tester.drag(find.byKey(const ValueKey('bubble')), const Offset(70, 0));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(const ValueKey('bubble'))), before);
  });

  testWidgets('a message with no id yet cannot be replied to', (tester) async {
    // It has not been acknowledged, so there is nothing to quote.
    expect(await swipe(tester, 70, enabled: false), 0);
  });

  testWidgets('the arrow is hidden until the swipe starts', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SwipeToReply(
                onReply: () {},
                child: const SizedBox(width: 200, height: 60),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 0);
  });

  test('the swipe and the menu set up the same reply', () {
    // Two ways in, one behaviour: both call the same helper.
    final screen = File(
      'lib/app/modules/chat/views/person/message_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('onReply: () => _replyTo(msg)'));
    expect(screen, contains('case MessageAction.reply:\n        _replyTo(msg);'));
    expect('void _replyTo('.allMatches(screen).length, 1);
  });
}

extension on String {
  Iterable<Match> allMatches(String input) =>
      RegExp(RegExp.escape(this)).allMatches(input);
}
