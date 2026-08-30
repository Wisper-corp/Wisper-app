import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/calls/controller/call_logs_controller.dart';
import 'package:wisper/app/modules/calls/model/call_log_model.dart';

/// The Calls search box had no controller and nothing read what was typed, so
/// it filtered nothing at all.
void main() {
  late CallLogsController ctrl;

  CallLogItem call(String name) => CallLogItem(
        id: name,
        type: 'AUDIO',
        mode: 'ONE_TO_ONE',
        duration: 1,
        date: DateTime(2026, 8, 31).toIso8601String(),
        participants: [
          CallLogParticipant(status: 'OUTGOING', name: 'me', image: null),
          CallLogParticipant(status: 'INCOMING', name: name, image: null),
        ],
      );

  setUp(() {
    Get.reset();
    // onInit fetches; constructing directly keeps the test off the network.
    ctrl = CallLogsController();
    ctrl.allCalls.addAll([
      call('faraz Ahmed'),
      call('Kate Dz'),
      call('Chisom Alaoma'),
    ]);
    ctrl.missedCalls.addAll([call('faraz Ahmed'), call('Kate Dz')]);
  });
  tearDown(Get.reset);

  test('with no term, everything shows', () {
    expect(ctrl.visibleCalls.length, 3);
    expect(ctrl.visibleMissedCalls.length, 2);
  });

  test('a term narrows the list by name', () {
    ctrl.search('kate');
    expect(ctrl.visibleCalls.map((c) => c.otherName), ['Kate Dz']);
  });

  test('matching ignores case and matches part of a name', () {
    ctrl.search('AHM');
    expect(ctrl.visibleCalls.length, 1);
    ctrl.search('alaoma');
    expect(ctrl.visibleCalls.length, 1);
  });

  test('missed calls are filtered by the same term', () {
    ctrl.search('kate');
    expect(ctrl.visibleMissedCalls.length, 1);
    expect(ctrl.visibleCalls.length, 1);
  });

  test('a term matching nothing gives an empty list, not everything', () {
    ctrl.search('zzzznomatch');
    expect(ctrl.visibleCalls, isEmpty);
    expect(ctrl.visibleMissedCalls, isEmpty);
  });

  test('whitespace is not a search', () {
    ctrl.search('   ');
    expect(ctrl.visibleCalls.length, 3);
  });

  test('clearing brings the list back', () {
    ctrl.search('kate');
    expect(ctrl.visibleCalls.length, 1);
    ctrl.search('');
    expect(ctrl.visibleCalls.length, 3);
  });

  test('the underlying list is never mutated by searching', () {
    ctrl.search('kate');
    expect(ctrl.allCalls.length, 3, reason: 'filtering must not delete calls');
  });
}
