import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// The REAL production helpers the app calls — not a reimplementation.
import 'package:wisper/app/core/utils/chat_scroll.dart';

/// Mirrors how the chats render: controller holds newest-first, the group list
/// shows `.reversed` in a NORMAL ListView; the class chat uses reverse: true.
class ChatList extends StatefulWidget {
  final ScrollController controller;
  final bool reverse;
  const ChatList({super.key, required this.controller, this.reverse = false});
  @override
  State<ChatList> createState() => ChatListState();
}

class ChatListState extends State<ChatList> {
  final newestFirst = <String>[for (var i = 29; i >= 0; i--) 'm$i'];
  void receive(String text) => setState(() => newestFirst.insert(0, text));

  @override
  Widget build(BuildContext context) {
    final shown = widget.reverse
        ? newestFirst
        : newestFirst.reversed.toList();
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 300,
          child: ListView.builder(
            controller: widget.controller,
            reverse: widget.reverse,
            itemCount: shown.length,
            itemBuilder: (_, i) => SizedBox(height: 40, child: Text(shown[i])),
          ),
        ),
      ),
    );
  }
}

Future<void> settle(WidgetTester t) async {
  await t.pump();          // frame 1 — list rebuilds, first pin
  await t.pump();          // frame 2 — late layout picked up
  await t.pump();          // frame 3 — final pin
}

void main() {
  testWidgets('GROUP chat: sent message becomes visible', (t) async {
    final c = ScrollController();
    await t.pumpWidget(ChatList(controller: c));
    await t.pump();
    chatScrollToBottomAfterFrame(c);
    await settle(t);

    t.state<ChatListState>(find.byType(ChatList)).receive('MY NEW MESSAGE');
    chatScrollToBottomAfterFrame(c);                  // exactly what the app does
    await settle(t);

    expect(find.text('MY NEW MESSAGE'), findsOneWidget);
    expect(chatIsAtNewest(c), isTrue);
  });

  testWidgets('GROUP chat: still correct after several rapid messages', (t) async {
    final c = ScrollController();
    await t.pumpWidget(ChatList(controller: c));
    await t.pump();
    final s = t.state<ChatListState>(find.byType(ChatList));
    for (var i = 0; i < 5; i++) {
      s.receive('burst $i');
      chatScrollToBottomAfterFrame(c);
      await settle(t);
    }
    expect(find.text('burst 4'), findsOneWidget);
    expect(chatIsAtNewest(c), isTrue);
  });

  testWidgets('GROUP chat: works when the user had scrolled up', (t) async {
    final c = ScrollController();
    await t.pumpWidget(ChatList(controller: c));
    await t.pump();
    c.jumpTo(0);                                      // scrolled to the top
    await t.pump();

    t.state<ChatListState>(find.byType(ChatList)).receive('AFTER SCROLLBACK');
    chatScrollToBottomAfterFrame(c);
    await settle(t);

    expect(find.text('AFTER SCROLLBACK'), findsOneWidget);
    expect(chatIsAtNewest(c), isTrue);
  });

  testWidgets('CLASS chat (reverse:true) is not broken by the fix', (t) async {
    final c = ScrollController();
    await t.pumpWidget(ChatList(controller: c, reverse: true));
    await t.pump();

    t.state<ChatListState>(find.byType(ChatList)).receive('REVERSED NEW');
    chatScrollToBottomAfterFrame(c);
    await settle(t);

    expect(find.text('REVERSED NEW'), findsOneWidget);
    expect(chatIsAtNewest(c), isTrue);
    expect(chatNewestOffset(c.position), c.position.minScrollExtent);
  });

  testWidgets('no crash when the controller has no attached list', (t) async {
    final c = ScrollController();
    chatScrollToBottom(c);
    chatScrollToBottomAfterFrame(c);
    await t.pump();
    expect(chatIsAtNewest(c), isFalse);
  });

  testWidgets('CONTROL: the old synchronous scroll leaves it off-screen', (t) async {
    final c = ScrollController();
    await t.pumpWidget(ChatList(controller: c));
    await t.pump();
    chatScrollToBottom(c, animated: false);
    await t.pump();

    t.state<ChatListState>(find.byType(ChatList)).receive('OLD WAY');
    chatScrollToBottom(c, animated: false);   // pre-rebuild extent — the bug
    await t.pump();

    expect(find.text('OLD WAY'), findsNothing,
        reason: 'proves the test can detect the original failure');
  });
}
