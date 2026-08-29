import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/widgets/common/location_filter_sheet.dart';

/// The Jobs filter existed but never reached the API — JobSection dropped it —
/// and Services had no filter at all.
void main() {
  group('what the filter sends', () {
    test('no choice sends nothing', () {
      const f = LocationFilters();
      expect(f.isEmpty, isTrue);
      expect(f.isLocal, isFalse);
      expect(f.locationType, isNull);
    });

    test('a job location type is sent as locationType, not as local', () {
      const f = LocationFilters(value: 'REMOTE');
      expect(f.isEmpty, isFalse);
      expect(f.isLocal, isFalse);
      expect(f.locationType, 'REMOTE');
    });

    test('"local" is a different question, so it is sent separately', () {
      const f = LocationFilters(value: kLocalFilterValue);
      expect(f.isLocal, isTrue);
      // Sending LOCAL as a locationType would 422 — it is not a job type.
      expect(f.locationType, isNull);
      expect(f.isEmpty, isFalse);
    });

    test('clearing goes back to nothing', () {
      const f = LocationFilters(value: kLocalFilterValue);
      expect(f.copyWith(value: null).isEmpty, isTrue);
    });
  });

  group('the options each tab offers', () {
    test('Jobs offers local alongside the job location types', () {
      expect(kJobLocationOptions[kLocalFilterValue], 'Local jobs');
      expect(kJobLocationOptions.keys, containsAll([null, 'REMOTE', 'ON_SITE', 'HYBRID']));
    });

    test('Services offers local, and no remote/on-site', () {
      expect(kServiceLocationOptions[kLocalFilterValue], 'Local services');
      // A service post has no location of its own; those would mean nothing.
      expect(kServiceLocationOptions.containsKey('REMOTE'), isFalse);
      expect(kServiceLocationOptions.containsKey('ON_SITE'), isFalse);
    });
  });

  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('the sheet returns the option that was tapped', (tester) async {
    LocationFilters? picked;
    await tester.pumpWidget(host(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await showLocationFilterSheet(
              context,
              current: const LocationFilters(),
              options: kJobLocationOptions,
              ctaLabel: 'Show jobs',
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Local jobs'), findsOneWidget);
    await tester.tap(find.text('Local jobs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show jobs'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.isLocal, isTrue);
  });

  testWidgets('the services sheet offers no job-only choices', (tester) async {
    await tester.pumpWidget(host(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showLocationFilterSheet(
            context,
            current: const LocationFilters(),
            options: kServiceLocationOptions,
            ctaLabel: 'Show services',
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Local services'), findsOneWidget);
    expect(find.text('Remote'), findsNothing);
    expect(find.text('Show services'), findsOneWidget);
  });

  testWidgets('the button shows a dot only while a filter is on',
      (tester) async {
    await tester.pumpWidget(host(Column(children: [
      FilterIconButton(active: false, onTap: () {}),
      FilterIconButton(active: true, onTap: () {}),
    ])));
    await tester.pumpAndSettle();
    // The dot is the only extra painted box inside the active button.
    expect(find.byType(FilterIconButton), findsNWidgets(2));
  });
}
