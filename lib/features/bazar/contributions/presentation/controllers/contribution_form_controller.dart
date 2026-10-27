import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/bazar/contributions/presentation/controllers/contribution_form_state.dart';
import 'package:family_hub/features/bazar/expenses/domain/amount_input.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The open contribution sheet (`add`, `edit` or `request a change`).
final contributionFormProvider = NotifierProvider.autoDispose
    .family<ContributionFormController, ContributionFormState,
        ContributionFormArgs>(ContributionFormController.new);

/// Drives one contribution sheet: record, request, edit or ask for a change.
///
/// It never parses in the widget: [submit] reads the text once through
/// `Money.parse`, then calls the use case for the mode.
class ContributionFormController extends Notifier<ContributionFormState> {
  ContributionFormController(this.args);

  final ContributionFormArgs args;

  @override
  ContributionFormState build() {
    final actor = ref.read(currentUidProvider);
    final canRecord = ref.can(Permission.recordContribution);
    final existing = _existing();
    return ContributionFormState(
      mode: _modeFor(existing, canRecord),
      // Generated once per sheet: a failed save keeps it.
      eventId: ref.read(idGeneratorProvider)(),
      date: existing?.pendingChange?.date ??
          existing?.dateKey ??
          ref.read(currentDateKeyProvider),
      memberId: existing?.memberId ?? actor,
      amountText: _amountText(existing),
      method: existing?.pendingChange?.method ?? existing?.method,
    );
  }

  /// Members are locked to themselves when asking; a manager picks anyone
  /// only while recording a NEW contribution.
  bool get canPickMember =>
      state.mode == ContributionFormMode.record ||
      state.mode == ContributionFormMode.request;

  ContributionFormMode _modeFor(Contribution? existing, bool canRecord) {
    if (existing == null) {
      return canRecord
          ? ContributionFormMode.record
          : ContributionFormMode.request;
    }
    // Editing an approved row is always a change request (D-P2-18); a pending
    // row is corrected in place by whoever holds it.
    return existing.isPending
        ? ContributionFormMode.editPending
        : ContributionFormMode.requestChange;
  }

  Contribution? _existing() {
    final id = args.contributionId;
    if (id == null) return null;
    final rows =
        ref.read(contributionsProvider(args.month)).value ??
        const <Contribution>[];
    for (final row in rows) {
      if (row.id == id) return row;
    }
    return null;
  }

  String _amountText(Contribution? row) {
    if (row == null) return '';
    final amount = row.pendingChange?.amount ?? row.amount;
    return amount.isZero ? '' : moneyEditText(amount);
  }

  void setMember(String? memberId) {
    if (!canPickMember || memberId == null || memberId.isEmpty) return;
    state = state.copyWith(memberId: memberId);
  }

  void setAmount(String text) => state = state.copyWith(
    amountText: text,
    clearAmountError: true,
    clearFailure: true,
  );

  void setMethod(ContributionMethod? method) => state = method == null
      ? state.copyWith(clearMethod: true)
      : state.copyWith(method: method);

  void setDate(DateKey date) => state = state.copyWith(date: date);

  /// Parses the amount and runs the mode's use case.
  ///
  /// Returns the saved row, or `null`; the reason is in `state.failure` /
  /// `state.amountError`.  A second tap while [ContributionFormState.saving]
  /// is ignored, so one intent is one write.
  Future<Contribution?> submit() async {
    if (state.saving) return null;
    final familyId = ref.read(currentFamilyIdProvider);
    final actor = ref.read(currentUidProvider);
    if (familyId == null || actor == null) return null;

    final parsed = Money.parse(state.amountText);
    final parseFailure = parsed.failureOrNull;
    if (parseFailure != null) {
      state = state.copyWith(amountError: _codeOf(parseFailure));
      return null;
    }

    state = state.copyWith(saving: true, clearFailure: true);
    final result = await _run(
      familyId: familyId,
      actorUid: actor,
      amount: parsed.valueOrNull!,
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      state = state.copyWith(saving: false, failure: failure);
      return null;
    }
    state = state.copyWith(saving: false, done: true);
    return result.valueOrNull;
  }

  /// `RecordOpeningBalance` (the "Set up the fund" card).  Returns the failure
  /// for the caller to show, or `null` when it saved and the sheet can close.
  Future<AppFailure?> saveOpening() async {
    if (state.saving) return null;
    final familyId = ref.read(currentFamilyIdProvider);
    final actor = ref.read(currentUidProvider);
    if (familyId == null || actor == null) return null;

    final parsed = Money.parse(state.amountText);
    final parseFailure = parsed.failureOrNull;
    if (parseFailure != null) {
      state = state.copyWith(amountError: _codeOf(parseFailure));
      return null;
    }

    state = state.copyWith(saving: true, clearFailure: true);
    final result = await ref.read(recordOpeningBalanceProvider)(
      actorUid: actor,
      familyId: familyId,
      startMonth: state.date.monthKey,
      amount: parsed.valueOrNull!,
      eventId: state.eventId,
    );
    final failure = result.failureOrNull;
    state = failure == null
        ? state.copyWith(saving: false, done: true)
        : state.copyWith(saving: false, failure: failure);
    return failure;
  }

  Future<Result<Contribution>> _run({
    required String familyId,
    required String actorUid,
    required Money amount,
  }) {
    final memberId = state.memberId ?? actorUid;
    final id = args.contributionId ?? '';
    switch (state.mode) {
      case ContributionFormMode.record:
        return ref.read(recordContributionProvider)(
          actorUid: actorUid,
          familyId: familyId,
          memberId: memberId,
          amount: amount,
          date: state.date,
          method: state.method,
          eventId: state.eventId,
        );
      case ContributionFormMode.request:
        return ref.read(requestContributionProvider)(
          actorUid: actorUid,
          familyId: familyId,
          memberId: actorUid,
          amount: amount,
          date: state.date,
          method: state.method,
          eventId: state.eventId,
        );
      case ContributionFormMode.editPending:
        return ref.read(editPendingContributionProvider)(
          actorUid: actorUid,
          familyId: familyId,
          contributionId: id,
          amount: amount,
          date: state.date,
          method: state.method,
          eventId: state.eventId,
        );
      case ContributionFormMode.requestChange:
        return ref.read(requestContributionChangeProvider)(
          actorUid: actorUid,
          familyId: familyId,
          contributionId: id,
          amount: amount,
          date: state.date,
          method: state.method,
          eventId: state.eventId,
        );
    }
  }

  /// A stable code for the sheet's amount error; anything unreadable is
  /// `invalid_amount`, and an empty field says it needs a value.
  static String _codeOf(AppFailure failure) => switch (failure) {
    Validation(code: 'empty') => 'required',
    Validation(code: 'negative') => 'negative',
    Validation(code: 'too_many_decimals') => 'too_many_decimals',
    Validation(code: 'too_large') => 'too_large',
    Validation() => 'invalid_amount',
    _ => 'invalid_amount',
  };
}
