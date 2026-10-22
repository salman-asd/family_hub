import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';

/// Localized text for Bazar use-case failures (roadmap section 3.6).
///
/// The switch is exhaustive on purpose: a new [AppFailure] subtype is a compile
/// error until it is given a message. Unknown `Validation`/`Conflict` codes
/// (written by a newer app version) fall back to the generic sentence; a raw
/// code is never shown to the user.
extension BazarFailureMessages on AppLocalizations {
  String bazarFailureMessage(AppFailure failure) => switch (failure) {
    Validation(code: 'required') => bazarErrRequired,
    Validation(code: 'too_long') => bazarErrTooLong,
    Validation(code: 'invalid_amount') => bazarErrInvalidAmount,
    Validation(code: 'amount_not_positive') => bazarErrAmountNotPositive,
    Validation(code: 'future_date') => bazarErrFutureDate,
    Validation(code: 'qty_unit_required') => bazarErrQtyUnitRequired,
    Validation(code: 'member_required') => bazarErrMemberRequired,
    Validation(code: 'category_required') => bazarErrCategoryRequired,
    Validation(code: 'item_name_required') => bazarErrItemNameRequired,
    Validation(code: 'too_many_lines') => bazarErrTooManyLines,
    Validation(code: 'invalid_month') => bazarErrInvalidMonth,
    Validation(code: 'invalid_range') => bazarErrInvalidRange,
    Validation(code: 'negative') => bazarErrNegative,
    Validation(code: 'too_many_decimals') => bazarErrTooManyDecimals,
    Validation(code: 'too_large') => bazarErrTooLarge,
    Validation() => bazarErrUnknown,
    Conflict(code: 'month_locked') => bazarErrMonthLocked,
    Conflict(code: 'advance_settled') => bazarErrAdvanceSettled,
    Conflict(code: 'overpayment') => bazarErrOverpayment,
    Conflict(code: 'already_closed') => bazarErrAlreadyClosed,
    Conflict(code: 'not_closed') => bazarErrNotClosed,
    Conflict(code: 'reopen_note_required') => bazarErrReopenNoteRequired,
    Conflict(code: 'catalog_not_empty') => bazarErrCatalogNotEmpty,
    Conflict(code: 'duplicate_item') => bazarErrDuplicateItem,
    Conflict(code: 'import_already_undone') => bazarErrImportAlreadyUndone,
    Conflict(code: 'import_has_locked_month') => bazarErrImportHasLockedMonth,
    Conflict(code: 'concurrent_edit') => bazarErrConcurrentEdit,
    Conflict() => bazarErrUnknown,
    NotFound() => bazarErrNotFound,
    PermissionDenied() => bazarErrNotAllowed,
    Network() => errorNetwork,
    Unknown() ||
    InvalidCredentials() ||
    UserNotFound() ||
    EmailAlreadyInUse() ||
    WeakPassword() ||
    TooManyRequests() ||
    UserDisabled() ||
    RequiresRecentLogin() ||
    InvalidEmail() ||
    NoCurrentUser() => bazarErrUnknown,
  };
}
