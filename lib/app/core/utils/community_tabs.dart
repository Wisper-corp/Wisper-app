/// The community screen's tabs, in canonical order. Content branches are
/// written against these indexes.
const List<String> kCommunityTabs = [
  'General Chat',
  'Forum',
  'Services',
  'Jobs',
  'Members',
];

/// The Forum replaces General Chat, so the chat tab is hidden from the bar.
/// Flip this to true to bring it back — nothing else needs editing, because
/// the content branches key off [canonicalTabIndex] rather than the bar's own
/// position.
const bool kShowGeneralChatTab = false;

/// The tabs actually shown.
///
/// With no [groupId] this is the home announcement feed, which is only ever the
/// chat, so the hide does not apply there.
List<String> visibleCommunityTabs({required bool hasGroupId}) {
  if (!hasGroupId) return const ['General Chat'];
  if (kShowGeneralChatTab) return kCommunityTabs;
  return kCommunityTabs.where((t) => t != 'General Chat').toList();
}

/// Maps a position in the visible bar back to its canonical index.
///
/// Hiding a tab shifts every position after it, so without this the Forum tab
/// would render Services, Services would render Jobs, and so on.
int canonicalTabIndex({required bool hasGroupId, required int visibleIndex}) {
  if (!hasGroupId) return 0;
  final visible = visibleCommunityTabs(hasGroupId: hasGroupId);
  if (visibleIndex < 0 || visibleIndex >= visible.length) return 0;
  return kCommunityTabs.indexOf(visible[visibleIndex]);
}
