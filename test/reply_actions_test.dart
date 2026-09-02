import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';

/// A reply had no overflow menu and no way to be kept — the post above it had
/// both. It also had no notion of who may delete it.
void main() {
  group('what a reply knows about itself', () {
    ForumReplyModel parse(Map<String, dynamic> json) =>
        ForumReplyModel.fromJson(json);

    test('canDelete and isSaved are read from the server', () {
      final r = parse({
        'id': 'r1',
        'text': 'hello',
        'author': {'id': 'a1', 'name': 'Chisom'},
        'isMine': false,
        'canDelete': true,
        'isSaved': true,
      });
      expect(r.canDelete, isTrue);
      expect(r.isSaved, isTrue);
      // A moderator may delete a reply that is not theirs.
      expect(r.isMine, isFalse);
    });

    test('an older server without them still lets you delete your own', () {
      final mine = parse({
        'id': 'r2',
        'text': 'hi',
        'author': {'id': 'a1', 'name': 'Me'},
        'isMine': true,
      });
      expect(mine.canDelete, isTrue);

      final theirs = parse({
        'id': 'r3',
        'text': 'hi',
        'author': {'id': 'a2', 'name': 'Them'},
        'isMine': false,
      });
      expect(theirs.canDelete, isFalse);
      expect(theirs.isSaved, isFalse);
    });

    test('a nested reply is parsed with its own permissions', () {
      final r = parse({
        'id': 'p',
        'text': 'parent',
        'author': {'id': 'a1', 'name': 'A'},
        'canDelete': false,
        'replies': [
          {
            'id': 'c',
            'text': 'child',
            'author': {'id': 'a2', 'name': 'B'},
            'canDelete': true,
            'isSaved': true,
          }
        ],
      });
      expect(r.canDelete, isFalse);
      expect(r.replies.single.canDelete, isTrue);
      expect(r.replies.single.isSaved, isTrue);
    });
  });

  group('the reply menu', () {
    final menu = File(
      'lib/app/modules/forum/widget/forum_post_menu.dart',
    ).readAsStringSync();

    test('offers replying privately and deleting', () {
      expect(menu, contains('enum ForumReplyAction'));
      expect(menu, contains('ForumReplyAction.replyPrivately'));
      expect(menu, contains('ForumReplyAction.delete'));
    });

    test('does not offer following — that belongs to the post', () {
      final start = menu.indexOf('showForumReplyMenu');
      final body = menu.substring(start, menu.indexOf('class _Item'));
      expect(body.contains('toggleFollow'), isFalse);
      expect(body.contains('Notify me of replies'), isFalse);
    });

    test('deleting warns that the thread goes too', () {
      expect(menu, contains('Removes it, and anything replying to it'));
    });
  });

  group('the replies screen wires both controls', () {
    final screen = File(
      'lib/app/modules/forum/views/forum_replies_screen.dart',
    ).readAsStringSync();

    test('the tile is given a menu handler', () {
      expect(screen, contains('onMore: _openReplyMenu'));
    });

    test('deleting asks first', () {
      expect(screen, contains('Delete reply?'));
      expect(screen, contains('_controller.deleteReply(reply)'));
    });

    test('the bookmark state is seeded, nested replies included', () {
      expect(screen, contains("_savedController.seed('reply'"));
      expect(screen, contains('for (final child in reply.replies)'));
    });
  });

  test('saving is in the menu, not a bookmark on the row', () {
    // It moved: the row keeps only Reply and the heart, and everything else
    // you can do to a reply lives behind the same overflow button.
    final tile = File(
      'lib/app/modules/forum/widget/forum_reply_tile.dart',
    ).readAsStringSync();
    expect(tile.contains('SaveButton'), isFalse);

    final menu = File(
      'lib/app/modules/forum/widget/forum_post_menu.dart',
    ).readAsStringSync();
    expect(menu, contains('ForumReplyAction.toggleSave'));
    expect(menu, contains("'Save reply'"));
    expect(menu, contains("'Remove from saved'"));

    final repliesScreen = File(
      'lib/app/modules/forum/views/forum_replies_screen.dart',
    ).readAsStringSync();
    expect(repliesScreen, contains("_savedController.toggle('reply', reply.id)"));
    expect(repliesScreen, contains("isSaved: _savedController.isSaved('reply'"));
  });
}
