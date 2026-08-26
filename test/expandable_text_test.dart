import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/widgets/common/expandable_text.dart';

const short = 'Anyone else running dev environments 24/7?';

const long =
    'Ibom Air placed an order for 10 brand new A220s at the Dubai Airshow in '
    '2021, expecting to receive the planes by 2023. But Airbus has been unable '
    'to deliver, and have stretched delivery through to 2028. Only the 3rd '
    'plane was just delivered recently. Meanwhile, the airline is running at '
    '90% load, meaning the existing CRJs are stretched thin across the network '
    'and maintenance windows keep slipping further out.';

const style = TextStyle(fontSize: 15, height: 1.4, color: Colors.white);

Future<void> pump(WidgetTester tester, String text,
    {int maxLines = 4, double width = 340}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: ExpandableText(text, style: style, maxLines: maxLines),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double bodyHeight(WidgetTester tester) =>
    tester.getSize(find.byType(ExpandableText)).height;


/// The inline link is only tappable where it is actually painted - at the end
/// of the last line, whose width varies with the text - so scan that line
/// until the tap registers rather than guessing one coordinate.
Future<void> tapLink(WidgetTester tester) async {
  final before = tester.getSize(find.byType(ExpandableText)).height;
  final rect = tester.getRect(find.byType(RichText).first);
  final y = rect.bottom - 8;
  for (var x = rect.right - 8; x > rect.left; x -= 12) {
    await tester.tapAt(Offset(x, y));
    await tester.pumpAndSettle();
    if (tester.getSize(find.byType(ExpandableText)).height != before) return;
  }
  fail('Could not find the inline link on the last line');
}

void main() {
  testWidgets('short text shows no link at all', (tester) async {
    await pump(tester, short);
    expect(find.textContaining('Show more'), findsNothing);
    expect(find.text(short), findsOneWidget);
  });

  testWidgets('long text collapses and offers Show more', (tester) async {
    await pump(tester, long);
    expect(find.textContaining('Show more'), findsOneWidget);
  });

  testWidgets('collapsed body is no taller than maxLines', (tester) async {
    await pump(tester, long, maxLines: 4);
    // 4 lines at 15px with height 1.4 is ~84px; allow a little slack.
    expect(bodyHeight(tester), lessThan(100),
        reason: 'collapsed text must stay within four lines');
  });

  testWidgets('fewer maxLines yields a shorter block', (tester) async {
    await pump(tester, long, maxLines: 3);
    final three = bodyHeight(tester);
    await pump(tester, long, maxLines: 6);
    final six = bodyHeight(tester);
    expect(three, lessThan(six));
  });

  testWidgets('tapping Show more expands, and offers Show less',
      (tester) async {
    await pump(tester, long);
    final collapsed = bodyHeight(tester);

    await tapLink(tester);

    expect(bodyHeight(tester), greaterThan(collapsed),
        reason: 'expanding must reveal more text');
    expect(find.textContaining('Show less'), findsOneWidget);
  });

  testWidgets('tapping Show less collapses again', (tester) async {
    await pump(tester, long);
    final collapsed = bodyHeight(tester);
    await tapLink(tester);
    expect(find.textContaining('Show less'), findsOneWidget);
    await tapLink(tester);
    expect(bodyHeight(tester), collapsed);
  });

  testWidgets('the cut lands on a word boundary, not mid-word',
      (tester) async {
    await pump(tester, long);
    final widget = tester.widget<RichText>(find.byType(RichText).first);
    final rendered = widget.text.toPlainText();
    final beforeEllipsis = rendered.split('…').first;
    expect(long.startsWith(beforeEllipsis.trimRight()), isTrue,
        reason: 'the visible prefix must be a real prefix of the post');
    // The character after the cut should be a space in the original text.
    final cut = beforeEllipsis.trimRight().length;
    if (cut < long.length) {
      expect(long[cut], anyOf(' ', '.', ','),
          reason: 'must not slice through a word');
    }
  });

  testWidgets('holds up at a narrow width', (tester) async {
    await pump(tester, long, width: 260);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Show more'), findsOneWidget);
    expect(bodyHeight(tester), lessThan(110));
  });
}
