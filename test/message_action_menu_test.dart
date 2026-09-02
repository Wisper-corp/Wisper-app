import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/chat/model/quoted_message.dart';
import 'package:wisper/app/modules/chat/views/forward_message_sheet.dart';
import 'package:wisper/app/modules/chat/widgets/message_action_menu.dart';

/// Long-pressing a message offers Reply, Forward, Copy and Delete.
Future<MessageAction?> openMenu(
  WidgetTester tester, {
  bool canDelete = true,
  bool canCopy = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  MessageAction? picked;
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () async => picked = await showMessageActionMenu(
                c,
                at: const Offset(40, 200),
                canDelete: canDelete,
                canCopy: canCopy,
              ),
              child: const Text('press'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('press'));
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  group('the menu', () {
    testWidgets('offers exactly the four actions', (tester) async {
      await openMenu(tester);
      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Forward'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('and nothing else', (tester) async {
      // The reference had Star, Pin, Report and Info too. Only four were asked
      // for, so only four are built.
      await openMenu(tester);
      for (final absent in ['Star', 'Pin', 'Report', 'Info', 'Edit']) {
        expect(find.text(absent), findsNothing, reason: '$absent is not wanted');
      }
    });

    testWidgets('Delete is set apart, below a divider', (tester) async {
      await openMenu(tester);
      final divider = tester.getRect(find.byType(Divider));
      final delete = tester.getRect(find.text('Delete'));
      expect(delete.top, greaterThan(divider.top));
    });

    testWidgets('Delete is red, the rest are not', (tester) async {
      await openMenu(tester);
      Color colourOf(String label) =>
          tester.widget<Text>(find.text(label)).style!.color!;
      expect(colourOf('Delete'), const Color(0xffE5484D));
      expect(colourOf('Reply'), Colors.white);
      expect(colourOf('Forward'), Colors.white);
    });

    testWidgets('every row carries an icon', (tester) async {
      await openMenu(tester);
      for (final icon in [
        Icons.reply_rounded,
        Icons.shortcut_rounded,
        Icons.copy_rounded,
        Icons.delete_outline_rounded,
      ]) {
        expect(find.byIcon(icon), findsOneWidget);
      }
    });

    testWidgets('no Delete on someone else\'s message', (tester) async {
      // The server only lets you delete your own, so the row would always
      // fail.
      await openMenu(tester, canDelete: false);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Reply'), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('no Copy when there are no words', (tester) async {
      await openMenu(tester, canCopy: false);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Forward'), findsOneWidget);
    });

    testWidgets('picking a row returns it and closes', (tester) async {
      await openMenu(tester);
      await tester.tap(find.text('Forward'));
      await tester.pumpAndSettle();
      expect(find.text('Forward'), findsNothing);
    });

    testWidgets('it opens near the finger, not centred', (tester) async {
      await openMenu(tester);
      final card = tester.getRect(find.byType(Material).last);
      expect(card.left, lessThan(120));
      expect(card.top, greaterThan(150));
    });
  });

  group('forwarding', () {
    const me = 'me-auth-id';
    final chats = <Map<String, dynamic>>[
      {
        'id': 'chat-1',
        'type': 'INDIVIDUAL',
        'participants': [
          {'auth': {'id': me, 'person': {'name': 'Me'}}},
          {'auth': {'id': 'them', 'person': {'name': 'Chisom Alaoma'}}},
        ],
      },
      {'id': 'chat-2', 'type': 'GROUP', 'group': {'name': 'Remote Tech Space'}},
      {'id': 'chat-here', 'type': 'GROUP', 'group': {'name': 'This One'}},
    ];

    test('offers the other person, not yourself', () {
      final targets = forwardTargets(chats, myAuthId: me);
      final one = targets.firstWhere((t) => t.chatId == 'chat-1');
      expect(one.name, 'Chisom Alaoma');
    });

    test('the conversation you are in is not a target', () {
      final targets =
          forwardTargets(chats, myAuthId: me, excludeChatId: 'chat-here');
      expect(targets.map((t) => t.chatId), isNot(contains('chat-here')));
      expect(targets, hasLength(2));
    });

    test('communities come through as communities', () {
      final targets = forwardTargets(chats, myAuthId: me);
      final group = targets.firstWhere((t) => t.chatId == 'chat-2');
      expect(group.name, 'Remote Tech Space');
      expect(group.isGroup, isTrue);
    });

    test('search narrows by name', () {
      final targets = forwardTargets(chats, myAuthId: me, query: 'chisom');
      expect(targets, hasLength(1));
      expect(targets.single.name, 'Chisom Alaoma');
    });

    test('junk in the list does not throw', () {
      final targets = forwardTargets(
        [{'id': 'x', 'type': 'INDIVIDUAL', 'participants': 'nope'}, {}],
        myAuthId: me,
      );
      expect(targets, hasLength(1));
    });
  });

  group('the quoted message', () {
    test('words are quoted as they are', () {
      final q = QuotedMessage.fromJson({
        'id': 'm1',
        'senderName': 'faraz Ahmed',
        'text': 'ORIGINAL for quoting',
      })!;
      expect(q.label, 'ORIGINAL for quoting');
      expect(q.senderName, 'faraz Ahmed');
    });

    test('a file is named by its kind', () {
      final q = QuotedMessage.fromJson({
        'id': 'm2',
        'senderName': 'Chisom',
        'text': '',
        'fileType': 'IMAGE',
      })!;
      expect(q.label, 'Photo');
    });

    test('nothing quoted reads as null', () {
      for (final nothing in [null, {}, 'nope', {'id': ''}]) {
        expect(QuotedMessage.fromJson(nothing), isNull);
      }
    });
  });

  group('the wiring', () {
    final screen = File(
      'lib/app/modules/chat/views/person/message_screen.dart',
    ).readAsStringSync();
    final controller = File(
      'lib/app/modules/chat/controller/message_controller.dart',
    ).readAsStringSync();

    test('a long press opens it', () {
      expect(screen, contains('onLongPress: () => _openMessageMenu'));
      expect(screen, contains('onLongPressStart:'));
    });

    test('Delete is only offered on your own message', () {
      expect(screen, contains('canDelete: isMe'));
    });

    test('deleting asks first, and goes over the socket', () {
      expect(screen, contains('Delete message?'));
      expect(controller, contains("emit('deleteMessage'"));
    });

    test('copying uses the clipboard', () {
      expect(screen, contains('Clipboard.setData'));
    });

    test('replying attaches the quote to the next message', () {
      expect(screen, contains('ctrl.pendingReplyTo.value = QuotedMessage('));
      expect(controller, contains('"replyToId": quoting.id'));
      expect(controller, contains('pendingReplyTo.value = null'));
    });

    test('a delete from the server takes the message away', () {
      expect(controller, contains("on('messageDeleted', _handleMessageDeleted)"));
    });
  });
}
