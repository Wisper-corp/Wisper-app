import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/chat_presence.dart';

/// Payloads below are the real shapes, taken from the live socket: the server
/// pushes the whole chat list on every connect and disconnect with isOnline
/// set per participant, and a typingStatus event carrying chatId, userId and
/// isTyping. Both were already arriving in the app and neither was read.
const me = '9e1d1bf7-073f-4546-8d2c-99a1f0298a58';
const them = 'b4014be4-c625-4ae7-b949-11b77c8020a0';
const chatId = '63380e91-f1b0-4c2b-aa89-129f00a94343';

Map<String, dynamic> chatList({required bool theirs, bool mine = true}) => {
      'receivedAt': 123,
      'payload': {
        'meta': {'page': 1},
        'chats': [
          {
            'id': chatId,
            'type': 'INDIVIDUAL',
            'participants': [
              {
                'auth': {'id': me, 'person': {'name': 'faraz Ahmed'}},
                'isOnline': mine,
              },
              {
                'auth': {'id': them, 'person': {'name': 'Chisom Alaoma'}},
                'isOnline': theirs,
              },
            ],
          },
        ],
      },
    };

void main() {
  group('online', () {
    test('reads the other participant, not us', () {
      expect(
        peerOnlineFromChatList(chatList(theirs: true), chatId: chatId, myAuthId: me),
        isTrue,
      );
      expect(
        peerOnlineFromChatList(chatList(theirs: false), chatId: chatId, myAuthId: me),
        isFalse,
      );
    });

    test('our own flag never stands in for theirs', () {
      // We are online whenever we are looking at this, so reading the wrong
      // participant would show Online permanently.
      final payload = chatList(theirs: false, mine: true);
      expect(peerOnlineFromChatList(payload, chatId: chatId, myAuthId: me), isFalse);
    });

    test('a list that does not mention this chat says nothing', () {
      // Null, not false — otherwise an unrelated update knocks the header
      // back to Offline.
      expect(
        peerOnlineFromChatList(chatList(theirs: true), chatId: 'other', myAuthId: me),
        isNull,
      );
    });

    test('it accepts the unwrapped and the REST-wrapped shapes too', () {
      final inner = (chatList(theirs: true)['payload'] as Map);
      expect(peerOnlineFromChatList(inner, chatId: chatId, myAuthId: me), isTrue);
      expect(
        peerOnlineFromChatList({'data': inner}, chatId: chatId, myAuthId: me),
        isTrue,
      );
    });

    test('junk does not throw', () {
      for (final bad in [null, 'nope', 42, <String, dynamic>{}, []]) {
        expect(peerOnlineFromChatList(bad, chatId: chatId, myAuthId: me), isNull);
      }
    });
  });

  group('typing', () {
    test('reads a start and a stop', () {
      expect(
        peerTypingFromEvent({'chatId': chatId, 'userId': them, 'isTyping': true},
            chatId: chatId, myAuthId: me),
        isTrue,
      );
      expect(
        peerTypingFromEvent({'chatId': chatId, 'userId': them, 'isTyping': false},
            chatId: chatId, myAuthId: me),
        isFalse,
      );
    });

    test('another conversation is not this one', () {
      expect(
        peerTypingFromEvent({'chatId': 'other', 'userId': them, 'isTyping': true},
            chatId: chatId, myAuthId: me),
        isNull,
      );
    });

    test('our own typing is not news about them', () {
      expect(
        peerTypingFromEvent({'chatId': chatId, 'userId': me, 'isTyping': true},
            chatId: chatId, myAuthId: me),
        isNull,
      );
    });

    test('junk does not throw', () {
      for (final bad in [null, 'nope', <String, dynamic>{}]) {
        expect(peerTypingFromEvent(bad, chatId: chatId, myAuthId: me), isNull);
      }
    });
  });
}
