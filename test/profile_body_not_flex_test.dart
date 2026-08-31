import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A profile screen shows its tab content as the body of a NestedScrollView.
/// A NestedScrollView body is not a Flex, so a section whose build returns
/// Expanded throws `Incorrect use of ParentDataWidget` — and it throws again on
/// every rebuild, so the profile never draws. That shipped once and read to the
/// client as the app freezing when opening anyone's profile.
void main() {
  /// The sections handed to a NestedScrollView body, and the screen that does
  /// it. Add a row here when a new tab is added to a profile.
  const bodies = <String, String>{
    'lib/app/modules/post/views/others_post_section.dart':
        'others_person_screen + others_business_screen',
    'lib/app/modules/job/views/others_job_section.dart':
        'others_business_screen',
    'lib/app/modules/homepage/views/my_resume_section.dart':
        'others_person_screen + profile_screen',
    'lib/app/modules/post/views/my_post_section.dart': 'profile_screen',
  };

  group('a profile tab body is never an Expanded', () {
    bodies.forEach((path, shownBy) {
      test('${path.split('/').last} ($shownBy)', () {
        final source = File(path).readAsStringSync();

        // Only a *root* Expanded is the bug. One nested inside a Column the
        // section builds itself is perfectly fine, so match the return.
        expect(
          RegExp(r'return Expanded\(').hasMatch(source),
          isFalse,
          reason: 'This widget is a NestedScrollView body, which is not a '
              'Flex. Returning Expanded throws on every build and the profile '
              'never renders. Return the list directly — the body already '
              'passes down a bounded height.',
        );
      });
    });
  });

  testWidgets('the pattern it guards against really does throw', (tester) async {
    // Proof the rule above is not superstition: the same shape a profile
    // screen has, with an Expanded root, raises on the first frame.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              const SliverAppBar(pinned: true),
            ],
            body: Expanded(
              child: ListView(children: const [Text('a post')]),
            ),
          ),
        ),
      ),
    );

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect('$error', contains('Incorrect use of ParentDataWidget'));
  });
}
