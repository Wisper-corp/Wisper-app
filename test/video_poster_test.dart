import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/widgets/common/video_poster.dart';

/// A video was drawn as a row saying "Video", and in chat as a black box.
/// Feeds show a video as its own frame with a play button over it.
void main() {
  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('a play button sits over the poster', (tester) async {
    await tester.pumpWidget(host(
      VideoPoster(url: 'https://example.test/clip.mp4', onTap: () {}),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('Play video'), findsOneWidget);
  });

  testWidgets('tapping it opens the video', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(
      VideoPoster(url: 'https://example.test/clip.mp4', onTap: () => taps++),
    ));
    await tester.pump();

    await tester.tap(find.byType(VideoPoster));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('it holds its shape before a frame arrives', (tester) async {
    // The frame is fetched over the network, which never resolves in a test —
    // exactly the case where a tile must not collapse or jump.
    await tester.pumpWidget(host(
      SizedBox(
        width: 300,
        child: VideoPoster(
          url: 'https://example.test/clip.mp4',
          onTap: () {},
          aspectRatio: 16 / 9,
        ),
      ),
    ));
    await tester.pump();

    final rect = tester.getRect(find.byType(VideoPoster));
    expect(rect.width, 300);
    expect(rect.height, closeTo(300 * 9 / 16, 1));
  });

  testWidgets('a broken url still renders rather than throwing',
      (tester) async {
    await tester.pumpWidget(host(
      VideoPoster(url: '', onTap: () {}),
    ));
    await tester.pump();

    expect(find.byType(VideoPoster), findsOneWidget);
    expect(find.bySemanticsLabel('Play video'), findsOneWidget);
  });

  test('both places that show a video use it', () {
    for (final path in [
      'lib/app/modules/forum/widget/forum_attachments_view.dart',
      'lib/app/modules/chat/widgets/message_bubble.dart',
    ]) {
      expect(File(path).readAsStringSync(), contains('VideoPoster'));
    }
  });
}
