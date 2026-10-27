import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';

/// Which use case the contribution sheet runs.
enum ContributionFormMode {
  /// A manager records a contribution: approved at once, with its ledger row.
  record,

  /// A member asks for approval: a `pending` row, no ledger row.
  request,

  /// The owner corrects their own pending request.
  editPending,

  /// The owner asks to change an approved contribution.
  requestChange,
}

/// What the sheet edits: a month, and for edit/change the contribution id.
final class ContributionFormArgs {
  const ContributionFormArgs({required this.month, this.contributionId});

  final MonthKey month;
  final String? contributionId;

  @override
  bool operator ==(Object other) =>
      other is ContributionFormArgs &&
      other.month == month &&
      other.contributionId == contributionId;

  @override
  int get hashCode => Object.hash(month, contributionId);
}

/// State of the open contribution sheet.
///
/// The amount stays TEXT until `ContributionFormController.submit` parses it
/// through `Money.parse` (never in a widget), and the event id is generated
/// once so a retry writes exactly one log entry (CLAUDE.md rule 15).
final class ContributionFormState {
  const ContributionFormState({
    required this.mode,
    required this.eventId,
    required this.date,
    this.memberId,
    this.amountText = '',
    this.method,
    this.amountError,
    this.failure,
    this.saving = false,
    this.done = false,
  });

  final ContributionFormMode mode;
  final String eventId;
  final DateKey date;
  final String? memberId;
  final String amountText;
  final ContributionMethod? method;

  /// A stable `Validation` code (`invalid_amount`, `amount_not_positive`).
  final String? amountError;
  final AppFailure? failure;
  final bool saving;

  /// `true` after a successful save; the sheet closes on it.
  final bool done;

  ContributionFormState copyWith({
    ContributionFormMode? mode,
    String? memberId,
    String? amountText,
    ContributionMethod? method,
    bool clearMethod = false,
    String? amountError,
    bool clearAmountError = false,
    AppFailure? failure,
    bool clearFailure = false,
    bool? saving,
    bool? done,
    DateKey? date,
  }) => ContributionFormState(
    mode: mode ?? this.mode,
    eventId: eventId,
    date: date ?? this.date,
    memberId: memberId ?? this.memberId,
    amountText: amountText ?? this.amountText,
    method: clearMethod ? null : (method ?? this.method),
    amountError: clearAmountError ? null : (amountError ?? this.amountError),
    failure: clearFailure ? null : (failure ?? this.failure),
    saving: saving ?? this.saving,
    done: done ?? this.done,
  );
}
