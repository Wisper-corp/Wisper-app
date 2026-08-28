import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/chat/widgets/contact_widget.dart';

/// ContactWidget took an onTap and never wired it to anything, so every
/// caller's callback was dead code — tapping a contact did nothing at all,
/// on the contacts sheet, the call screen and both create-group screens.
void main() {
  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('tapping a contact runs its callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(
      ContactWidget(
        imagePath: '',
        title: 'Priya Sharma',
        subtitle: 'Frontend Lead',
        onTap: () => taps++,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Priya Sharma'));
    await tester.pumpAndSettle();
    expect(taps, 1, reason: 'the callback never fired');
  });

  testWidgets('the empty space in the row is tappable too', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(
      ContactWidget(
        imagePath: '',
        title: 'Lucas Francis',
        subtitle: 'Android Developer',
        onTap: () => taps++,
      ),
    ));
    await tester.pumpAndSettle();

    // A row is mostly gap; hitting only the text would feel broken.
    final row = tester.getRect(find.byType(ContactWidget));
    await tester.tapAt(Offset(row.right - 8, row.center.dy));
    await tester.pumpAndSettle();
    expect(taps, 1, reason: 'only the text was hittable');
  });

  testWidgets('a trailing widget still renders', (tester) async {
    await tester.pumpWidget(host(
      ContactWidget(
        imagePath: '',
        title: 'Kevin carter',
        subtitle: 'Other',
        onTap: () {},
        trailing: const Icon(Icons.check_circle, key: ValueKey('trail')),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trail')), findsOneWidget);
    expect(find.text('Kevin carter'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
  });
}
