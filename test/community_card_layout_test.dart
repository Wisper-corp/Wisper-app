import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/chat/model/communities_model.dart';
import 'package:wisper/app/modules/homepage/widget/community_card.dart';

/// Real rows captured from the live API, so the card is measured against the
/// names and tag pills that actually exist rather than tidy fixtures.
List<CommunitiesItemModel> liveGroups() {
  final raw = jsonDecode(File('test/_live_groups.json').readAsStringSync());
  return (raw['data']['groups'] as List)
      .map((g) => CommunitiesItemModel.fromJson(g as Map<String, dynamic>))
      .toList();
}

Future<void> pumpCard(
  WidgetTester tester,
  CommunitiesItemModel item, {
  double width = 360,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CommunityCard(item: item, onTap: () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final w in [360.0, 390.0, 412.0]) {
    testWidgets('every live community card lays out at ${w.toInt()}dp',
        (tester) async {
      for (final item in liveGroups()) {
        await pumpCard(tester, item, width: w);
        expect(tester.takeException(), isNull,
            reason: '"${item.name}" overflowed at ${w.toInt()}dp');
      }
    });
  }

  testWidgets('the name never runs off the right edge', (tester) async {
    for (final item in liveGroups()) {
      await pumpCard(tester, item, width: 360);
      final name = find.text(item.name ?? '');
      if (name.evaluate().isEmpty) continue;
      expect(tester.getRect(name).right, lessThanOrEqualTo(360),
          reason: '"${item.name}" crosses the right edge');
    }
  });

  testWidgets('the card keeps real breathing room around its content',
      (tester) async {
    final item = liveGroups().first;
    await pumpCard(tester, item);
    final card = tester.getRect(find.byType(CommunityCard));
    final name = find.text(item.name ?? '');
    if (name.evaluate().isEmpty) return;
    final nameRect = tester.getRect(name);
    expect(nameRect.left - card.left, greaterThan(8),
        reason: 'text must not hug the left edge');
    expect(card.height, greaterThan(60),
        reason: 'rows must not be crushed together');
  });

  testWidgets('a very long community name truncates rather than overflowing',
      (tester) async {
    final base = liveGroups().first;
    final long = CommunitiesItemModel(
      id: base.id,
      name: 'A Very Long Community Name That Should Truncate Instead Of '
          'Pushing Everything Off The Screen Entirely',
      description: base.description,
      image: base.image,
      createdAt: base.createdAt,
      chatId: base.chatId,
      isJoined: false,
      memberCount: 42,
      members: const [],
      isFeatured: true,
    );
    await pumpCard(tester, long, width: 320);
    expect(tester.takeException(), isNull);
  });
}
