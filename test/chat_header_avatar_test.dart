import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The chat header's avatar stood taller than the name-and-status block beside
/// it and crowded the back arrow: 44 across against a 36-tall block.
void main() {
  final source = File(
    'lib/app/modules/chat/widgets/chatting_header.dart',
  ).readAsStringSync();

  test('the avatar is sized from one named constant', () {
    expect(source, contains('final double kChatHeaderAvatarRadius = 18.r'));
    expect(source, contains('radius: kChatHeaderAvatarRadius'));
    // The old hard-coded size is gone.
    expect(source, isNot(contains('radius: 22.r')));
  });

  test('its diameter matches the text it sits beside', () {
    // The name is 17 at line-height 1.2 and the status 12 at 1.3.
    double lineHeight(String fontSize, String height) =>
        double.parse(fontSize) * double.parse(height);

    final name = lineHeight('17', '1.2');
    final status = lineHeight('12', '1.3');
    const diameter = 18 * 2;

    expect(name + status, closeTo(diameter, 0.5));
  });

  test('the header still shows a status, which is what it is sized to', () {
    // The words themselves, not the expression that picks between them --
    // "typing..." joined them later and the avatar sizing did not change.
    expect(source, contains("'Online'"));
    expect(source, contains("'Offline'"));
    expect(source, contains('fontSize: 17.sp'));
    expect(source, contains('fontSize: 12.sp'));
  });

  test('one size for every chat profile, whoever it is', () {
    // Only one avatar radius in the header, so it cannot vary per person.
    expect('kChatHeaderAvatarRadius'.allMatches(source).length, 2);
  });
}

extension on String {
  Iterable<Match> allMatches(String input) =>
      RegExp(RegExp.escape(this)).allMatches(input);
}
