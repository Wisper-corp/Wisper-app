import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// In a chat with no messages the encryption notice sat at the bottom, against
/// the input bar, where it read like part of it. The group chat already showed
/// it at the top, so the two screens disagreed.
void main() {
  const oneToOne = 'lib/app/modules/chat/views/person/message_screen.dart';
  const group = 'lib/app/modules/chat/views/group/group_message_screen.dart';

  /// The empty-state branch, from the `messages.isEmpty` test to the end of
  /// the Column it returns.
  String emptyBranch(String path, String marker) {
    final source = File(path).readAsStringSync();
    final start = source.indexOf(marker);
    expect(start, greaterThan(-1), reason: 'empty branch not found in $path');
    return source.substring(start, start + 1400);
  }

  test('a one-to-one chat shows the notice above the empty state', () {
    final branch = emptyBranch(oneToOne, 'if (ctrl.messages.isEmpty)');
    final notice = branch.indexOf('_buildEncryptionNotice()');
    final emptyText = branch.indexOf('No messages yet');

    expect(notice, greaterThan(-1));
    expect(emptyText, greaterThan(-1));
    expect(
      notice,
      lessThan(emptyText),
      reason: 'the notice still sits below the empty state',
    );
  });

  test('a group chat does the same, so the two screens agree', () {
    final branch = emptyBranch(group, 'if (_ctrl.messages.isEmpty)');
    final notice = branch.indexOf('_encryptionNotice()');
    final card = branch.indexOf('EmptyGroupInfoCard');

    expect(notice, greaterThan(-1));
    expect(card, greaterThan(-1));
    expect(notice, lessThan(card));
  });

  test('the empty state no longer carries a stray character', () {
    final source = File(oneToOne).readAsStringSync();
    expect(source, contains('"No messages yet"'));
    expect(source, isNot(contains('No messages yet 3')));
  });
}
