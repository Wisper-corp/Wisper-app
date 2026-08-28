import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/saved/controller/saved_controller.dart';
import 'package:wisper/app/modules/saved/widget/save_button.dart';

/// Every card showing the same post has to agree about whether it is saved,
/// which is why the button reads its state from the controller rather than
/// holding its own.
void main() {
  setUp(() {
    Get.reset();
    Get.put(SavedController(), permanent: true);
  });

  tearDown(Get.reset);

  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('an unsaved post shows a hollow bookmark', (tester) async {
    await tester.pumpWidget(host(
      const SaveButton(kind: 'service', itemId: 'p1'),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
  });

  testWidgets('seeding from a listing fills it in', (tester) async {
    Get.find<SavedController>().seed('service', 'p1', true);

    await tester.pumpWidget(host(
      const SaveButton(kind: 'service', itemId: 'p1'),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
  });

  testWidgets('two buttons for the same post stay in step', (tester) async {
    await tester.pumpWidget(host(
      const Column(children: [
        SaveButton(kind: 'forum', itemId: 'same'),
        SaveButton(kind: 'forum', itemId: 'same'),
      ]),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark_border_rounded), findsNWidgets(2));

    Get.find<SavedController>().seed('forum', 'same', true);
    await tester.pumpAndSettle();
    // Both, not just the one that was touched.
    expect(find.byIcon(Icons.bookmark_rounded), findsNWidgets(2));
  });

  testWidgets('the same id under a different kind is a different post',
      (tester) async {
    Get.find<SavedController>().seed('service', 'shared-id', true);

    await tester.pumpWidget(host(
      const Column(children: [
        SaveButton(kind: 'service', itemId: 'shared-id'),
        SaveButton(kind: 'forum', itemId: 'shared-id'),
      ]),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
  });

  test('unseeding clears it again', () {
    final controller = Get.find<SavedController>();
    controller.seed('forum', 'x', true);
    expect(controller.isSaved('forum', 'x'), isTrue);
    controller.seed('forum', 'x', false);
    expect(controller.isSaved('forum', 'x'), isFalse);
  });
}
