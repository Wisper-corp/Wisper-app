import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Leave Community was orange, which reads as a warning — for something that
/// is reversible and asks for confirmation anyway. It uses the same blue as
/// Join, which it is the counterpart of.
///
/// It has since moved from a button under the member list into the Group Info
/// overflow menu. The colour travels with it: still blue, still not a
/// destructive red or orange.
void main() {
  final info = File(
    'lib/app/modules/chat/views/group/group_info_screen.dart',
  ).readAsStringSync();
  final chat = File(
    'lib/app/modules/chat/views/group/group_message_screen.dart',
  ).readAsStringSync();

  /// The menu entry, from its guard to the end of its style.
  final leaveAt = info.indexOf("'Leave Community'");
  final entry = leaveAt == -1 ? '' : info.substring(leaveAt - 200, leaveAt + 200);

  test('the leave entry is in the menu', () {
    expect(leaveAt, greaterThan(-1));
    expect(entry, contains('if (_canLeave)'));
  });

  test('it is blue, not orange or red', () {
    expect(entry, contains('Color(0xff1F7DE9)'));
    expect(entry, isNot(contains('Colors.orange')));
    expect(entry, isNot(contains('Colors.red')));
  });

  test('the confirm button is blue too', () {
    // A red Leave in the dialog would undo the point of a blue menu row.
    final confirmAt = info.indexOf("'Leave',");
    expect(confirmAt, greaterThan(-1));
    expect(info.substring(confirmAt, confirmAt + 200), contains('Color(0xff1F7DE9)'));
  });

  test('it is the same blue as the Join button', () {
    final join = chat.indexOf("'Join'");
    expect(join, greaterThan(-1));
    expect(chat.substring(join - 900, join), contains('0xff1F7DE9'));
  });

  test('the role colours are untouched', () {
    // Moderator is orange in the role picker; that is a different thing.
    expect(chat, contains("'label': 'Moderator', 'value': 'MODERATOR', 'color': Colors.orange"));
  });
}
