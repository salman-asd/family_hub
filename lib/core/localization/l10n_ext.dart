import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/locale_controller.dart';
import 'package:family_hub/core/localization/locale_prefs.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Re-export the controller so callers get the provider and prefs in one import.
export 'package:family_hub/core/localization/locale_controller.dart'
    show localeControllerProvider;

/// Convenience access to the generated [AppLocalizations] from any widget:
/// `context.l10n.actionSave`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Provider exposing [AppFormatters] built from the active [LocalePrefs].
///
/// Widgets read it with `ref.watch(appFormattersProvider)`; pure tests build an
/// [AppFormatters] directly.
final appFormattersProvider = Provider<AppFormatters>((ref) {
  final prefs = ref.watch(localeControllerProvider);
  return AppFormatters(
    languageCode: prefs.languageCode,
    useBanglaDigits: prefs.useBanglaDigits,
  );
});

/// A [Locale] list for [MaterialApp.supportedLocales], derived from the
/// single source of truth in [LocalePrefs].
List<Locale> get supportedLocales =>
    LocalePrefs.supportedLanguageCodes.map(Locale.new).toList(growable: false);

/// Resolves the message code produced by `authFailureCode` (see
/// `features/auth/presentation/auth_providers.dart`) into localized text.
///
/// The domain layer never holds user-visible strings (CLAUDE.md rule 7), so it
/// returns a stable code and this extension owns the single mapping from code
/// to copy.  Unknown codes fall back to the generic error message rather than
/// throwing or showing a raw code to the user.
extension AuthFailureMessages on AppLocalizations {
  /// Localized text for an auth message [code].
  ///
  /// Codes of the form `validation.<field>.<reason>` are split so the field
  /// name can be substituted into the message.
  String authFailureMessage(String code) {
    if (code.startsWith('validation.')) {
      final parts = code.split('.');
      // parts = ['validation', field, reason]
      if (parts.length == 3) {
        final field = switch (parts[1]) {
          'email' => authFieldEmail,
          'password_confirm' => authPasswordConfirmLabel,
          _ => authFieldPassword,
        };
        return switch (parts[2]) {
          'required' => switch (parts[1]) {
              // The confirmation field is not a backend concept, so it has its
              // own copy rather than reusing the generic "fill in X" message.
              'password_confirm' =>
                authFailureValidationPasswordConfirmRequired,
              _ => authFailureValidationRequired(field),
            },
          'invalid_email' => authFailureValidationInvalidEmail,
          'password_too_short' => authFailureValidationPasswordTooShort,
          'password_mismatch' => authFailureValidationPasswordMismatch,
          _ => authFailureUnknown,
        };
      }
      return authFailureUnknown;
    }

    return switch (code) {
      'permission_denied' => authFailurePermissionDenied,
      'not_found' => authFailureNotFound,
      'conflict' => authFailureConflict,
      'network' => authFailureNetwork,
      'invalid_credentials' => authFailureInvalidCredentials,
      'user_not_found' => authFailureUserNotFound,
      'email_already_in_use' => authFailureEmailInUse,
      'weak_password' => authFailureWeakPassword,
      'too_many_requests' => authFailureTooManyRequests,
      'user_disabled' => authFailureUserDisabled,
      'requires_recent_login' => authFailureRequiresRecentLogin,
      'invalid_email' => authFailureInvalidEmail,
      'no_current_user' => authFailureNoCurrentUser,
      _ => authFailureUnknown,
    };
  }
}

/// Localized text for failures of the family / onboarding use cases.
///
/// Conflict and validation codes are defined by those use cases
/// (`code_used`, `code_expired`, `last_admin`, ...).  Anything unexpected falls
/// back to the generic message; a raw code is never shown.
extension FamilyFailureMessages on AppLocalizations {
  String familyFailureMessage(AppFailure failure) => switch (failure) {
        Validation(field: 'code') => famFailureCodeInvalid,
        Validation(field: 'profile') => famFailureProfileRequired,
        Validation(field: 'name' || 'fullName') => famFailureNameRequired,
        Validation(field: 'label') => relationshipsFailureLabel,
        Validation(field: 'entries') => relationshipsFailureTooMany,
        Conflict(code: 'built_in') => relationshipsFailureBuiltIn,
        NotFound(entity: 'invitation') => famFailureCodeNotFound,
        Conflict(code: 'code_used') => famFailureCodeUsed,
        Conflict(code: 'code_expired') => famFailureCodeExpired,
        Conflict(code: 'code_revoked') => famFailureCodeRevoked,
        Conflict(code: 'already_member') => famFailureAlreadyMember,
        Conflict(code: 'already_in_family') => famFailureAlreadyInFamily,
        Conflict(code: 'last_admin') => famFailureLastAdmin,
        Conflict(code: 'last_admin_has_members') =>
          accountDeleteLastAdminHasMembers,
        PermissionDenied() => famFailureNotAllowed,
        Network() => errorNetwork,
        // Exhaustive on purpose (H8): a new AppFailure subtype is a compile
        // error here until it is given a message, never a silent fallback.
        Validation() ||
        NotFound() ||
        Conflict() ||
        Unknown() ||
        InvalidCredentials() ||
        UserNotFound() ||
        EmailAlreadyInUse() ||
        WeakPassword() ||
        TooManyRequests() ||
        UserDisabled() ||
        RequiresRecentLogin() ||
        InvalidEmail() ||
        NoCurrentUser() =>
          errorUnknown,
      };
}
