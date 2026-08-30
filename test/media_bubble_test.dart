import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A picture or clip sat inside the padding meant for text, leaving a thick
/// band of bubble colour framing it. Messaging apps let media nearly fill its
/// bubble.
void main() {
  final source = File(
    'lib/app/modules/chat/widgets/message_bubble.dart',
  ).readAsStringSync();

  test('media gets a tight inset, text keeps its own', () {
    expect(source, contains('_isMedia\n                      ? EdgeInsets.all(3.r)'));
    expect(
      source,
      contains('EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h)'),
      reason: 'a text bubble should still be comfortable',
    );
  });

  test('only pictures and clips count as media', () {
    // A document is drawn as a bordered row that reads as part of the bubble,
    // so it keeps the padding text has.
    expect(
      source,
      contains("fileUrl.isNotEmpty && (fileType == 'IMAGE' || fileType == 'VIDEO')"),
    );
  });

  test('a caption brings its own margins', () {
    // With the bubble no longer padding a media message, text would otherwise
    // sit flush against the edge.
    expect(source, contains('EdgeInsets.fromLTRB(11.w, 8.h, 11.w, 7.h)'));
  });

  test('the corners are concentric with the bubble', () {
    // 16 outer, 3 of padding, so 13 inside — for both the image and the clip.
    expect('BorderRadius.circular(13.r)'.allMatches(source).length,
        greaterThanOrEqualTo(3));
  });

  test('the bubble itself keeps its shape', () {
    expect(source, contains('topRight: Radius.circular(16.r)'));
  });
}

extension on String {
  Iterable<Match> allMatches(String input) =>
      RegExp(RegExp.escape(this)).allMatches(input);
}
