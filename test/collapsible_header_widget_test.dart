import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/collapsible_header.dart';

/// Mirrors how group_message_screen composes it: a fixed title, a collapsible
/// row, fixed tabs, then the scrolling feed underneath.
class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool collapsed = false;

  bool _onScroll(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return false;
    if (n.metrics.axis != Axis.vertical) return false;
    final intent = headerCollapseIntent(
      metrics: n.metrics,
      scrollDelta: n.scrollDelta ?? 0,
    );
    if (intent == null || intent == collapsed) return false;
    setState(() => collapsed = intent);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: Column(
            children: [
              const SizedBox(height: 40, child: Text('Community title')),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: collapsed
                    ? const SizedBox(width: double.infinity)
                    : const SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: Text('23.8K Members'),
                      ),
              ),
              const SizedBox(height: 40, child: Text('Forum Services Jobs')),
              Expanded(
                child: ListView.builder(
                  itemCount: 60,
                  itemBuilder: (_, i) => SizedBox(height: 80, child: Text('row $i')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('scroll down collapses, scroll up expands, top restores',
      (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    double memberRowHeight() =>
        tester.getSize(find.byType(AnimatedSize)).height;
    final expanded = memberRowHeight();
    expect(expanded, 44, reason: 'starts fully expanded');
    expect(find.text('23.8K Members'), findsOneWidget);

    // Scroll the feed down.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(memberRowHeight(), 0, reason: 'collapses when scrolling down');
    expect(find.text('23.8K Members'), findsNothing);

    // Tabs and title must not have moved.
    expect(find.text('Community title'), findsOneWidget);
    expect(find.text('Forum Services Jobs'), findsOneWidget);

    // Scroll back up a little — should expand again without returning to top.
    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(memberRowHeight(), 44, reason: 'expands when scrolling back up');
  });

  testWidgets('feed keeps scrolling while the bar collapses', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    expect(find.text('row 0'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // The list actually moved — the header did not eat the gesture.
    expect(find.text('row 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
