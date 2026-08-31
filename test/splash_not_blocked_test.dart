import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A fresh install hung on the splash logo, and was fine once the app was
/// closed and reopened.
///
/// The splash awaited the camera and microphone permission dialogs before it
/// would navigate. On a first install those dialogs are actually shown, so the
/// logo stayed up until every one had been answered — and stayed for good if
/// one was left standing. On a second launch the answers already exist and the
/// request returns at once, which is the whole shape of the report.
void main() {
  final splash = File(
    'lib/app/modules/onboarding/views/splash_screen.dart',
  ).readAsStringSync();

  test('the permission prompts do not gate navigation', () {
    expect(
      splash.contains('await _requestPermissions()'),
      isFalse,
      reason: 'awaiting the prompts is what held the splash',
    );
    expect(splash, contains('unawaited(_requestPermissions())'));
  });

  test('navigation still runs', () {
    expect(splash, contains('await _checkAndNavigate()'));
  });

  test('a prompt that never resolves cannot take the launch down', () {
    final body = splash.substring(splash.indexOf('_requestPermissions() async'));
    expect(body, contains('try {'));
    expect(body, contains('catch'));
  });

  test('the notification permission is asked for', () {
    // Android 13 and up delivers nothing without it, and it can only be
    // requested while the app is in the foreground.
    expect(splash, contains('Permission.notification'));
  });

  test('notifications are set up before the token fetch, not after', () {
    // PushNotificationService.init() is what asks for the permission. Behind
    // the token fetch it could be twenty seconds late on a first install.
    final main = File('lib/main.dart').readAsStringSync();
    final services = main.substring(main.indexOf('Future<void> _startServices()'));
    expect(
      services.indexOf('PushNotificationService().init()'),
      lessThan(services.indexOf('await _initFCMToken()')),
    );
  });
}
