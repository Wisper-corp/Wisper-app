import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/community_tabs.dart';

void main() {
  test('General Chat is hidden inside a community', () {
    final visible = visibleCommunityTabs(hasGroupId: true);
    expect(visible, ['Forum', 'Services', 'Jobs', 'Members']);
    expect(visible.contains('General Chat'), isFalse);
  });

  test('the home announcement feed still shows the chat', () {
    // No groupId means the embedded announcement feed, which is only ever the
    // chat — hiding it there would leave an empty screen.
    expect(visibleCommunityTabs(hasGroupId: false), ['General Chat']);
    expect(canonicalTabIndex(hasGroupId: false, visibleIndex: 0), 0);
  });

  test('every visible tab maps to the content it names', () {
    final visible = visibleCommunityTabs(hasGroupId: true);
    for (var i = 0; i < visible.length; i++) {
      final canonical = canonicalTabIndex(hasGroupId: true, visibleIndex: i);
      expect(kCommunityTabs[canonical], visible[i],
          reason: 'tapping "${visible[i]}" must open "${visible[i]}"');
    }
  });

  test('the mapping is exactly the expected shift', () {
    expect(canonicalTabIndex(hasGroupId: true, visibleIndex: 0), 1); // Forum
    expect(canonicalTabIndex(hasGroupId: true, visibleIndex: 1), 2); // Services
    expect(canonicalTabIndex(hasGroupId: true, visibleIndex: 2), 3); // Jobs
    expect(canonicalTabIndex(hasGroupId: true, visibleIndex: 3), 4); // Members
  });

  test('CONTROL: using the raw bar position would open the wrong tab', () {
    final visible = visibleCommunityTabs(hasGroupId: true);
    // Tapping the first tab ("Forum") with no mapping would render index 0,
    // which is General Chat — the exact bug this guards.
    expect(visible[0], 'Forum');
    expect(kCommunityTabs[0], 'General Chat');
    expect(canonicalTabIndex(hasGroupId: true, visibleIndex: 0), isNot(0));
  });

  test('out-of-range positions fall back rather than crash', () {
    expect(canonicalTabIndex(hasGroupId: true, visibleIndex: 99), 0);
    expect(canonicalTabIndex(hasGroupId: true, visibleIndex: -1), 0);
  });

  test('restoring the tab needs only the flag', () {
    // Documents the contract: with the flag on, the bar is the canonical list
    // and the mapping becomes the identity.
    if (kShowGeneralChatTab) {
      expect(visibleCommunityTabs(hasGroupId: true), kCommunityTabs);
      for (var i = 0; i < kCommunityTabs.length; i++) {
        expect(canonicalTabIndex(hasGroupId: true, visibleIndex: i), i);
      }
    } else {
      expect(visibleCommunityTabs(hasGroupId: true).length,
          kCommunityTabs.length - 1);
    }
  });
}
