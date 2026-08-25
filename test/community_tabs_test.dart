import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/community_tabs.dart';
import 'package:wisper/app/core/widgets/common/community_tab_bar.dart';

/// Renders the REAL CommunityTabBar. An earlier version of this file tested a
/// hand-written replica that left out the underline, so it passed while the
/// shipped strip rendered blank. Always mount the real widget.
Future<int?> pumpBar(
  WidgetTester tester, {
  double width = 360,
  List<String>? tabs,
  int selected = 0,
}) async {
  int? tapped;
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: CommunityTabBar(
              tabs: tabs ?? visibleCommunityTabs(hasGroupId: true),
              selectedIndex: selected,
              onSelected: (i) => tapped = i,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return tapped;
}

void main() {
  testWidgets('the strip actually renders — no blank bar', (tester) async {
    await pumpBar(tester);
    // The bug: an unbounded-width underline threw during layout and the whole
    // strip disappeared, leaving an empty nav bar.
    expect(tester.takeException(), isNull,
        reason: 'the tab strip must lay out inside a scrolling row');
    for (final t in visibleCommunityTabs(hasGroupId: true)) {
      expect(find.text(t), findsOneWidget, reason: '$t must be visible');
    }
  });

  testWidgets('every label has real width and height', (tester) async {
    await pumpBar(tester);
    for (final t in visibleCommunityTabs(hasGroupId: true)) {
      final size = tester.getSize(find.text(t));
      expect(size.width, greaterThan(0), reason: '$t collapsed to zero width');
      expect(size.height, greaterThan(0));
      expect(size.width.isFinite, isTrue, reason: '$t got an infinite width');
    }
  });

  testWidgets('the underline is finite and matches its label', (tester) async {
    await pumpBar(tester, selected: 0);
    final barSize = tester.getSize(find.byType(CommunityTabBar));
    expect(barSize.width.isFinite, isTrue);
    expect(barSize.height, greaterThan(0));
    expect(barSize.height, lessThan(120), reason: 'strip should stay compact');
  });

  testWidgets('tapping a tab reports its position', (tester) async {
    int? got;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            // Wide enough that every tab is on screen, so the tap cannot
            // miss for reasons unrelated to what is being tested.
            body: SizedBox(
              width: 600,
              child: CommunityTabBar(
                tabs: visibleCommunityTabs(hasGroupId: true),
                selectedIndex: 0,
                onSelected: (i) => got = i,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Jobs'));
    await tester.pump();
    expect(got, 2, reason: 'Jobs sits third in the visible strip');
  });

  testWidgets('scrolls instead of clipping at 320dp', (tester) async {
    await pumpBar(tester, width: 320);
    expect(tester.takeException(), isNull);
    final before = tester.getTopLeft(find.text('Members'));
    await tester.drag(find.byType(CommunityTabBar), const Offset(-150, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Members')).dx, lessThan(before.dx));
  });

  testWidgets('survives the five-tab case if General Chat is restored',
      (tester) async {
    await pumpBar(tester, tabs: kCommunityTabs, selected: 1);
    expect(tester.takeException(), isNull);
    for (final t in kCommunityTabs) {
      expect(find.text(t), findsOneWidget);
    }
  });

  testWidgets('single-tab case (home announcement feed) renders', (tester) async {
    await pumpBar(tester, tabs: visibleCommunityTabs(hasGroupId: false));
    expect(tester.takeException(), isNull);
    expect(find.text('General Chat'), findsOneWidget);
  });
}
