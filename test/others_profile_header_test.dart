import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Your own profile collapses its card and pins the tabs. Viewing someone
/// else's kept a fixed card, so their posts were read through a letterbox.
void main() {
  const person =
      'lib/app/modules/profile/views/person/others_person_screen.dart';
  const business =
      'lib/app/modules/profile/views/business/others_business_screen.dart';
  const mine = 'lib/app/modules/profile/views/profile_screen.dart';

  String read(String p) => File(p).readAsStringSync();

  group('every profile scrolls the same way', () {
    for (final path in [person, business, mine]) {
      final name = path.split('/').last;

      test('$name: the card scrolls with the list', () {
        final source = read(path);
        expect(source, contains('NestedScrollView'));
        expect(source, contains('headerSliverBuilder'));
      });

      test('$name: the tabs pin', () {
        final source = read(path);
        expect(source, contains('SliverPersistentHeader'));
        expect(source, contains('PinnedTabsHeader'));
        expect(source, contains('pinned: true'));
      });

      test('$name: the old fixed layout is gone', () {
        final source = read(path);
        // Expanded tab content only works inside a Column that never scrolls.
        expect(
          source,
          isNot(contains('Expanded(\n                child: selectedIndex')),
        );
        expect(
          source,
          isNot(contains('Expanded(\n              child: selectedIndex')),
        );
      });
    }
  });

  group("someone else's profile keeps its identity on screen", () {
    for (final path in [person, business]) {
      final name = path.split('/').last;

      test('$name: back and the name stay pinned', () {
        final source = read(path);
        expect(source, contains('SliverAppBar'));
        expect(source, contains("tooltip: 'Back'"));
        expect(source, contains('Navigator.of(context).pop()'));
      });
    }
  });

  test('one delegate, shared, so the three cannot drift apart', () {
    final shared =
        read('lib/app/core/widgets/common/pinned_tabs_header.dart');
    expect(shared, contains('class PinnedTabsHeader'));
    expect(shared, contains('double get minExtent => height'));
    expect(shared, contains('double get maxExtent => height'));

    // No screen keeps a private copy any more.
    for (final path in [person, business, mine]) {
      expect(read(path), isNot(contains('class _PinnedTabs')));
    }
  });
}
