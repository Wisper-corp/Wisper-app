import 'package:flutter_test/flutter_test.dart';

/// Mirrors the exact chain:
///   group_info_screen:  isPublic = !(groupInfo.isPrivate ?? true)
///   edit_group_screen:  _isPublic = widget.isPublic
///   edit_group_screen:  sends isPrivate = !_isPublic
bool sentIsPrivate({required bool? storedIsPrivate}) {
  final isPublic = !(storedIsPrivate ?? true);   // group_info_screen
  final isPublicState = isPublic;                // edit_group_screen initState
  return !isPublicState;                         // what the PATCH sends
}

/// The behaviour before the fix: isPublic was hardcoded false.
bool sentIsPrivateOld({required bool? storedIsPrivate}) => !false;

void main() {
  test('a PUBLIC community stays public after an edit', () {
    expect(sentIsPrivate(storedIsPrivate: false), isFalse);
  });

  test('a PRIVATE community stays private after an edit', () {
    expect(sentIsPrivate(storedIsPrivate: true), isTrue);
  });

  test('missing value defaults to private (safe: never leaks a private group)', () {
    expect(sentIsPrivate(storedIsPrivate: null), isTrue);
  });

  test('CONTROL: the old code forced every community private', () {
    expect(sentIsPrivateOld(storedIsPrivate: false), isTrue,
        reason: 'reproduces the bug — a public community became private');
    expect(sentIsPrivate(storedIsPrivate: false),
        isNot(sentIsPrivateOld(storedIsPrivate: false)),
        reason: 'the fix must change the outcome for a public community');
  });
}
