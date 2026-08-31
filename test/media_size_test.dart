import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A picture was forced into a 200-high letterbox with BoxFit.cover, so a tall
/// photo was cropped to a band and a wide one floated in filler. Messaging
/// apps let media keep its own shape, capped so one very tall picture cannot
/// take the whole screen.
void main() {
  final source = File(
    'lib/app/modules/chat/widgets/message_bubble.dart',
  ).readAsStringSync();

  /// Just the image branch.
  final imageAt = source.indexOf("if (fileType == 'IMAGE')");
  final videoAt = source.indexOf("else if (fileType == 'VIDEO')");
  final imageBranch = source.substring(imageAt, videoAt);

  test('the image is no longer forced to a fixed height', () {
    // The only 200.h left in the branch belongs to the loading and error
    // placeholders, which have no picture to measure.
    expect(imageBranch, isNot(contains('fileUrl,\n                                height: 200.h')));
    expect(imageBranch, contains('width: double.infinity'));
  });

  test('it is capped so one photo cannot fill the screen', () {
    expect(imageBranch, contains('maxHeight: kChatMediaMaxHeight'));
    expect(source, contains('final double kChatMediaMaxHeight = 320.h'));
  });

  test('a clip is shown as its own frame with a play button', () {
    final videoBranch = source.substring(videoAt, videoAt + 600);
    // No fixed box: the poster takes the video's own aspect ratio.
    expect(videoBranch, contains('VideoPoster'));
    expect(videoBranch, isNot(contains('height: 200.h')));
    expect(videoBranch, isNot(contains('Colors.black54')));
  });

  test('placeholders keep a fixed height, having nothing to measure', () {
    // A spinner and a broken-image icon need some height of their own.
    expect(imageBranch, contains('height: 200.h'));
  });

  test('only pictures and clips are affected', () {
    // The document row and text bubbles are untouched.
    expect(
      source,
      contains("fileUrl.isNotEmpty && (fileType == 'IMAGE' || fileType == 'VIDEO')"),
    );
    expect(source, contains('EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h)'));
  });
}
