import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/chat_scroll.dart';

/// Opening a one-to-one chat landed in the middle of the conversation rather
/// than on the newest message.
///
/// The screen built its own ScrollController and attached the list to that,
/// while the pin that runs when the history arrives — several frames of it, so
/// late layout is caught — was aimed at MessageController's controller, which
/// had nothing attached. So the list kept whatever offset the first partial
/// layout produced. The group and class screens were always wired to the
/// controller's; only this screen was not.
void main() {
  final screen = File(
    'lib/app/modules/chat/views/person/message_screen.dart',
  ).readAsStringSync();

  test('the list is wired to the controller that gets pinned', () {
    expect(
      screen.contains('ScrollController _scrollController = ScrollController()'),
      isFalse,
      reason: 'a second controller is the bug',
    );
    expect(screen, contains('ScrollController get _scrollController => ctrl.scrollController'));
  });

  test('it does not dispose a controller it does not own', () {
    expect(screen.contains('_scrollController.dispose()'), isFalse);
  });

  test('the history is pinned, not animated towards', () {
    expect(screen, contains('chatScrollToBottomAfterFrame'));
    expect(screen, contains('isFirstBatch'));
  });

  testWidgets('a list that grows after the first frame still ends at the newest',
      (tester) async {
    // What a chat does: lay out empty, then the history lands and the extent
    // jumps. A single jump taken before that leaves the view mid-list.
    final controller = ScrollController();
    var count = 0;

    Widget build() => MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: count,
              itemBuilder: (context, i) => SizedBox(height: 100, child: Text('m$i')),
            ),
          ),
        );

    await tester.pumpWidget(build());
    chatScrollToBottomAfterFrame(controller);

    // History arrives.
    count = 40;
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    expect(
      controller.offset,
      closeTo(controller.position.maxScrollExtent, 1),
      reason: 'should be sitting on the newest message',
    );
    expect(controller.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('one plain jump would not have been enough', (tester) async {
    final controller = ScrollController();
    var count = 0;

    Widget build() => MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: count,
              itemBuilder: (context, i) => SizedBox(height: 100, child: Text('m$i')),
            ),
          ),
        );

    await tester.pumpWidget(build());
    controller.jumpTo(controller.position.maxScrollExtent); // 0 — nothing yet

    count = 40;
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    // Still parked at the top: this is the reported behaviour.
    expect(controller.offset, 0);
    expect(controller.position.maxScrollExtent, greaterThan(0));
  });
}
