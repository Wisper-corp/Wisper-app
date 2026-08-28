import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/chat/controller/create_chat_controller.dart';
import 'package:wisper/app/modules/chat/utils/open_direct_chat.dart';

/// Tapping a contact used to open their profile. It opens the chat with them
/// now — that list exists to start a conversation.
void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('a missing id does nothing at all', () {
    // No overlay, no controller, no request — the alternative is a loading
    // spinner over a call that was always going to fail.
    for (final id in <String?>[null, '', '   ']) {
      test('id "${id ?? 'null'}" is ignored', () async {
        await openDirectChat(userId: id);
        expect(
          Get.isRegistered<CreateChatController>(),
          isFalse,
          reason: 'it got as far as trying to create a chat',
        );
      });
    }
  });

  test('the contacts list opens a chat, not a profile', () {
    final source = File(
      'lib/app/modules/chat/views/create_group_class_screen.dart',
    ).readAsStringSync();

    expect(source, contains('openDirectChat('));
    expect(
      source,
      isNot(contains('OthersPersonScreen')),
      reason: 'tapping a contact still opens their profile',
    );
    expect(source, isNot(contains('OthersBusinessScreen')));
  });

  test('the sheet is dismissed before the chat is pushed', () {
    final source = File(
      'lib/app/modules/chat/utils/open_direct_chat.dart',
    ).readAsStringSync();
    // Otherwise going back from the chat lands on the sheet again.
    final closeAt = source.indexOf('Get.isBottomSheetOpen');
    final pushAt = source.indexOf('Get.to(');
    expect(closeAt, greaterThan(-1));
    expect(pushAt, greaterThan(closeAt));
  });
}
