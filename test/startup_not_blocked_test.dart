import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The app came up blank on a first launch and was fine on the second.
///
/// The first frame cannot be drawn until main() reaches runApp, and main()
/// awaited the FCM token first. On a first launch there is no cached token, so
/// getToken() makes a network round trip — unbounded — and the screen stayed
/// black for as long as it took. The second launch read the cached token and
/// returned at once, which is exactly the shape of the report.
void main() {
  final source = File('lib/main.dart').readAsStringSync();
  final beforeRunApp = source.substring(0, source.indexOf('runApp('));

  test('nothing waits on the network before the first frame', () {
    for (final call in [
      'await _initFCMToken()',
      'await socketService.init()',
      'await Get.find<SocketService>().init()',
      'await PushNotificationService()',
    ]) {
      expect(
        beforeRunApp.contains(call),
        isFalse,
        reason: '$call blocks the first frame',
      );
    }
  });

  test('the network work is started, just not awaited', () {
    expect(source, contains('unawaited(_startServices())'));
    expect(source, contains('Future<void> _startServices()'));
    // Still registers the FCM background handler, which nothing else does.
    expect(source, contains('PushNotificationService().init()'));
  });

  test('the token fetch is bounded', () {
    // A missing token costs notifications until the next launch. A hang costs
    // the whole app.
    final tokenFn = source.substring(source.indexOf('Future<void> _initFCMToken'));
    expect(tokenFn, contains('.timeout('));
  });

  test('runApp is not deferred behind a platform channel', () {
    // It used to sit inside setPreferredOrientations().then(...).
    expect(source, isNot(contains('setPreferredOrientations([\n'
        '    DeviceOrientation.portraitUp,\n'
        '    DeviceOrientation.portraitDown,\n'
        '  ]).then(')));
    expect(source, contains('unawaited(SystemChrome.setPreferredOrientations('));
  });

  test('a build failure still shows why rather than a black screen', () {
    expect(source, contains('ErrorWidget.builder'));
  });
}
