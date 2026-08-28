import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/community_engagement.dart';
import 'package:wisper/app/modules/chat/model/communities_model.dart';

/// Home used to list joined communities newest-first, so the one someone
/// actually uses could sit at the bottom.
void main() {
  // Captured from GET /groups/public?limit=9999 against the live API, so the
  // parsing is exercised against the shape the server really sends.
  final live = (json.decode(
    File('test/fixtures/groups_public_live.json').readAsStringSync(),
  ) as List)
      .map((e) => CommunitiesItemModel.fromJson(e as Map<String, dynamic>))
      .toList();

  CommunitiesItemModel make({
    required String name,
    int activity = 0,
    DateTime? lastAt,
    DateTime? created,
  }) =>
      CommunitiesItemModel(
        id: name,
        name: name,
        description: null,
        image: null,
        createdAt: created,
        chatId: null,
        isJoined: true,
        memberCount: 0,
        members: const [],
        myActivityCount: activity,
        myLastActivityAt: lastAt,
      );

  test('the live payload carries the engagement fields', () {
    expect(live, isNotEmpty);
    // The busiest community in the captured data is the one replied to.
    final busiest =
        live.reduce((a, b) => a.myActivityCount >= b.myActivityCount ? a : b);
    expect(busiest.myActivityCount, greaterThan(0),
        reason: 'server sent no engagement — sorting would be a no-op');
    expect(busiest.myLastActivityAt, isNotNull);
  });

  test('the most engaged community leads', () {
    final ordered = sortByEngagement(live);
    expect(ordered.first.myActivityCount,
        equals(live.map((c) => c.myActivityCount).reduce((a, b) => a > b ? a : b)));
    // Descending, with no gaps out of order.
    for (var i = 1; i < ordered.length; i++) {
      expect(ordered[i - 1].myActivityCount,
          greaterThanOrEqualTo(ordered[i].myActivityCount));
    }
  });

  test('equal activity is broken by who was there most recently', () {
    final older = DateTime(2026, 8, 1);
    final newer = DateTime(2026, 8, 27);
    final ordered = sortByEngagement([
      make(name: 'stale', activity: 3, lastAt: older),
      make(name: 'fresh', activity: 3, lastAt: newer),
    ]);
    expect(ordered.map((c) => c.name), ['fresh', 'stale']);
  });

  test('a community with any activity outranks one with none', () {
    final ordered = sortByEngagement([
      make(name: 'untouched', created: DateTime(2026, 8, 28)),
      make(name: 'used', activity: 1, lastAt: DateTime(2026, 8, 2)),
    ]);
    expect(ordered.first.name, 'used');
  });

  test('communities nobody has touched keep the old newest-first order', () {
    final ordered = sortByEngagement([
      make(name: 'old', created: DateTime(2026, 1, 1)),
      make(name: 'new', created: DateTime(2026, 8, 28)),
      make(name: 'mid', created: DateTime(2026, 5, 5)),
    ]);
    expect(ordered.map((c) => c.name), ['new', 'mid', 'old']);
  });

  test('sorting leaves the caller list alone', () {
    final input = [
      make(name: 'a'),
      make(name: 'b', activity: 9, lastAt: DateTime(2026, 8, 28)),
    ];
    final before = input.map((c) => c.name).toList();
    sortByEngagement(input);
    expect(input.map((c) => c.name).toList(), before);
  });
}
