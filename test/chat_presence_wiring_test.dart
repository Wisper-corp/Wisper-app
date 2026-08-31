import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The presence feed was arriving and nothing consumed it: the header took a
/// bool passed in when the screen opened, three of the four ways into a chat
/// passed nothing at all, the typing event was printed rather than shown, and
/// the app never told the server we were typing either.
void main() {
  final controller = File(
    'lib/app/modules/chat/controller/message_controller.dart',
  ).readAsStringSync();
  final screen = File(
    'lib/app/modules/chat/views/person/message_screen.dart',
  ).readAsStringSync();
  final header = File(
    'lib/app/modules/chat/widgets/chatting_header.dart',
  ).readAsStringSync();

  test('the chat list is read for presence, not just logged', () {
    expect(controller, contains('peerOnlineFromChatList'));
    expect(controller, contains('chatListPayload'));
  });

  test('the typing event is read rather than printed', () {
    expect(controller, contains('peerTypingFromEvent'));
    final handler = controller.substring(
      controller.indexOf('void _handleTypingStatus'),
      controller.indexOf('void notifyTyping'),
    );
    expect(handler.contains("print('typingStatus called')"), isFalse);
  });

  test('the app tells the server when we type, and when we stop', () {
    expect(controller, contains("emit('startTyping'"));
    expect(controller, contains("emit('stopTyping'"));
    expect(screen, contains('ctrl.notifyTyping()'));
    expect(screen, contains('ctrl.stopTypingNow()'));
  });

  test('a lost stop event cannot leave them typing for good', () {
    expect(controller, contains('_peerTypingTimeout'));
  });

  test('the header follows the live values, not the opening snapshot', () {
    expect(screen, contains('status: ctrl.peerOnline.value'));
    expect(screen, contains('isTyping: ctrl.peerTyping.value'));
    expect(
      screen.contains('status: widget.isOnline'),
      isFalse,
      reason: 'that is the snapshot that never updated',
    );
  });

  test('typing takes the place of Online in the header', () {
    expect(header, contains("'typing...'"));
    expect(header, contains('widget.isTyping'));
  });

  test('leaving the screen stops our typing', () {
    final dispose = screen.substring(screen.indexOf('void dispose()'));
    expect(dispose, contains('stopTypingNow'));
  });
}
