import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// "Leave Community" was shown to anyone who was not an admin — which includes
/// people who are not in the community at all, so visitors were offered the way
/// out of somewhere they had never entered.
///
/// The screen needs live GetX controllers and a network stack to mount, so this
/// checks the condition that decides when the button is drawn.
void main() {
  final source = File(
    'lib/app/modules/chat/views/group/group_message_screen.dart',
  ).readAsStringSync();

  test('leaving is offered only to someone who joined', () {
    expect(
      source,
      contains('if (_hasJoined && !isAdmin)'),
      reason: 'the leave button is not gated on membership',
    );
    expect(
      source,
      isNot(contains('''            if (!isAdmin)
              Padding''')),
      reason: 'the ungated form is still there',
    );
  });

  test('admins still cannot leave their own community', () {
    // Dropping !isAdmin would let an admin strand a community with no owner.
    final gate = RegExp(r'if \(_hasJoined && !isAdmin\)');
    expect(gate.hasMatch(source), isTrue);
  });

  test('joining and leaving are never offered at the same time', () {
    // One is gated on _hasJoined, the other on !_hasJoined, so they are
    // mutually exclusive by construction.
    expect(source, contains('if (!_hasJoined) _buildJoinBanner(),'));
    expect(source, contains('if (_hasJoined && !isAdmin)'));
  });
}
