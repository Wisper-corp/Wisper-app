import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Android throws a small icon's colours away and keeps only its alpha, then
/// paints that shape white. A fully opaque PNG therefore renders as a plain
/// white square instead of the Wisper mark — which is exactly what the launcher
/// icon used to do when it was pointed at from the notification code.
void main() {
  const densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
  const res = 'android/app/src/main/res';

  Future<Uint8List> pixelsOf(String path) async {
    final codec = await ui.instantiateImageCodec(
      await File(path).readAsBytes(),
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    return data!.buffer.asUint8List();
  }

  test('a notification icon ships at every density', () {
    for (final d in densities) {
      expect(
        File('$res/drawable-$d/ic_notification.png').existsSync(),
        isTrue,
        reason: 'missing ic_notification.png for $d',
      );
    }
  });

  test('the icon is a silhouette, not a solid block', () async {
    for (final d in densities) {
      final px = await pixelsOf('$res/drawable-$d/ic_notification.png');
      var transparent = 0;
      var opaque = 0;
      for (var i = 3; i < px.length; i += 4) {
        if (px[i] == 0) transparent++;
        if (px[i] == 255) opaque++;
      }
      final total = px.length ~/ 4;

      // Enough transparency that the mark reads as a shape...
      expect(
        transparent / total,
        greaterThan(0.3),
        reason: '$d icon is nearly solid — Android would draw a white square',
      );
      // ...and enough solid pixels that something is actually visible.
      expect(
        opaque / total,
        greaterThan(0.05),
        reason: '$d icon is almost entirely transparent — nothing would show',
      );
    }
  });

  test('nothing points a notification at the opaque launcher icon', () {
    for (final path in [
      'lib/push_notification.dart',
      'lib/app/core/services/notifications/rich_notification.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('@mipmap/ic_launcher')),
        reason: '$path would render a white square as the badge',
      );
    }
  });

  test('the system tray is told which icon to use', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    // Pushes drawn by Android itself (app backgrounded) read this metadata.
    expect(
      manifest,
      contains('com.google.firebase.messaging.default_notification_icon'),
    );
    expect(manifest, contains('@drawable/ic_notification'));
  });
}
