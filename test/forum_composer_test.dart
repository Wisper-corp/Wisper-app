import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/forum/widget/forum_composer.dart';

Future<void> pump(WidgetTester tester, {bool allowImages = true}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Spacer(),
              ForumComposer(
                allowImages: allowImages,
                onSend: (String text, List<File> images, List<String>? poll) async => true,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the text box is one line high when empty', (tester) async {
    await pump(tester);
    final field = tester.getSize(find.byType(TextField));
    // The bug: a Center inside a maxHeight box filled the whole 120dp, so the
    // composer sat there as a tall slab instead of a single-line pill.
    expect(field.height, lessThan(56),
        reason: 'empty composer was ${field.height.toStringAsFixed(1)}dp tall');
    expect(field.height, greaterThan(14), reason: 'must still be usable');
  });

  testWidgets('the whole composer stays compact', (tester) async {
    await pump(tester);
    final bar = tester.getSize(find.byType(ForumComposer));
    expect(bar.height, lessThan(90),
        reason: 'composer was ${bar.height.toStringAsFixed(1)}dp tall');
  });

  testWidgets('it grows as the text wraps, then stops', (tester) async {
    await pump(tester);
    final empty = tester.getSize(find.byType(TextField)).height;

    await tester.enterText(
      find.byType(TextField),
      List.filled(60, 'wrapping text').join(' '),
    );
    await tester.pump();
    final full = tester.getSize(find.byType(TextField)).height;

    expect(full, greaterThan(empty), reason: 'should grow with content');
    expect(full, lessThan(200), reason: 'but stay capped');
  });

  testWidgets('send is disabled until there is a caption', (tester) async {
    await pump(tester);
    // Images alone must not enable send - a caption is required.
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });

  testWidgets('replies get no attach button', (tester) async {
    await pump(tester, allowImages: false);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('posts do get an attach button', (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('the poll button is offered on posts, not replies',
      (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    await pump(tester, allowImages: false);
    expect(find.byIcon(Icons.bar_chart_rounded), findsNothing,
        reason: 'a reply cannot carry a poll');
  });

  testWidgets('attaching a poll does not push the caption out of view',
      (tester) async {
    await pump(tester);
    final before = tester.getSize(find.byType(ForumComposer)).height;
    expect(find.byType(TextField), findsOneWidget);
    // The composer must stay compact enough that the caption field - which is
    // the poll's question - is still on screen.
    expect(before, lessThan(120));
  });
}
