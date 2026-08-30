import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/community_tags.dart';
import 'package:wisper/app/core/widgets/common/searchable_tag_field.dart';

/// Every community tag has always been optional in code, but a numbered list
/// of fields reads as a form you must fill in — and the one that says what the
/// community actually is sat last, under two that only qualify it.
void main() {
  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('an optional field says so beside its label', (tester) async {
    await tester.pumpWidget(host(SearchableTagField(
      label: '2. Trade Type',
      hint: 'Search trade type',
      options: const ['Local B2B'],
      selected: null,
      optional: true,
      onSelect: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('2. Trade Type'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
  });

  testWidgets('a required field does not', (tester) async {
    await tester.pumpWidget(host(SearchableTagField(
      label: '1. Community Category',
      hint: 'Search category',
      options: const ['Food & Beverages'],
      selected: null,
      onSelect: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Optional'), findsNothing);
  });

  group('both screens agree on the tags', () {
    final screens = {
      'create': 'lib/app/modules/chat/views/group/create_group_button_sheet.dart',
      'edit': 'lib/app/modules/chat/views/group/edit_group_screen.dart',
    };

    screens.forEach((name, path) {
      test('$name: category is first, and named for a community', () {
        final source = File(path).readAsStringSync();

        expect(source, contains("1. Community Category"));
        expect(source, contains("2. Trade Type"));
        expect(source, contains("3. Market Type"));
        // The old wording is gone.
        expect(source, isNot(contains('Business Category')));

        // Order on screen, not just in the numbering.
        final category = source.indexOf('1. Community Category');
        final trade = source.indexOf('2. Trade Type');
        final market = source.indexOf('3. Market Type');
        expect(category, lessThan(trade));
        expect(trade, lessThan(market));
      });

      test('$name: trade and market are marked optional, category is not', () {
        final source = File(path).readAsStringSync();
        final category = source.indexOf('1. Community Category');
        final trade = source.indexOf('2. Trade Type');

        // No "optional" between the category label and the next field.
        expect(source.substring(category, trade).contains('optional: true'),
            isFalse);
        expect(source.substring(trade).contains('optional: true'), isTrue);
      });
    });
  });

  test('what is stored still parses, whatever order the fields appear in', () {
    // The description keeps the original key order; the parser reads by key.
    const description =
        'A community\nTrade: Local B2B | Market: Wholesale | Category: Fashion | Suffix: MKT';
    final tags = parseCommunityTags(description);
    expect(tags, containsAll(['Fashion', 'Local B2B', 'Wholesale']));
    // Category leads the pills, matching the new field order.
    expect(tags.first, 'Fashion');
  });

  test('a community with only a category still shows its pill', () {
    final tags = parseCommunityTags('Just us\nCategory: Fashion | Suffix: MKT');
    expect(tags, ['Fashion']);
  });
}
