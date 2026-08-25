import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/community_tabs.dart';
import 'package:wisper/app/core/widgets/common/community_tab_bar.dart';

/// Measured at real phone widths with the view sized to match, so ScreenUtil
/// scales the way it does on a device. Testing at the default 800px surface
/// silently inflates every `.w` and hides overflow.
Future<List<Rect>> pumpAt(WidgetTester tester, double width,
    {List<String>? tabs}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.reset);

  final list = tabs ?? visibleCommunityTabs(hasGroupId: true);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: CommunityTabBar(
            tabs: list,
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return [for (final t in list) tester.getRect(find.text(t))];
}

void main() {
  for (final w in [360.0, 390.0, 412.0, 430.0]) {
    testWidgets('all four tabs are on screen at ${w.toInt()}dp', (tester) async {
      final rects = await pumpAt(tester, w);
      expect(tester.takeException(), isNull);
      expect(rects.first.left, greaterThanOrEqualTo(0));
      expect(rects.last.right, lessThanOrEqualTo(w),
          reason: 'no tab may run off the right edge at ${w.toInt()}dp');
    });

    testWidgets('gaps are generous at ${w.toInt()}dp', (tester) async {
      final rects = await pumpAt(tester, w);
      for (var i = 1; i < rects.length; i++) {
        final gap = rects[i].left - rects[i - 1].right;
        expect(gap, greaterThan(10),
            reason: 'tabs must not be bunched together at ${w.toInt()}dp');
      }
    });
  }

  testWidgets('no label is squeezed narrower than its text', (tester) async {
    // "Services" is the widest at 104dp, more than an equal quarter share of
    // 390dp (97dp) - equal shares would truncate it.
    final rects = await pumpAt(tester, 390);
    final services = rects[visibleCommunityTabs(hasGroupId: true).indexOf('Services')];
    expect(services.width, greaterThan(95),
        reason: '"Services" must render at its full width');
  });

  testWidgets('falls back to scrolling when labels genuinely cannot fit',
      (tester) async {
    // Five tabs including "General Chat" (156dp) cannot fit 360dp.
    await pumpAt(tester, 360, tabs: kCommunityTabs);
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget,
        reason: 'it must scroll rather than clip');
    for (final t in kCommunityTabs) {
      expect(find.text(t), findsOneWidget);
    }
  });
}
