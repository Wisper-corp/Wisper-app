import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/forum/widget/forum_poll_view.dart';

ForumPoll poll({String? mine, List<int> votes = const [0, 0, 0]}) {
  final total = votes.fold<int>(0, (a, b) => a + b);
  const labels = ['Monday', 'Wednesday', 'Friday'];
  return ForumPoll(
    id: 'p1',
    totalVotes: total,
    myOptionId: mine,
    options: [
      for (var i = 0; i < labels.length; i++)
        ForumPollOption(
          id: 'o$i',
          text: labels[i],
          votes: votes[i],
          percent: total == 0 ? 0 : ((votes[i] / total) * 100).round(),
        ),
    ],
  );
}

Future<ForumPollOption?> pump(WidgetTester tester, ForumPoll p,
    {double width = 360}) async {
  ForumPollOption? voted;
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ForumPollView(poll: p, onVote: (o) => voted = o),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return voted;
}

void main() {
  testWidgets('before voting: options shown, no percentages', (tester) async {
    await pump(tester, poll());
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing,
        reason: 'results stay hidden until you vote');
    expect(find.text('No votes yet — be the first.'), findsOneWidget);
  });

  testWidgets('tapping an option reports the vote', (tester) async {
    ForumPollOption? got;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: ForumPollView(poll: poll(), onVote: (o) => got = o),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wednesday'));
    await tester.pump();
    expect(got?.text, 'Wednesday');
  });

  testWidgets('after voting: percentages appear and my choice is marked',
      (tester) async {
    await pump(tester, poll(mine: 'o1', votes: [1, 3, 0]));
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget,
        reason: 'exactly one option is mine');
    expect(find.text('4 votes'), findsOneWidget);
  });

  testWidgets('a voted poll ignores further taps', (tester) async {
    final got = await pump(tester, poll(mine: 'o0', votes: [1, 0, 0]));
    await tester.tap(find.text('Friday'));
    await tester.pump();
    expect(got, isNull, reason: 'voting twice must not be possible');
  });

  testWidgets('one vote reads in the singular', (tester) async {
    await pump(tester, poll(mine: 'o0', votes: [1, 0, 0]));
    expect(find.text('1 vote'), findsOneWidget);
  });

  testWidgets('options have generous, even spacing', (tester) async {
    await pump(tester, poll());
    final a = tester.getRect(find.text('Monday'));
    final b = tester.getRect(find.text('Wednesday'));
    final c = tester.getRect(find.text('Friday'));
    final gap1 = b.top - a.bottom;
    final gap2 = c.top - b.bottom;
    expect(gap1, greaterThan(14), reason: 'rows must not be cramped');
    expect(gap2, closeTo(gap1, 1), reason: 'spacing must be even');
  });

  testWidgets('a long option wraps instead of overflowing', (tester) async {
    final p = ForumPoll(
      id: 'p',
      totalVotes: 2,
      myOptionId: 'a',
      options: [
        ForumPollOption(
          id: 'a',
          text: 'Wednesday afternoon after the quarterly review, if that suits',
          votes: 2,
          percent: 100,
        ),
        ForumPollOption(id: 'b', text: 'No', votes: 0, percent: 0),
      ],
    );
    await pump(tester, p, width: 320);
    expect(tester.takeException(), isNull,
        reason: 'a long option must not overflow the row');
    expect(find.text('100%'), findsOneWidget,
        reason: 'the percentage stays visible beside a long label');
  });
}
