import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/chat/model/communities_model.dart';

const int minExploreMembers = 30;

CommunitiesItemModel c({
  required String name,
  required int members,
  bool joined = false,
  bool featured = false,
}) =>
    CommunitiesItemModel(
      id: name,
      name: name,
      description: null,
      image: null,
      createdAt: null,
      chatId: null,
      isJoined: joined,
      memberCount: members,
      members: const [],
      isFeatured: featured,
    );

/// Mirrors home_screen's Explore predicate exactly.
List<CommunitiesItemModel> explore(List<CommunitiesItemModel> all) => all
    .where((x) => !(x.isJoined ?? false))
    .where((x) => x.isFeatured || (x.memberCount ?? 0) >= minExploreMembers)
    .toList();

void main() {
  test('a featured community shows even with 2 members', () {
    final out = explore([c(name: 'Digital Remote', members: 2, featured: true)]);
    expect(out.map((e) => e.name), ['Digital Remote']);
  });

  test('an unfeatured small community is still excluded', () {
    expect(explore([c(name: 'Tiny', members: 4)]), isEmpty);
  });

  test('the 30-member auto rule still works', () {
    final out = explore([
      c(name: 'Big', members: 30),
      c(name: 'Just under', members: 29),
    ]);
    expect(out.map((e) => e.name), ['Big'],
        reason: '30 qualifies, 29 does not');
  });

  test('a joined community never appears, featured or not', () {
    final out = explore([
      c(name: 'Joined featured', members: 2, joined: true, featured: true),
      c(name: 'Joined big', members: 500, joined: true),
    ]);
    expect(out, isEmpty, reason: 'Explore is communities you could join');
  });

  test('featured and auto rules combine without duplicates', () {
    final out = explore([
      c(name: 'Featured small', members: 1, featured: true),
      c(name: 'Auto big', members: 120),
      c(name: 'Featured big', members: 200, featured: true),
      c(name: 'Excluded', members: 5),
    ]);
    expect(out.map((e) => e.name),
        ['Featured small', 'Auto big', 'Featured big']);
    expect(out.length, out.map((e) => e.id).toSet().length,
        reason: 'no community listed twice');
  });

  test('missing isFeatured from an older API defaults to false', () {
    final parsed = CommunitiesItemModel.fromJson({
      'id': 'x',
      'name': 'Old API row',
      'memberCount': 4,
      'isJoined': false,
    });
    expect(parsed.isFeatured, isFalse);
    expect(explore([parsed]), isEmpty,
        reason: 'an old response must not accidentally feature everything');
  });

  test('isFeatured is parsed when present', () {
    final parsed = CommunitiesItemModel.fromJson({
      'id': 'y',
      'name': 'Featured row',
      'memberCount': 2,
      'isJoined': false,
      'isFeatured': true,
    });
    expect(parsed.isFeatured, isTrue);
    expect(explore([parsed]).length, 1);
  });
}
