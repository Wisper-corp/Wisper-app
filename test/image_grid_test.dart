import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/widgets/common/image_container_widget.dart';

List<String> urls(int n) =>
    List.generate(n, (i) => 'https://example.test/img$i.jpg');

Future<void> pump(WidgetTester tester, List<String> images) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 358,
            child: ImageContainer(
              images: images,
              height: 200,
              width: double.infinity,
              borderRadius: 12,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders one tile per image for 1-4', (tester) async {
    for (final n in [1, 2, 3, 4]) {
      await pump(tester, urls(n));
      expect(find.byType(CachedNetworkImage), findsNWidgets(n),
          reason: '$n images should render $n tiles');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('5+ images show four tiles and a +N badge', (tester) async {
    await pump(tester, urls(6));
    expect(find.byType(CachedNetworkImage), findsNWidgets(4));
    expect(find.text('+2'), findsOneWidget,
        reason: 'the fourth tile must say how many are hidden');
  });

  testWidgets('exactly 4 images show no badge', (tester) async {
    await pump(tester, urls(4));
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('tiles are separated, never butted together', (tester) async {
    await pump(tester, urls(2));
    final boxes = tester
        .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .toList();
    expect(boxes.length, 2);
    final a = tester.getRect(find.byType(CachedNetworkImage).at(0));
    final b = tester.getRect(find.byType(CachedNetworkImage).at(1));
    expect(b.left - a.right, greaterThan(0),
        reason: 'there must be a visible gap between tiles');
  });

  testWidgets('no tile dominates: 4-up tiles are equal size', (tester) async {
    await pump(tester, urls(4));
    final rects = List.generate(
        4, (i) => tester.getRect(find.byType(CachedNetworkImage).at(i)));
    for (final r in rects.skip(1)) {
      expect(r.width, closeTo(rects.first.width, 0.5));
      expect(r.height, closeTo(rects.first.height, 0.5));
    }
  });

  testWidgets('empty or blank urls render nothing', (tester) async {
    await pump(tester, ['', '  '.trim()]);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });
}
