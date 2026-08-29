import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A business publishes a job, lands back on its profile, and the Job tab is
/// empty. The publish screens call resetPagination() on the profile's shared
/// controllers, and those cleared the list without fetching it again — so
/// publishing emptied the very list the new job was supposed to appear in.
///
/// The controllers need a signed-in session and a live NetworkCaller to drive
/// end to end, so this checks the contract that decides the behaviour.
void main() {
  String read(String path) => File(path).readAsStringSync();

  /// The body of a named method, up to the next method at the same indent.
  String methodBody(String source, String signature) {
    final start = source.indexOf(signature);
    expect(start, greaterThan(-1), reason: 'missing: $signature');
    final rest = source.substring(start);
    final end = rest.indexOf('\n  }');
    return rest.substring(0, end == -1 ? rest.length : end);
  }

  group('resetting a profile list fetches it again', () {
    test('jobs', () {
      final body = methodBody(
        read('lib/app/modules/job/controller/my_job_controller.dart'),
        'void resetPagination()',
      );
      expect(body, contains('_allJobList.clear()'));
      expect(
        body,
        contains('getJobs('),
        reason: 'clears the list and never refills it',
      );
    });

    test('services', () {
      final body = methodBody(
        read('lib/app/modules/post/controller/my_post_controller.dart'),
        'void resetPagination()',
      );
      expect(body, contains('_allPostList.clear()'));
      expect(
        body,
        contains('getAllPost()'),
        reason: 'clears the list and never refills it',
      );
    });
  });

  group('the profile sections start from a clean page', () {
    // The controllers are shared and keep their page counter, so a plain fetch
    // on remount asks for the page after the one already loaded.
    test('the services tab resets rather than fetching', () {
      final source = read('lib/app/modules/post/views/my_post_section.dart');
      expect(source, contains('controller.resetPagination()'));
    });

    test('the jobs tab resets rather than fetching', () {
      final source = read('lib/app/modules/job/views/my_job_section.dart');
      expect(source, contains('controller.resetPagination()'));
    });
  });

  test('publishing still asks the profile lists to refresh', () {
    // Both publish screens rely on resetPagination doing the refetch.
    expect(
      read('lib/app/modules/job/views/job_post_screen.dart'),
      contains('resetPagination()'),
    );
    expect(
      read('lib/app/modules/post/views/gallery_post_screen.dart'),
      contains('resetPagination()'),
    );
  });
}
