import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/chat/controller/image_decode_controller.dart';
import 'package:wisper/app/modules/chat/widgets/chatting_field.dart';

/// Attaching a picture broke the composer apart: the preview sits inside the
/// input row, so a centred row floated the plus button halfway up beside the
/// thumbnail and left the text field stranded below it.
void main() {
  late FileDecodeController files;

  setUp(() {
    Get.reset();
    files = Get.put(FileDecodeController());
  });
  tearDown(Get.reset);

  Widget host() => MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ChattingFieldWidget(
              controller: TextEditingController(),
              isSendEnabled: false.obs,
              chatId: 'c1',
              receiverId: 'r1',
            ),
          ),
        ),
      );

  testWidgets('with no attachment the plus sits beside the field',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final plus = tester.getRect(find.byType(CircleAvatar).first);
    final field = tester.getRect(find.byType(TextFormField));
    // Their bottoms line up: one row, one line.
    expect(plus.bottom, closeTo(field.bottom, 1.0));
  });

  testWidgets('with an attachment the plus stays level with the field',
      (tester) async {
    files.imageUrl = 'https://example.test/photo.jpg';
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final plus = tester.getRect(find.byType(CircleAvatar).first);
    final field = tester.getRect(find.byType(TextFormField));

    // The regression: centring put the plus level with the preview instead,
    // which sits well above the field.
    expect(
      plus.bottom,
      closeTo(field.bottom, 2.0),
      reason: 'the plus button drifted away from the field it belongs to',
    );
  });

  testWidgets('the preview sits above the field, not beside it',
      (tester) async {
    files.imageUrl = 'https://example.test/photo.jpg';
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final field = tester.getRect(find.byType(TextFormField));
    final preview =
        tester.getRect(find.byKey(const ValueKey('attachment-preview')));

    expect(preview.bottom, lessThanOrEqualTo(field.top + 1),
        reason: 'the preview should sit above the field, not beside it');
  });
}
