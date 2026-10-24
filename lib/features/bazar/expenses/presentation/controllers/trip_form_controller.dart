import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_draft.dart';
import 'package:family_hub/features/bazar/expenses/domain/trip.dart';
import 'package:family_hub/features/bazar/expenses/domain/trip_limits.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_state.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Object _unset = Object();

/// One line of a trip before it is saved.  [id] is fixed when the line is
/// created, so a retried save rewrites the same expense documents.
final class TripLineDraft {
  const TripLineDraft({
    required this.id,
    this.itemId,
    required this.itemName,
    required this.categoryId,
    this.qty,
    this.unit,
    this.unitPrice,
    this.typedTotal,
    required this.total,
    this.rememberItem = false,
  });

  final String id;
  final String? itemId;
  final String itemName;
  final String categoryId;
  final Quantity? qty;
  final Unit? unit;
  final Money? unitPrice;
  final Money? typedTotal;

  /// The amount the line will be saved with (calculated or typed).
  final Money total;
  final bool rememberItem;

  ExpenseDraft toDraft(DateKey date) => ExpenseDraft(
    dateKey: date,
    itemId: itemId,
    itemName: itemName,
    categoryId: categoryId,
    qty: qty,
    unit: unit,
    unitPrice: unitPrice,
    typedTotal: typedTotal,
    rememberItem: rememberItem,
  );
}

/// The trip header, its lines and the progress of the save.
final class TripFormState {
  const TripFormState({
    required this.tripId,
    required this.eventId,
    required this.date,
    this.shop = '',
    this.funding = FundingChoice.fundPool,
    this.paidByMemberId,
    this.lines = const <TripLineDraft>[],
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.saving = false,
  });

  final String tripId;
  final String eventId;
  final DateKey date;
  final String shop;
  final FundingChoice funding;
  final String? paidByMemberId;
  final List<TripLineDraft> lines;
  final Map<String, String> fieldErrors;
  final AppFailure? failure;
  final bool saving;

  Money get total => Money.sum(lines.map((line) => line.total));

  bool get atLineLimit => lines.length >= kMaxTripLines;

  TripFormState copyWith({
    DateKey? date,
    String? shop,
    FundingChoice? funding,
    Object? paidByMemberId = _unset,
    List<TripLineDraft>? lines,
    Map<String, String>? fieldErrors,
    Object? failure = _unset,
    bool? saving,
  }) => TripFormState(
    tripId: tripId,
    eventId: eventId,
    date: date ?? this.date,
    shop: shop ?? this.shop,
    funding: funding ?? this.funding,
    paidByMemberId: identical(paidByMemberId, _unset)
        ? this.paidByMemberId
        : paidByMemberId as String?,
    lines: lines ?? this.lines,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    failure: identical(failure, _unset) ? this.failure : failure as AppFailure?,
    saving: saving ?? this.saving,
  );
}

/// One trip form, auto-disposed with its screen.
final tripFormProvider =
    NotifierProvider.autoDispose<TripFormController, TripFormState>(
      TripFormController.new,
    );

class TripFormController extends Notifier<TripFormState> {
  @override
  TripFormState build() {
    final newId = ref.read(idGeneratorProvider);
    return TripFormState(
      tripId: newId(),
      eventId: newId(),
      date: ref.read(currentDateKeyProvider),
      paidByMemberId: ref.read(currentUidProvider),
    );
  }

  /// A fresh id for a new line (the sheet asks before the line exists).
  String newLineId() => ref.read(idGeneratorProvider)();

  void setDate(DateKey date) {
    if (date.isAfter(ref.read(currentDateKeyProvider))) {
      state = state.copyWith(
        fieldErrors: const <String, String>{'dateKey': 'future_date'},
      );
      return;
    }
    state = state.copyWith(date: date, fieldErrors: const <String, String>{});
  }

  void setShop(String text) => state = state.copyWith(shop: text);

  void setFunding(FundingChoice choice) => state = state.copyWith(
    funding: choice,
    paidByMemberId: choice.needsPayer
        ? (state.paidByMemberId ?? ref.read(currentUidProvider))
        : state.paidByMemberId,
  );

  void setPaidBy(String? memberId) =>
      state = state.copyWith(paidByMemberId: memberId);

  /// Adds a line; `false` when the trip is already at the 40-line cap.
  bool addLine(TripLineDraft line) {
    if (state.atLineLimit) return false;
    state = state.copyWith(
      lines: <TripLineDraft>[...state.lines, line],
      failure: null,
    );
    return true;
  }

  void updateLine(int index, TripLineDraft line) {
    if (index < 0 || index >= state.lines.length) return;
    final next = <TripLineDraft>[...state.lines];
    next[index] = line;
    state = state.copyWith(lines: next);
  }

  /// Removes a line and returns it so the screen can offer Undo.
  TripLineDraft? removeLine(int index) {
    if (index < 0 || index >= state.lines.length) return null;
    final next = <TripLineDraft>[...state.lines];
    final removed = next.removeAt(index);
    state = state.copyWith(lines: next);
    return removed;
  }

  /// Puts a removed line back where it was (Undo).
  void insertLine(int index, TripLineDraft line) {
    if (state.atLineLimit) return;
    final next = <TripLineDraft>[...state.lines];
    next.insert(index.clamp(0, next.length), line);
    state = state.copyWith(lines: next);
  }

  /// Saves the whole trip in one batch; returns it, or `null` and the reason
  /// in the state.  Stays busy on success because the screen closes.
  Future<Trip?> save() async {
    if (state.saving || state.lines.isEmpty) return null;
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (familyId == null || uid == null) {
      state = state.copyWith(failure: const PermissionDenied());
      return null;
    }
    if (state.funding.needsPayer && (state.paidByMemberId ?? '').isEmpty) {
      state = state.copyWith(
        fieldErrors: const <String, String>{
          'paidByMemberId': 'member_required',
        },
      );
      return null;
    }

    state = state.copyWith(
      saving: true,
      failure: null,
      fieldErrors: const <String, String>{},
    );
    final header = TripDraft(
      dateKey: state.date,
      shop: state.shop,
      funding: state.funding.source,
      paidByMemberId: state.funding.needsPayer ? state.paidByMemberId : null,
      reimbursable: state.funding.reimbursable,
    );
    final result = await ref.read(addBazarTripProvider)(
      actorUid: uid,
      familyId: familyId,
      header: header,
      lines: <ExpenseDraft>[
        for (final line in state.lines) line.toDraft(state.date),
      ],
      tripId: state.tripId,
      lineIds: <String>[for (final line in state.lines) line.id],
      eventId: state.eventId,
    );
    if (!ref.mounted) return null;

    final failure = result.failureOrNull;
    if (failure != null) {
      state = state.copyWith(saving: false, failure: failure);
      return null;
    }
    return result.valueOrNull;
  }
}
