import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduces the community-chat bug: scrolling immediately after inserting an
/// item reads the pre-layout maxScrollExtent and lands short of the bottom.
class _Harness extends StatefulWidget {
  final ScrollController c;
  const _Harness(this.c);
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final items = List.generate(30, (i) => 'm$i');
  void add(String s) => setState(() => items.add(s));
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: ListView.builder(
              controller: widget.c,
              itemCount: items.length,
              itemBuilder: (_, i) => SizedBox(height: 40, child: Text(items[i])),
            ),
          ),
        ),
      );
}

void main() {
  testWidgets('OLD: scrolling synchronously after insert lands short', (t) async {
    final c = ScrollController();
    final key = GlobalKey<_HarnessState>();
    await t.pumpWidget(_Harness(c));
    await t.pump();
    c.jumpTo(c.position.maxScrollExtent);
    final before = c.position.maxScrollExtent;

    final state = t.state<_HarnessState>(find.byType(_Harness));
    state.add('NEW');
    c.jumpTo(c.position.maxScrollExtent);   // synchronous — pre-rebuild extent
    final landed = c.offset;
    await t.pump();                          // now the row exists

    expect(landed, before, reason: 'scrolled to the stale extent');
    expect(c.position.maxScrollExtent, greaterThan(landed),
        reason: 'the real bottom moved — message stays off-screen');
    expect(find.text('NEW'), findsNothing);  // the reported bug
  });

  testWidgets('NEW: scrolling after the frame reaches the real bottom', (t) async {
    final c = ScrollController();
    await t.pumpWidget(_Harness(c));
    await t.pump();
    c.jumpTo(c.position.maxScrollExtent);

    final state = t.state<_HarnessState>(find.byType(_Harness));
    state.add('NEW');
    await t.pump();                          // let the list rebuild first
    c.jumpTo(c.position.maxScrollExtent);    // then scroll
    await t.pump();

    expect(c.offset, c.position.maxScrollExtent);
    expect(find.text('NEW'), findsOneWidget); // message is visible
  });
}
