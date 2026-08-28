import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/validator_service.dart';

/// Change Password could not be submitted at all by anyone whose existing
/// password predates the current strength rules: the Old Password field ran
/// the *new* password rules over it, so the form refused to submit and told
/// them their old password needed a capital letter.
void main() {
  group('the existing password only has to be typed', () {
    test('a password that predates the strength rules is accepted', () {
      // These are all rejected by validatePassword — that is the point.
      for (final legacy in ['chisom123', 'wisper2026', 'password', 'abc1234']) {
        expect(
          ValidatorService.validateCurrentPassword(legacy),
          isNull,
          reason: '"$legacy" cannot be entered, so the form can never submit',
        );
        expect(ValidatorService.validatePassword(legacy), isNotNull,
            reason: 'this test is meaningless if $legacy passes anyway');
      }
    });

    test('blank is still refused', () {
      expect(ValidatorService.validateCurrentPassword(null), isNotNull);
      expect(ValidatorService.validateCurrentPassword(''), isNotNull);
    });

    test('a strong password is fine too', () {
      expect(ValidatorService.validateCurrentPassword('Ssapmms5@123'), isNull);
    });
  });

  group('the new password still has to be strong', () {
    test('the rules the server enforces are enforced here first', () {
      // Mirrors passwordZod on the server: 7+, upper, digit, special.
      expect(ValidatorService.validatePassword('Short1@'), isNull);
      expect(ValidatorService.validatePassword('nocaps1@'), isNotNull);
      expect(ValidatorService.validatePassword('NoDigit@'), isNotNull);
      expect(ValidatorService.validatePassword('NoSpecial1'), isNotNull);
      expect(ValidatorService.validatePassword('Ab1@'), isNotNull);
    });
  });

  group('confirmation', () {
    test('a mismatch is caught before the request', () {
      expect(
        ValidatorService.validateConfirmPassword('Other1@x', 'Ssapmms5@123'),
        isNotNull,
      );
      expect(
        ValidatorService.validateConfirmPassword('Ssapmms5@123', 'Ssapmms5@123'),
        isNull,
      );
    });
  });
}
