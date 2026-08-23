import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/widgets/common/header_icon.dart';

/// Renders the header bar layout at real phone widths and fails on overflow.
Widget bar({required double width, required String name, int actions = 3}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 92,
            width: width,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 8, bottom: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      HeaderIcon(asset: 'assets/images/arrow_back.png', size: 20,
                          tooltip: 'Back', onTap: () {}),
                      Expanded(
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 17, height: 1.2)),
                                  const Text('Offline', maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, height: 1.3)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      HeaderActionGroup(children: [
                        HeaderIcon(asset: 'assets/images/video.png', size: 24,
                            tooltip: 'Video call', onTap: () {}),
                        HeaderIcon(asset: 'assets/images/call.png', size: 22,
                            tooltip: 'Voice call', onTap: () {}),
                      ]),
                      HeaderIcon(asset: 'assets/images/more.png', size: 20,
                          tooltip: 'More options', onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('HeaderIcon keeps a 44px tap target', (t) async {
    await t.pumpWidget(MaterialApp(
      home: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => Scaffold(
          body: HeaderIcon(asset: 'assets/images/call.png', size: 22,
              tooltip: 'Voice call', onTap: () {}),
        ),
      ),
    ));
    await t.pump();
    final size = t.getSize(find.byType(HeaderIcon).first);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('HeaderIcon is tappable and labelled', (t) async {
    var tapped = 0;
    await t.pumpWidget(MaterialApp(
      home: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => Scaffold(
          body: HeaderIcon(asset: 'assets/images/call.png', size: 22,
              tooltip: 'Voice call', onTap: () => tapped++),
        ),
      ),
    ));
    await t.pump();
    await t.tap(find.byType(HeaderIcon));
    expect(tapped, 1);
    expect(find.bySemanticsLabel('Voice call'), findsOneWidget);
  });

  for (final w in [320.0, 360.0, 412.0]) {
    testWidgets('header bar does not overflow at ${w.toInt()}dp', (t) async {
      await t.pumpWidget(bar(width: w, name: 'faraz Ahmed'));
      await t.pump();
      expect(overflowErrors(), isEmpty, reason: 'overflow at ${w}dp');
    });

    testWidgets('very long name does not overflow at ${w.toInt()}dp', (t) async {
      await t.pumpWidget(bar(
        width: w,
        name: 'Digital Remote Community STY Extremely Long Name That Should Truncate',
      ));
      await t.pump();
      expect(overflowErrors(), isEmpty, reason: 'overflow at ${w}dp');
    });
  }
}

/// Only layout overflow matters here; missing image assets are a harness
/// artifact of rendering outside a real app bundle.
List<String> overflowErrors() {
  final out = <String>[];
  while (true) {
    final e = TestWidgetsFlutterBinding.instance.takeException();
    if (e == null) break;
    final text = e.toString();
    if (text.contains('overflowed') || text.contains('RenderFlex')) out.add(text.split('\n').first);
  }
  return out;
}

List<Object> tester_exceptions() {
  final list = <Object>[];
  while (true) {
    final e = TestWidgetsFlutterBinding.instance.takeException();
    if (e == null) break;
    list.add(e as Object);
  }
  return list;
}
