import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors MessageController.scrollToBottom's target resolution.
double target(ScrollPosition p) => p.axisDirection == AxisDirection.up
    ? p.minScrollExtent
    : p.maxScrollExtent;

Widget list({required bool reverse, required ScrollController c}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 300,
          child: ListView.builder(
            controller: c,
            reverse: reverse,
            itemCount: 60,
            itemBuilder: (_, i) => SizedBox(height: 40, child: Text('m$i')),
          ),
        ),
      ),
    );

void main() {
  testWidgets('NON-reversed list (group chat): newest is at maxScrollExtent', (t) async {
    final c = ScrollController();
    await t.pumpWidget(list(reverse: false, c: c));
    await t.pump();
    final p = c.position;
    expect(p.axisDirection, AxisDirection.down);
    expect(target(p), p.maxScrollExtent);
    expect(target(p), greaterThan(0), reason: 'old code used 0 = TOP — the bug');
    c.jumpTo(target(p));
    await t.pump();
    expect(c.offset, p.maxScrollExtent);
  });

  testWidgets('REVERSED list (class chat): newest is at offset 0', (t) async {
    final c = ScrollController();
    await t.pumpWidget(list(reverse: true, c: c));
    await t.pump();
    final p = c.position;
    expect(p.axisDirection, AxisDirection.up);
    expect(target(p), p.minScrollExtent);
    expect(target(p), 0, reason: 'reversed lists must keep the old behaviour');
  });

  testWidgets('old hardcoded 0 would land at the WRONG end for a normal list', (t) async {
    final c = ScrollController();
    await t.pumpWidget(list(reverse: false, c: c));
    await t.pump();
    c.jumpTo(0);
    await t.pump();
    expect(find.text('m0'), findsOneWidget);           // oldest visible
    expect(find.text('m59'), findsNothing);            // newest NOT visible
    c.jumpTo(target(c.position));
    await t.pump();
    expect(find.text('m59'), findsOneWidget);          // fix brings newest into view
  });
}
