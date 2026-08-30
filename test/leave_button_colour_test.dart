import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Leave Community was orange, which reads as a warning — for something that
/// is reversible and asks for confirmation anyway. It uses the same blue as
/// Join, which it is the counterpart of.
void main() {
  final source = File(
    'lib/app/modules/chat/views/group/group_message_screen.dart',
  ).readAsStringSync();

  /// The Leave button, from its guard to the end of its style block.
  final leaveAt = source.indexOf('if (_hasJoined && !isAdmin)');
  final leaveButton = leaveAt == -1
      ? ''
      : source.substring(leaveAt, leaveAt + 1100);

  test('the leave button is found at all', () {
    expect(leaveAt, greaterThan(-1));
  });

  test('the leave button is blue, not orange', () {
    expect(leaveButton, isNot(contains('Colors.orange')));
    expect(leaveButton, contains('Color(0xff1F7DE9)'));
  });

  test('border, icon and label all match', () {
    // Three separate colours are set; a half-recoloured button looks broken.
    expect('Color(0xff1F7DE9)'.allMatches(leaveButton).length, 3);
  });

  test('it is the same blue as the Join button beside it', () {
    final join = source.indexOf("'Join'");
    expect(join, greaterThan(-1));
    // Join's container colour sits just above its label.
    expect(source.substring(join - 900, join), contains('0xff1F7DE9'));
  });

  test('the role colours are untouched', () {
    // Moderator is orange in the role picker; that is a different thing.
    expect(source, contains("'label': 'Moderator', 'value': 'MODERATOR', 'color': Colors.orange"));
  });
}

extension on String {
  Iterable<Match> allMatches(String input) =>
      RegExp(RegExp.escape(this)).allMatches(input);
}
