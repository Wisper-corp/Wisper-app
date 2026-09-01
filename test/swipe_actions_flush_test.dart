import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/widgets/common/swipe_actions.dart';
import 'package:wisper/app/modules/chat/widgets/member_list_title.dart';

/// The mute and delete buttons ran on past the row's separator into the gap
/// beneath it, so their lower edge floated below the line. They should end
/// level with it.
Future<void> pumpRow(WidgetTester tester, {String message = 'yit'}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwipeActions(
                actions: [
                  SwipeAction(
                    icon: Icons.notifications_off_outlined,
                    colour: const Color(0xffE5A34D),
                    semanticLabel: 'Mute',
                    onTap: () {},
                  ),
                  SwipeAction(
                    icon: Icons.delete_outline_rounded,
                    colour: const Color(0xffE5484D),
                    semanticLabel: 'Delete',
                    onTap: () {},
                  ),
                ],
                child: MemberListTile(
                  isGroup: true,
                  isClass: false,
                  isOnline: false,
                  imagePath: '',
                  name: 'FMCG Mkt',
                  message: message,
                  time: '23 August 2026',
                  unreadMessageCount: '0',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// One of the coloured action buttons behind the row.
Finder button(Color colour) => find.byWidgetPredicate(
      (w) => w is Container && w.color == colour,
    );

/// The hairline the tile ends with.
Finder separator() => find.byWidgetPredicate((w) =>
    w is Container &&
    w.constraints?.maxHeight == 0.5 &&
    w.constraints?.minHeight == 0.5);

void main() {
  testWidgets('the buttons end level with the row separator', (tester) async {
    await pumpRow(tester);

    final line = tester.getRect(separator());
    final mute = tester.getRect(button(const Color(0xffE5A34D)));
    final del = tester.getRect(button(const Color(0xffE5484D)));

    expect(mute.bottom, closeTo(line.bottom, 0.5));
    expect(del.bottom, closeTo(line.bottom, 0.5));
    // Sanity: these really are the two buttons, side by side.
    expect(mute.center.dx, lessThan(del.center.dx));
  });

  testWidgets('still level when the row is taller', (tester) async {
    // A longer message can push the text column past the avatar, which moves
    // the separator. The buttons must follow it.
    await pumpRow(tester, message: 'a considerably longer preview line');

    final line = tester.getRect(separator());
    expect(
      tester.getRect(button(const Color(0xffE5A34D))).bottom,
      closeTo(line.bottom, 0.5),
    );
  });

  testWidgets('nothing of the tile is drawn below the separator',
      (tester) async {
    await pumpRow(tester);
    final line = tester.getRect(separator());
    final tile = tester.getRect(find.byType(MemberListTile));
    expect(tile.bottom, closeTo(line.bottom, 0.5));
  });

  testWidgets('the separator sits just clear of the picture, as it always did',
      (tester) async {
    // Dropping the empty second line once pulled this line up under the name,
    // where it cut across the avatar on a community with no messages. It
    // belongs just below the picture, and in the same place whether or not
    // there is a message.
    for (final message in ['', 'checking']) {
      await pumpRow(tester, message: message);

      final tile = tester.getRect(find.byType(MemberListTile));
      final avatar = tester.getRect(find.byType(CircleAvatar).first);
      final line = tester.getRect(separator());

      expect(line.top, greaterThan(avatar.bottom),
          reason: 'it must never cross the picture');
      expect(line.top - avatar.bottom, closeTo(3, 0.5));
      // The row keeps the height it had before any of this.
      expect(tile.height, closeTo(77.5, 0.5));
    }
  });
}
