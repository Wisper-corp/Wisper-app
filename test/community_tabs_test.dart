import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const tabs = ['General Chat', 'Forum', 'Services', 'Jobs', 'Members'];

/// The old row: equal shares. This is what clipped "Members" to "Mem".
Widget oldRow() => Row(
      children: List.generate(
        tabs.length,
        (i) => Expanded(
          child: Text(tabs[i],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: const TextStyle(fontSize: 13)),
        ),
      ),
    );

/// The new row: labels size to their text, the row scrolls.
Widget newRow() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs
            .map((t) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(t, style: const TextStyle(fontSize: 13)),
                ))
            .toList(),
      ),
    );

Future<void> pump(WidgetTester tester, Widget row, double width) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(body: SizedBox(width: width, child: row)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('all five labels render in full at 360dp', (tester) async {
    await pump(tester, newRow(), 360);
    for (final t in tabs) {
      expect(find.text(t), findsOneWidget, reason: '$t must be present');
    }
    // Every label gets the width its text actually needs.
    for (final t in tabs) {
      final size = tester.getSize(find.text(t));
      expect(size.width, greaterThan(0));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the row scrolls rather than clipping', (tester) async {
    await pump(tester, newRow(), 360);
    final before = tester.getTopLeft(find.text('Members'));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(-120, 0));
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.text('Members'));
    expect(after.dx, lessThan(before.dx),
        reason: 'dragging must bring the last tab into view');
  });

  testWidgets('CONTROL: the old equal-share row squeezes the labels',
      (tester) async {
    await pump(tester, oldRow(), 360);
    final members = tester.getSize(find.text('Members'));
    // 5 equal shares of 360 is 72dp each - not enough for "General Chat",
    // which is why the mockups showed "Mem".
    expect(members.width, lessThanOrEqualTo(72),
        reason: 'the old row caps each tab at a fifth of the width');
  });
}
