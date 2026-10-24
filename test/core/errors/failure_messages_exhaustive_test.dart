import 'dart:io';

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/generated/app_localizations_bn.dart';
import 'package:family_hub/core/localization/generated/app_localizations_en.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// H8: adding an `AppFailure` subtype must not be forgettable.
///
/// The two `switch`es (`authFailureCode`, `familyFailureMessage`) have no
/// default, so the compiler already rejects a missing case.  This test closes
/// the other gap: it fails when a subtype is declared in `app_failure.dart`
/// that this list does not know, and it runs every known failure through both
/// mappings in both languages.
void main() {
  const samples = <AppFailure>[
    PermissionDenied(),
    NotFound(entity: 'member'),
    Validation('name', 'required'),
    Conflict(code: 'last_admin'),
    Network(),
    Unknown('boom'),
    InvalidCredentials(),
    UserNotFound(),
    EmailAlreadyInUse(),
    WeakPassword(),
    TooManyRequests(),
    UserDisabled(),
    RequiresRecentLogin(),
    InvalidEmail(),
    NoCurrentUser(),
  ];

  test('every AppFailure subtype in the source has a sample here', () {
    final source = File('lib/core/errors/app_failure.dart').readAsStringSync();
    final declared = RegExp(r'final class (\w+) extends AppFailure')
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toSet();
    expect(declared, isNotEmpty);
    expect(
      samples.map((s) => s.runtimeType.toString()).toSet(),
      declared,
      reason:
          'a failure type was added or removed: update `samples` and make '
          'sure authFailureCode and familyFailureMessage map it',
    );
  });

  test('every failure has a non-empty family message in bn and en', () {
    for (final l10n in [AppLocalizationsBn(), AppLocalizationsEn()]) {
      for (final failure in samples) {
        expect(
          l10n.familyFailureMessage(failure).trim(),
          isNotEmpty,
          reason: '${failure.runtimeType} (${l10n.localeName})',
        );
      }
    }
  });

  test('every failure has an auth code and a non-empty auth message', () {
    for (final l10n in [AppLocalizationsBn(), AppLocalizationsEn()]) {
      for (final failure in samples) {
        final code = authFailureCode(failure);
        expect(code, isNotEmpty, reason: failure.runtimeType.toString());
        expect(
          l10n.authFailureMessage(code).trim(),
          isNotEmpty,
          reason: '$code (${l10n.localeName})',
        );
      }
    }
  });
}
