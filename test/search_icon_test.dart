import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';

/// The Jobs tab's search bar had no magnifier while the Services bar beside it
/// did, so the two sat side by side looking like different controls.
void main() {
  testWidgets('a search field renders the icon it is given', (tester) async {
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            hintText: 'Search jobs...',
            prefixIcon: Icons.search_rounded,
            onChanged: (_) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.text('Search jobs...'), findsOneWidget);
  });

  test('the community tabs use the same magnifier as each other', () {
    final source = File(
      'lib/app/modules/chat/views/group/group_message_screen.dart',
    ).readAsStringSync();

    for (final hint in ["'Search jobs...'", "'Search services...'"]) {
      final at = source.indexOf(hint);
      expect(at, greaterThan(-1), reason: 'missing field: $hint');
      // The icon is set within the same field, a few lines below the hint.
      final field = source.substring(at, at + 260);
      expect(
        field,
        contains('prefixIcon: Icons.search_rounded'),
        reason: '$hint has no search icon',
      );
    }
  });
}
