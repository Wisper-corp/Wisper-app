import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/modules/job/widgets/job_filter_sheet.dart';

Future<void> pumpButton(WidgetTester tester, JobFilters filters,
    {double width = 360}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              const Expanded(child: SizedBox(height: 48)),
              SizedBox(width: 10),
              JobFilterButton(filters: filters, onTap: () {}),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('filter model', () {
    test('empty by default', () {
      const f = JobFilters();
      expect(f.isEmpty, isTrue);
      expect(f.activeCount, 0);
    });

    test('a location makes it active', () {
      const f = JobFilters(locationType: 'REMOTE');
      expect(f.isEmpty, isFalse);
      expect(f.activeCount, 1);
    });

    test('copyWith can clear back to any location', () {
      const f = JobFilters(locationType: 'REMOTE');
      final cleared = f.copyWith(locationType: null);
      expect(cleared.locationType, isNull,
          reason: 'null must mean "clear", not "leave unchanged"');
      expect(cleared.isEmpty, isTrue);
    });

    test('copyWith leaves untouched fields alone', () {
      const f = JobFilters(locationType: 'HYBRID');
      expect(f.copyWith().locationType, 'HYBRID');
    });
  });

  group('filter button', () {
    testWidgets('is compact enough to sit beside the search field',
        (tester) async {
      await pumpButton(tester, const JobFilters());
      final size = tester.getSize(find.byType(JobFilterButton));
      expect(size.width, lessThan(70),
          reason: 'it must not crowd the search field');
      expect(size.height, lessThan(70));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows no dot when nothing is filtered', (tester) async {
      await pumpButton(tester, const JobFilters());
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      // The dot is the only extra circle in the tree when active.
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => (c.decoration as BoxDecoration?)?.shape ==
              BoxShape.circle);
      expect(containers, isEmpty);
    });

    testWidgets('shows a dot once a filter is on', (tester) async {
      await pumpButton(tester, const JobFilters(locationType: 'REMOTE'));
      final dots = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => (c.decoration as BoxDecoration?)?.shape ==
              BoxShape.circle);
      expect(dots.length, 1, reason: 'exactly one active dot');
    });

    testWidgets('still fits at a narrow width', (tester) async {
      await pumpButton(tester, const JobFilters(locationType: 'ON_SITE'),
          width: 300);
      expect(tester.takeException(), isNull);
    });
  });

  group('community avatar shape', () {
    testWidgets('defaults to a circle, unchanged for existing callers',
        (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: Scaffold(body: InitialsAvatar(name: 'Digital Remote')),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a cornerRadius gives a rounded square instead',
        (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: Scaffold(
              body: InitialsAvatar(name: 'Digital Remote', cornerRadius: 12),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircleAvatar), findsNothing,
          reason: 'a community should not render as a circle');
      final box = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration as BoxDecoration?)
          .firstWhere((d) => d?.borderRadius != null);
      expect(box!.borderRadius, BorderRadius.circular(12));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the squircle keeps the same footprint as the circle',
        (tester) async {
      Future<Size> sizeFor(double? corner) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, __) => MaterialApp(
              home: Scaffold(
                body: Center(
                  child: InitialsAvatar(
                    name: 'Digital Remote',
                    radius: 20,
                    cornerRadius: corner,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        return tester.getSize(find.byType(InitialsAvatar));
      }

      final circle = await sizeFor(null);
      final squircle = await sizeFor(12);
      expect(squircle, circle,
          reason: 'the shape changed, the size and position must not');
    });
  });
}
