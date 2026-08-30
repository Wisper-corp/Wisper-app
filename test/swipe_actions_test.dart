import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/widgets/common/swipe_actions.dart';

/// Swiping a chat in the inbox reveals Mute and Delete behind it.
void main() {
  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
      );

  Widget row({
    required VoidCallback onMute,
    required VoidCallback onDelete,
    VoidCallback? onOpen,
  }) =>
      SwipeActions(
        actions: [
          SwipeAction(
            icon: Icons.notifications_off_outlined,
            colour: const Color(0xffE5A34D),
            semanticLabel: 'Mute',
            onTap: onMute,
          ),
          SwipeAction(
            icon: Icons.delete_outline_rounded,
            colour: const Color(0xffE5484D),
            semanticLabel: 'Delete',
            onTap: onDelete,
          ),
        ],
        child: GestureDetector(
          onTap: onOpen,
          // Full width, as a list row is: the cover can only hide the buttons
          // if the row it wraps actually spans them.
          child: SizedBox(
            width: double.infinity,
            height: 72,
            child: Align(
              alignment: Alignment.centerLeft,
              child: const Text('Eze Miracle'),
            ),
          ),
        ),
      );

  testWidgets('the row sits closed until it is swiped', (tester) async {
    await tester.pumpWidget(host(row(onMute: () {}, onDelete: () {})));
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(find.text('Eze Miracle'));
    expect(before.dx, 0);
  });

  testWidgets('swiping left moves the row aside', (tester) async {
    await tester.pumpWidget(host(row(onMute: () {}, onDelete: () {})));
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(find.text('Eze Miracle')).dx;
    await tester.drag(find.text('Eze Miracle'), const Offset(-160, 0));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Eze Miracle')).dx, lessThan(before));
  });

  testWidgets('the revealed buttons run their actions', (tester) async {
    var muted = 0;
    var deleted = 0;
    await tester.pumpWidget(
        host(row(onMute: () => muted++, onDelete: () => deleted++)));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Eze Miracle'), const Offset(-160, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
    expect(muted, 0);
  });

  testWidgets('an open row swallows the tap instead of opening the chat',
      (tester) async {
    var opened = 0;
    await tester.pumpWidget(host(
        row(onMute: () {}, onDelete: () {}, onOpen: () => opened++)));
    await tester.pumpAndSettle();

    // Closed: tapping opens the chat.
    await tester.tap(find.text('Eze Miracle'));
    await tester.pumpAndSettle();
    expect(opened, 1);

    // Open: the tap closes the row rather than opening the chat.
    await tester.drag(find.text('Eze Miracle'), const Offset(-160, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eze Miracle'));
    await tester.pumpAndSettle();
    expect(opened, 1, reason: 'an open row should not open the chat');
  });

  testWidgets('it cannot be dragged the wrong way', (tester) async {
    await tester.pumpWidget(host(row(onMute: () {}, onDelete: () {})));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Eze Miracle'), const Offset(200, 0));
    await tester.pumpAndSettle();

    // Still flush left — there is nothing to reveal on that side.
    expect(tester.getTopLeft(find.text('Eze Miracle')).dx, 0);
  });

  testWidgets('the buttons are hidden until the row is swiped',
      (tester) async {
    // The regression that shipped: a list row paints no background, so the
    // buttons behind it showed through every row before anything was swiped.
    await tester.pumpWidget(host(row(onMute: () {}, onDelete: () {})));
    await tester.pumpAndSettle();

    final rowRect = tester.getRect(find.byType(SwipeActions));
    final deleteRect = tester.getRect(find.bySemanticsLabel('Delete'));

    expect(find.bySemanticsLabel('Delete'), findsOneWidget);

    // The cover is the one wrapping the row itself. Found by what it wraps,
    // not by order: an action button is a coloured box too.
    final cover = tester.getRect(
      find.ancestor(
        of: find.text('Eze Miracle'),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(
      cover.overlaps(deleteRect),
      isTrue,
      reason: 'the row does not paint over the buttons, so they show through',
    );
    expect(cover.width, greaterThanOrEqualTo(rowRect.width - 0.5),
        reason: 'the cover must span the whole row');
    // And the buttons stay inside the row rather than spilling past it.
    expect(deleteRect.right, lessThanOrEqualTo(rowRect.right + 0.5));
  });

  testWidgets('with no actions it is just the row', (tester) async {
    await tester.pumpWidget(host(SwipeActions(
      actions: const [],
      child: const Text('plain'),
    )));
    await tester.pumpAndSettle();
    expect(find.text('plain'), findsOneWidget);
  });
}
