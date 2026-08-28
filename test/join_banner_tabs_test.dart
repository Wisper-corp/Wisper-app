import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The join banner was rendered inside the Services and Jobs branches only, so
/// someone who opened Forum or Members had no way into the community.
///
/// The screen needs live GetX controllers and a network stack to mount, so this
/// checks the structure that decides when the banner is drawn rather than the
/// pixels.
void main() {
  final source = File(
    'lib/app/modules/chat/views/group/group_message_screen.dart',
  ).readAsStringSync();

  // Everything from the tabbed branch onwards.
  final tabbed = source.substring(source.indexOf('if (_canonicalTabIndex == 0)'));

  test('the banner is not tied to any one tab', () {
    // Each tab branch opens with `if (_canonicalTabIndex == N)`. Slice the
    // tabbed section on those boundaries and check no slice owns a banner.
    final bounds = RegExp(r'if \(_canonicalTabIndex == (\d)\)')
        .allMatches(tabbed)
        .toList();
    expect(bounds.length, greaterThanOrEqualTo(4),
        reason: 'tab branches not found — this test needs rewriting');

    for (var i = 0; i < bounds.length; i++) {
      final start = bounds[i].start;
      final end = i + 1 < bounds.length ? bounds[i + 1].start : tabbed.length;
      final branch = tabbed.substring(start, end);
      // The last slice runs to the end of the build method and legitimately
      // contains the shared banner, so only check it does not sit *before*
      // the shared one.
      if (i + 1 == bounds.length) continue;
      expect(
        branch.contains('_buildJoinBanner'),
        isFalse,
        reason: 'tab ${bounds[i].group(1)} carries its own banner, so the '
            'other tabs would go without one',
      );
    }
  });

  test('one banner covers every tab', () {
    expect(
      tabbed,
      contains('if (!_hasJoined) _buildJoinBanner(),'),
      reason: 'nothing offers a way to join from Forum or Members',
    );
    // Exactly one in the tabbed branch — a second would double up.
    expect('_buildJoinBanner()'.allMatches(tabbed).length, 1);
  });

  test('the wording does not promise only chats and services', () {
    expect(source, isNot(contains('Join to participate in chats and post services')));
    // "subscribers", not "members", in user-facing copy.
    expect(source, contains('subscribers'));
  });
}

extension on String {
  Iterable<Match> allMatches(String input) =>
      RegExp(RegExp.escape(this)).allMatches(input);
}
