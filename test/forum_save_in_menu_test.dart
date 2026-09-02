import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_menu.dart';

/// Saving used to be a bookmark sitting on the action row beside Reply and the
/// heart. It belongs with everything else you can do to a post, behind the
/// overflow button — so the row carries only the two things you do to the post
/// itself.
Future<void> openPostMenu(
  WidgetTester tester, {
  required bool isSaved,
  bool isMine = false,
  bool canDelete = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showForumPostMenu(
                c,
                isFollowing: false,
                canDelete: canDelete,
                isMine: isMine,
                isSaved: isSaved,
                authorName: 'Lukas',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('the post menu', () {
    testWidgets('offers Save when the post is not saved', (tester) async {
      await openPostMenu(tester, isSaved: false);
      expect(find.text('Save post'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    });

    testWidgets('offers to unsave when it already is', (tester) async {
      await openPostMenu(tester, isSaved: true);
      expect(find.text('Remove from saved'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });

    testWidgets('saving is offered on your own post too', (tester) async {
      // Reply-privately is hidden on your own post; saving must not be.
      await openPostMenu(tester, isSaved: false, isMine: true);
      expect(find.text('Save post'), findsOneWidget);
      expect(find.text('Reply privately'), findsNothing);
    });

    testWidgets('tapping it closes the sheet and reports the action',
        (tester) async {
      ForumPostAction? got;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (c) => TextButton(
                  onPressed: () async => got = await showForumPostMenu(
                    c,
                    isFollowing: false,
                    canDelete: false,
                    isMine: false,
                    isSaved: false,
                    authorName: 'Lukas',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save post'));
      await tester.pumpAndSettle();

      expect(got, ForumPostAction.toggleSave);
      expect(find.text('Save post'), findsNothing);
    });
  });

  test('the bookmark is gone from both rows', () {
    for (final path in [
      'lib/app/modules/forum/widget/forum_post_card.dart',
      'lib/app/modules/forum/widget/forum_reply_tile.dart',
    ]) {
      expect(
        File(path).readAsStringSync().contains('SaveButton'),
        isFalse,
        reason: '$path should no longer draw its own bookmark',
      );
    }
  });

  test('the feed wires the menu through to the saved list', () {
    final section = File(
      'lib/app/modules/forum/views/forum_section.dart',
    ).readAsStringSync();
    expect(section, contains("_savedController.toggle('forum', post.id)"));
    expect(section, contains("isSaved: _savedController.isSaved('forum'"));
  });

  test('every post in the feed has the button that opens the menu', () {
    // Without it there is no way left to save, since the bookmark is gone.
    final section = File(
      'lib/app/modules/forum/views/forum_section.dart',
    ).readAsStringSync();
    expect(section, contains('onMore: () => _openMenu(post)'));
  });
}
