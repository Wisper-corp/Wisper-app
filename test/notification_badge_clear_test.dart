import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/push_notification.dart';

/// The launcher badge on Android counts what is sitting in the notification
/// tray. Nothing dismissed those when the app opened, so the count stuck.
///
/// flutter_local_notifications registers no platform implementation off-device,
/// so the cancel itself cannot be driven from here -- only its failure
/// behaviour, plus the wiring that decides when it is called.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a failure to clear never escapes', () {
    // No platform implementation exists in a VM test, so this exercises the
    // real failure path: a badge that will not clear is a blemish, a crash on
    // resume is not.
    expect(
      PushNotificationService().clearDeliveredNotifications(),
      completes,
    );
  });

  test('the dashboard clears on open and on resume', () {
    final source = File(
      'lib/app/modules/dashboard/views/dashboard_screen.dart',
    ).readAsStringSync();

    // Once when the app is opened...
    expect(
      source,
      contains('clearDeliveredNotifications'),
      reason: 'nothing clears the tray, so the badge would keep its count',
    );

    // ...and again on the resume branch, or anything arriving while the app
    // sat backgrounded would leave the count behind.
    final resumed = source.indexOf('AppLifecycleState.resumed');
    expect(resumed, greaterThan(-1));
    expect(
      source.substring(resumed).contains('clearDeliveredNotifications'),
      isTrue,
      reason: 'the badge would survive a background/foreground round trip',
    );

    // Both call sites, not one reused twice.
    expect(
      'clearDeliveredNotifications'.allMatches(source).length,
      greaterThanOrEqualTo(2),
    );
  });

  test('clearing survives being called before startup finished', () {
    final source = File('lib/push_notification.dart').readAsStringSync();
    // cancelAll() throws outright if the plugin was never initialised, which
    // would make an early clear quietly do nothing.
    expect(source, contains('if (!_localReady) await _initLocalNotifications()'));
  });
}

extension on String {
  Iterable<Match> allMatches(String input) => RegExp(this).allMatches(input);
}
