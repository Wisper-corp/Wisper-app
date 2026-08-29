import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// flutter_local_notifications resolves an icon with
/// getIdentifier(name, "drawable", package). A prefixed name like
/// "@drawable/ic_notification" resolves to 0, and initialize() then fails
/// outright with an invalid-icon error — which is what made every attempt to
/// clear the tray, and every notification the app draws itself, fail.
void main() {
  final sources = [
    'lib/push_notification.dart',
    'lib/app/core/services/notifications/rich_notification.dart',
  ];

  test('icons are referenced by bare resource name', () {
    for (final path in sources) {
      final source = File(path).readAsStringSync();
      // Only string literals — a comment may legitimately mention the form.
      final prefixed = RegExp(r"'@(drawable|mipmap)/").allMatches(source);
      expect(
        prefixed,
        isEmpty,
        reason: '$path passes a prefixed name, which resolves to 0',
      );
    }
  });

  test('the name that is used matches a real drawable file', () {
    for (final path in sources) {
      final source = File(path).readAsStringSync();
      for (final match
          in RegExp(r"'(ic_[a-z_]+)'").allMatches(source)) {
        final name = match.group(1)!;
        final exists = [
          'mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi',
        ].every((d) =>
            File('android/app/src/main/res/drawable-$d/$name.png').existsSync());
        expect(exists, isTrue,
            reason: '$name is referenced but not shipped at every density');
      }
    }
  });

  test('the manifest points at the same drawable', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    // The manifest is XML, where the @drawable/ prefix is correct.
    expect(manifest, contains('@drawable/ic_notification'));
  });
}
