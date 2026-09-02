import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// "Leave Community" was once shown to anyone who was not an admin — which
/// includes people who are not in the community at all, so visitors were
/// offered the way out of somewhere they had never entered.
///
/// The action has since moved from a button under the member list into the
/// Group Info overflow menu, beside Edit Group. The gating rule has to travel
/// with it: still only for someone who joined, still not for an admin.
///
/// These screens need live GetX controllers and a network stack to mount, so
/// this checks the conditions that decide what is drawn.
void main() {
  final info = File(
    'lib/app/modules/chat/views/group/group_info_screen.dart',
  ).readAsStringSync();
  final chat = File(
    'lib/app/modules/chat/views/group/group_message_screen.dart',
  ).readAsStringSync();

  test('leaving is offered only to someone who joined, and never to an admin',
      () {
    expect(info, contains('bool get _canLeave => _me != null && !_isCurrentUserAdmin;'));
    expect(info, contains('if (_canLeave)'));
  });

  test('two membership rows for one person still read as admin', () {
    // Creating a community adds the owner as ADMIN, and again for anyone
    // named in the member list. Taking whichever came first showed the owner
    // Leave instead of Edit. Seen on a real community during testing.
    expect(info, contains("_myRows.any((m) => m.role == 'ADMIN')"));
    expect(
      info.contains("_me?.role == 'ADMIN'"),
      isFalse,
      reason: 'that reads one row and can pick the wrong one',
    );
  });

  test('leaving without a chat id says so rather than failing quietly', () {
    expect(info, contains('widget.chatId.isEmpty'));
    expect(info, contains('Could not leave'));
  });

  test('the menu opens for a plain member, not only for an admin', () {
    // The menu used to be admin-only. Moving Leave into it without widening
    // that would have taken the way out from exactly the people who use it.
    expect(info, contains('bool get _hasMenu => _isCurrentUserAdmin || _canLeave;'));
    expect(info, contains('isTrailing: _hasMenu'));
    expect(info, contains('trailingOnTap: _hasMenu'));
    expect(
      info.contains('isTrailing: _isCurrentUserAdmin'),
      isFalse,
      reason: 'that is the admin-only gate the menu used to have',
    );
  });

  test('editing stays admin-only', () {
    expect(info, contains('if (_isCurrentUserAdmin)'));
  });

  test('leaving actually leaves', () {
    expect(info, contains('_confirmLeave'));
    expect(info, contains('ctrl.removeRequest('));
    expect(info, contains('chatId: widget.chatId'));
  });

  test('it asks before leaving', () {
    expect(info, contains("'Leave Community?'"));
    expect(info, contains("'Cancel'"));
  });

  test('the old button and its handler are gone from the member list', () {
    expect(chat.contains('if (_hasJoined && !isAdmin)'), isFalse);
    expect(chat.contains('_confirmLeaveGroup'), isFalse);
  });

  test('joining is still offered to someone who has not joined', () {
    expect(chat, contains('if (!_hasJoined) _buildJoinBanner(),'));
  });
}
