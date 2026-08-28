import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/saved/model/saved_item_model.dart';

/// The bookmark on a service card used to raise "Save post — coming soon" and
/// nothing existed behind it.
void main() {
  // Captured from GET /saved against the live API with two things saved: a
  // service post with three images and a price, and a forum post.
  final live = (json.decode(
    File('test/fixtures/saved_live.json').readAsStringSync(),
  ) as List)
      .map((e) => SavedItemModel.fromJson(e as Map<String, dynamic>))
      .toList();

  test('the live payload parses into both kinds', () {
    expect(live.length, 2);
    expect(live.map((i) => i.kind).toSet(), {'service', 'forum'});
  });

  test('a saved service keeps its price, delivery and pictures', () {
    final service = live.firstWhere((i) => i.isService);
    expect(service.price, 2000);
    expect(service.currency, 'NGN');
    expect(service.deliveryTime, '30 Days');
    expect(service.images.length, 3);
    expect(service.authorName, isNotEmpty);
    expect(service.id, isNotEmpty);
  });

  test('a saved forum post knows which community it came from', () {
    final forum = live.firstWhere((i) => !i.isService);
    expect(forum.groupName, isNotNull);
    expect(forum.groupName, isNotEmpty);
    expect(forum.text, isNotEmpty);
    // Forum posts carry no price — the tile must not render one.
    expect(forum.price, isNull);
  });

  test('a payload missing every optional field still parses', () {
    // The server omits nulls in places; a tile must not crash on a sparse row.
    final sparse = SavedItemModel.fromJson({
      'savedId': 's1',
      'kind': 'forum',
      'id': 'p1',
      'text': '',
    });
    expect(sparse.images, isEmpty);
    expect(sparse.authorName, 'Someone');
    expect(sparse.price, isNull);
    expect(sparse.createdAt, isNull);
    expect(sparse.isService, isFalse);
  });

  test('kind decides which fields are meaningful', () {
    expect(live.firstWhere((i) => i.isService).isService, isTrue);
    expect(live.firstWhere((i) => !i.isService).isService, isFalse);
  });
}
