import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/core/widgets/common/pinned_tabs_header.dart';
import 'package:wisper/app/modules/chat/widgets/select_option_widget.dart';

/// The tab bar is one rule above the tabs and one below. Your own profile had
/// a third left behind from the layout this replaced, so a second line sat
/// just under the first with a gap between them.
void main() {
  const screens = <String>[
    'lib/app/modules/profile/views/profile_screen.dart',
    'lib/app/modules/profile/views/person/others_person_screen.dart',
    'lib/app/modules/profile/views/business/others_business_screen.dart',
  ];

  for (final path in screens) {
    test('${path.split('/').last} draws two rules, not three', () {
      final source = File(path).readAsStringSync();
      final header = source.substring(
        source.indexOf('PinnedTabsHeader('),
        source.indexOf('body:', source.indexOf('PinnedTabsHeader(')),
      );
      expect(
        'StraightLiner'.allMatches(header).length,
        2,
        reason: 'one rule above the tabs, one below',
      );
    });
  }

  testWidgets('the bar fits the height the pinned sliver reserves',
      (tester) async {
    // A pinned sliver states its height up front. If the content is taller it
    // is clipped, and the rule underneath is the first thing to go.
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: kProfileTabsHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StraightLiner(height: 0.4, color: Color(0xff454545)),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectOptionWidget(
                        currentIndex: 0,
                        selectedIndex: 0,
                        title: 'Post',
                        lineColor: Colors.white,
                      ),
                      SizedBox(width: 100.w),
                      SelectOptionWidget(
                        currentIndex: 1,
                        selectedIndex: 0,
                        title: 'Resume',
                        lineColor: Colors.white,
                      ),
                    ],
                  ),
                  const StraightLiner(height: 0.4, color: Color(0xff454545)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final bar = tester.getSize(find.byType(Column).first).height;
    expect(bar, lessThanOrEqualTo(kProfileTabsHeight));
  });
}
