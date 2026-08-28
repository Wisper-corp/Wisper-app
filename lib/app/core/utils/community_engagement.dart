import 'package:wisper/app/modules/chat/model/communities_model.dart';

/// Orders the communities on Home so the one the person actually uses is at
/// the top.
///
/// The server reports, per community, how much the caller has done in it over
/// the last 30 days and when they last did it. Busiest wins; a tie is broken by
/// whoever was there most recently, and a community with no activity at all
/// falls back to newest-first — which is the order Home used to have.
///
/// Returns a new list; the caller's list is left alone.
List<CommunitiesItemModel> sortByEngagement(
  List<CommunitiesItemModel> communities,
) {
  final sorted = List<CommunitiesItemModel>.from(communities);
  sorted.sort((a, b) {
    final byCount = b.myActivityCount.compareTo(a.myActivityCount);
    if (byCount != 0) return byCount;

    final aAt = a.myLastActivityAt;
    final bAt = b.myLastActivityAt;
    if (aAt != null && bAt != null && aAt != bAt) return bAt.compareTo(aAt);
    if (aAt != null && bAt == null) return -1;
    if (aAt == null && bAt != null) return 1;

    // Nothing to tell them apart by engagement, so keep the old ordering.
    final aMade = a.createdAt;
    final bMade = b.createdAt;
    if (aMade != null && bMade != null) return bMade.compareTo(aMade);
    return 0;
  });
  return sorted;
}
