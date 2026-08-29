import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/community_tags.dart';
import 'package:wisper/app/core/widgets/common/searchable_choice_field.dart';

/// A curated list can never be complete, and the alternative to typing your
/// own title was picking one that is not true.
void main() {
  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
      );

  Future<List<String>> fakeSearch(String q) async =>
      ['Flutter Developer', 'Backend Developer']
          .where((s) => s.toLowerCase().contains(q.toLowerCase()))
          .toList();

  group('the custom row', () {
    testWidgets('appears when nothing in the list matches', (tester) async {
      String? chosen;
      await tester.pumpWidget(host(SearchableChoiceField(
        search: fakeSearch,
        onSelected: (v) => chosen = v,
      )));

      await tester.enterText(find.byType(TextField), 'Goat Herder');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Use "Goat Herder"'), findsOneWidget);
      await tester.tap(find.text('Use "Goat Herder"'));
      await tester.pumpAndSettle();
      expect(chosen, 'Goat Herder');
    });

    testWidgets('is hidden when the list already has it', (tester) async {
      await tester.pumpWidget(host(SearchableChoiceField(
        search: fakeSearch,
        onSelected: (_) {},
      )));

      await tester.enterText(find.byType(TextField), 'Flutter Developer');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Offering to "add" something that exists would create a duplicate.
      expect(find.text('Use "Flutter Developer"'), findsNothing);
      // Twice: once as the text typed into the field, once as the suggestion.
      expect(find.text('Flutter Developer'), findsNWidgets(2));
    });

    testWidgets('refuses anything past the limit, and says why',
        (tester) async {
      String? chosen;
      final tooLong = 'A' * (kMaxCustomChoiceLength + 5);
      await tester.pumpWidget(host(SearchableChoiceField(
        search: fakeSearch,
        onSelected: (v) => chosen = v,
      )));

      await tester.enterText(find.byType(TextField), tooLong);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.textContaining('Keep it to $kMaxCustomChoiceLength'),
          findsOneWidget);
      expect(find.text('Use "$tooLong"'), findsNothing);
      expect(chosen, isNull);
    });

    testWidgets('exactly at the limit is allowed', (tester) async {
      String? chosen;
      final exact = 'B' * kMaxCustomChoiceLength;
      await tester.pumpWidget(host(SearchableChoiceField(
        search: fakeSearch,
        onSelected: (v) => chosen = v,
      )));

      await tester.enterText(find.byType(TextField), exact);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use "$exact"'));
      await tester.pumpAndSettle();
      expect(chosen, exact);
      expect(chosen!.length, kMaxCustomChoiceLength);
    });

    testWidgets('a failed lookup still lets you enter your own',
        (tester) async {
      String? chosen;
      await tester.pumpWidget(host(SearchableChoiceField(
        search: (_) async => throw Exception('offline'),
        onSelected: (v) => chosen = v,
      )));

      await tester.enterText(find.byType(TextField), 'Cobbler');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use "Cobbler"'));
      await tester.pumpAndSettle();
      expect(chosen, 'Cobbler');
    });
  });

  group('a custom community category cannot corrupt the tag line', () {
    // Tags live in the description as
    // "Trade: X | Market: Y | Category: Z | Suffix: S".
    test('pipes and colons are stripped', () {
      expect(sanitizeTagValue('Food | Drink'), 'Food Drink');
      expect(sanitizeTagValue('Retail: Fashion'), 'Retail Fashion');
      expect(sanitizeTagValue('A|B:C'), 'A B C');
    });

    test('newlines cannot end the line early', () {
      expect(sanitizeTagValue('Food\nSuffix: MKT'), 'Food Suffix MKT');
    });

    test('it is capped, and the cap does not leave trailing space', () {
      final long = '${'x' * 30} yyyyy';
      final out = sanitizeTagValue(long);
      expect(out.length, lessThanOrEqualTo(32));
      expect(out, out.trim());
    });

    test('an ordinary value passes through untouched', () {
      expect(sanitizeTagValue('Fashion & Clothing'), 'Fashion & Clothing');
    });

    test('a sanitised value still parses back as one tag', () {
      final value = sanitizeTagValue('Food | Drink: Local');
      final description = 'My community\nCategory: $value | Suffix: MKT';
      final tags = parseCommunityTags(description);
      expect(tags, contains(value));
      expect(tags.length, 1);
    });
  });
}
