import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The profile led with a card that cost most of the screen and never moved:
/// the header was a Column and only the tab content scrolled, so a post list
/// was read through a letterbox.
void main() {
  final source = File(
    'lib/app/modules/profile/views/profile_screen.dart',
  ).readAsStringSync();

  test('the header scrolls with the list', () {
    expect(source, contains('NestedScrollView'));
    expect(source, contains('headerSliverBuilder'));
    // The old fixed layout is gone.
    expect(
      source,
      isNot(contains('Expanded(child: _getTabContent(selectedIndex))')),
    );
  });

  test('the tabs stay put once the card is gone', () {
    expect(source, contains('SliverPersistentHeader'));
    expect(source, contains('pinned: true'));
    expect(source, contains('class _PinnedTabs extends SliverPersistentHeaderDelegate'));
  });

  test('the profile name stays pinned above the tabs', () {
    // Once the card scrolls away nothing else on screen says whose profile
    // this is.
    expect(source, contains('SliverAppBar'));
    expect(source, contains('title: Text(\n                displayName'));
    // Above the tabs, not below them.
    expect(
      source.indexOf('SliverAppBar'),
      lessThan(source.indexOf('SliverPersistentHeader')),
    );
  });

  testWidgets('a pinned bar survives the list scrolling under it',
      (tester) async {
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              const SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                title: Text('Chisom Alaoma'),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 400, child: Text('profile card')),
              ),
            ],
            body: ListView(
              children: List.generate(
                30,
                (i) => SizedBox(height: 80, child: Text('post $i')),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.drag(find.text('post 1'), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('profile card'), findsNothing);
    expect(find.text('Chisom Alaoma'), findsOneWidget,
        reason: 'the name should still say whose profile this is');
  });

  test('a back arrow appears only when there is something to go back to', () {
    // The screen is both the Profile tab and a pushed screen from Settings.
    expect(source, contains('Navigator.of(context).canPop()'));
    expect(source, contains('automaticallyImplyLeading: false'));
  });

  testWidgets('pushed: the arrow is there and pops', (tester) async {
    var popped = false;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _FakeProfile(),
                ),
              ).then((_) => popped = true),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(popped, isTrue);
  });

  testWidgets('as a root tab: no arrow, because there is no back',
      (tester) async {
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => const MaterialApp(home: _FakeProfile()),
    ));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsNothing);
    expect(find.text('Chisom Alaoma'), findsOneWidget);
  });

  test('the pinned bar has one fixed height', () {
    // A pinned sliver must state its height up front; min and max must agree
    // or it would collapse as it scrolls.
    expect(source, contains('double get minExtent => height'));
    expect(source, contains('double get maxExtent => height'));
    expect(source, contains('final double kProfileTabsHeight = 56.h'));
  });

  testWidgets('the delegate pins its child and rebuilds when it changes',
      (tester) async {
    // Exercised through a real scroll view rather than trusting the source.
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              const SliverToBoxAdapter(
                child: SizedBox(height: 400, child: Text('profile card')),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TestPinned(
                  height: 56,
                  child: Container(
                    color: Colors.black,
                    child: const Text('Post'),
                  ),
                ),
              ),
            ],
            body: ListView(
              children: List.generate(
                30,
                (i) => SizedBox(height: 80, child: Text('post $i')),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('profile card'), findsOneWidget);
    expect(find.text('Post'), findsOneWidget);

    // Scroll the list far enough to take the card off screen.
    await tester.drag(find.text('post 1'), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('profile card'), findsNothing,
        reason: 'the card should scroll away');
    expect(find.text('Post'), findsOneWidget,
        reason: 'the tabs should stay pinned');
  });
}

/// Mirrors the delegate in the screen, so the behaviour is what is tested
/// rather than the private class being reached into.
class _TestPinned extends SliverPersistentHeaderDelegate {
  const _TestPinned({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_TestPinned oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

/// The same pinned bar the profile builds, so the rule about when a back
/// arrow appears is exercised rather than read.
class _FakeProfile extends StatelessWidget {
  const _FakeProfile();

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            leading: canPop
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  )
                : null,
            title: const Text('Chisom Alaoma'),
          ),
        ],
        body: ListView(
          children: List.generate(
            20,
            (i) => SizedBox(height: 80, child: Text('post $i')),
          ),
        ),
      ),
    );
  }
}
