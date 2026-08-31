import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Once a profile pinned its own back arrow in the app bar, the card below it
/// kept drawing a second one. Two back buttons sat on screen together, and the
/// card's scrolled away while the pinned one stayed.
void main() {
  const screens = <String>[
    'lib/app/modules/profile/views/person/others_person_screen.dart',
    'lib/app/modules/profile/views/business/others_business_screen.dart',
  ];

  for (final path in screens) {
    test('${path.split('/').last} shows exactly one back button', () {
      final source = File(path).readAsStringSync();

      final pinned = 'Icons.arrow_back'.allMatches(source).length;
      expect(pinned, 1, reason: 'the app bar arrow is the one that stays');

      expect(
        source.contains('isBack: true'),
        isFalse,
        reason: "InfoCard's own back button duplicates the pinned one.",
      );
    });
  }
}
