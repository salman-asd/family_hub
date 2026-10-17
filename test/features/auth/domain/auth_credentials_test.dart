import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/auth/domain/auth_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email format', () {
    test('accepts ordinary addresses', () {
      const good = [
        'a@b.co',
        'salman@familyhub.dev',
        'first.last+tag@sub.example.com',
        'x_y-z@example.io',
      ];
      for (final email in good) {
        expect(
          AuthCredentials.isValidEmail(email),
          isTrue,
          reason: '$email should be valid',
        );
      }
    });

    test('rejects malformed addresses', () {
      const bad = [
        '',
        'plain',
        'a@b', // no TLD
        '@example.com', // no local part
        'a@.com', // empty label
        'a b@example.com', // space
        'a@example', // no dot in domain
        'a@@example.com',
      ];
      for (final email in bad) {
        expect(
          AuthCredentials.isValidEmail(email),
          isFalse,
          reason: '$email should be rejected',
        );
      }
    });

    test('is case- and whitespace-tolerant on the trimmed value', () {
      expect(AuthCredentials.isValidEmail('  A@Example.COM  '), isTrue);
    });
  });

  group('password rule', () {
    test('requires at least 8 characters', () {
      expect(AuthCredentials.isValidPassword('1234567'), isFalse);
      expect(AuthCredentials.isValidPassword('12345678'), isTrue);
    });

    test('does not trim — spaces are part of the password', () {
      expect(AuthCredentials.isValidPassword('        '), isTrue);
      expect(AuthCredentials.isValidPassword('       '), isFalse);
    });
  });

  group('validateEmail', () {
    test('empty -> Validation(email, required)', () {
      expect(
        AuthCredentials.validateEmail(''),
        const Validation(
          AuthCredentials.fieldEmail,
          AuthCredentials.codeRequired,
        ),
      );
      expect(
        AuthCredentials.validateEmail(null),
        const Validation(
          AuthCredentials.fieldEmail,
          AuthCredentials.codeRequired,
        ),
      );
    });

    test('malformed -> Validation(email, invalid_email)', () {
      expect(
        AuthCredentials.validateEmail('nope'),
        const Validation(
          AuthCredentials.fieldEmail,
          AuthCredentials.codeInvalidEmail,
        ),
      );
    });

    test('valid -> null', () {
      expect(AuthCredentials.validateEmail('a@b.co'), isNull);
    });
  });

  group('validatePassword', () {
    test('empty -> Validation(password, required)', () {
      expect(
        AuthCredentials.validatePassword(''),
        const Validation(
          AuthCredentials.fieldPassword,
          AuthCredentials.codeRequired,
        ),
      );
    });

    test('too short -> Validation(password, password_too_short)', () {
      expect(
        AuthCredentials.validatePassword('short'),
        const Validation(
          AuthCredentials.fieldPassword,
          AuthCredentials.codePasswordTooShort,
        ),
      );
    });

    test('acceptable -> null', () {
      expect(AuthCredentials.validatePassword('longenough'), isNull);
    });
  });

  group('Result wrappers', () {
    test('checkEmail trims the accepted value', () {
      final result = AuthCredentials.checkEmail('  a@b.co  ');
      expect(result.valueOrNull, 'a@b.co');
    });

    test('checkEmail surfaces the failure', () {
      expect(AuthCredentials.checkEmail('nope').isFailure, isTrue);
    });

    test('checkPassword keeps the raw value, including spaces', () {
      final result = AuthCredentials.checkPassword('  spaces  ');
      expect(result.valueOrNull, '  spaces  ');
    });

    test('checkPassword surfaces the failure', () {
      expect(AuthCredentials.checkPassword('short').isFailure, isTrue);
    });
  });
}
