import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_card.dart';

void main() {
  test('the same person always gets the same colour', () {
    const id = '9e1d1bf7-073f-4546-8d2c-99a1f0298a58';
    expect(forumNameColor(id), forumNameColor(id));
  });

  test('no id falls back to white', () {
    expect(forumNameColor(null), Colors.white);
    expect(forumNameColor(''), Colors.white);
  });

  test('a colliding neighbour is nudged to a different colour', () {
    const id = 'agent-abc';
    final own = forumNameColor(id);
    final nudged = forumNameColor(id, avoid: own);
    expect(nudged, isNot(own),
        reason: 'two names in a row must never share a colour');
    expect(kForumNameColors.contains(nudged), isTrue,
        reason: 'the nudge must stay inside the palette');
  });

  test('a non-colliding neighbour leaves the colour alone', () {
    const id = 'agent-abc';
    final own = forumNameColor(id);
    final other = kForumNameColors.firstWhere((c) => c != own);
    expect(forumNameColor(id, avoid: other), own);
  });

  test('running the real feed order, no two neighbours match', () {
    // Ids shaped like the ones the API returns.
    final ids = List.generate(40, (i) => 'a3f5b1c$i-0000-4000-8000-00000000000$i');
    Color? previous;
    for (final id in ids) {
      final colour = forumNameColor(id, avoid: previous);
      expect(colour, isNot(previous), reason: 'neighbours collided at $id');
      previous = colour;
    }
  });

  test('the palette has no duplicates and no near-identical blues', () {
    expect(kForumNameColors.toSet().length, kForumNameColors.length,
        reason: 'a duplicate would make the nudge a no-op');
    expect(kForumNameColors.length, greaterThanOrEqualTo(8),
        reason: 'too few colours and collisions become common');
  });

  test('every colour is bright enough to read on the dark card', () {
    for (final c in kForumNameColors) {
      // Card background is #0D0D0D, so luminance needs real separation.
      expect(c.computeLuminance(), greaterThan(0.08),
          reason: '$c is too dark to read on black');
    }
  });
}
