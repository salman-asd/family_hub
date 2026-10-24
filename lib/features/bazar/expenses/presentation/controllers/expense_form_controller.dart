import 'dart:async';

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/bazar/expenses/domain/amount_input.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_draft.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_prefill.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_setters.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_state.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fields the form can show an inline error under.
const Set<String> expenseFormFields = <String>{
  'itemName',
  'categoryId',
  'dateKey',
  'paidByMemberId',
  'shop',
  'note',
  'total',
  'qty',
  'unit',
  'unitPrice',
};

/// One Add/Edit expense form.  Auto-disposed with its screen.
final expenseFormProvider = NotifierProvider.autoDispose
    .family<ExpenseFormController, ExpenseFormState, ExpenseFormArgs>(
      ExpenseFormController.new,
    );

/// The live amount of a form: calculated, typed or not known yet.
extension ExpenseFormAmount on ExpenseFormState {
  AmountInput get amount => readAmountInput(
    qtyText: qtyText,
    unit: unit,
    unitPriceText: unitPriceText,
    totalText: totalText,
    strict: false,
  );
}

class ExpenseFormController extends ExpenseFormSetters {
  ExpenseFormController(this.args);

  final ExpenseFormArgs args;

  @override
  ExpenseFormState build() {
    final newId = ref.read(idGeneratorProvider);
    final editingId = args.editingId;
    final initial = ExpenseFormState(
      expenseId: editingId ?? newId(),
      eventId: newId(),
      newItemId: newId(),
      date: ref.read(currentDateKeyProvider),
      editing: editingId != null,
      load: editingId == null
          ? ExpenseFormLoad.ready
          : ExpenseFormLoad.loading,
      paidByMemberId: ref.read(currentUidProvider),
    );
    if (editingId != null) unawaited(Future<void>.microtask(_loadForEdit));
    return initial;
  }

  // ── Saving ──────────────────────────────────────────────────────────────

  /// Validates, checks for a duplicate (new expenses only) and saves.  Returns
  /// `null` when nothing was saved; the reason is in the state.
  Future<ExpenseSaveOutcome?> save({required bool addAnother}) =>
      _save(addAnother: addAnother, checkDuplicate: !state.editing);

  /// Saves after the user chose "Save anyway" on the duplicate sheet.
  Future<ExpenseSaveOutcome?> saveConfirmed({required bool addAnother}) =>
      _save(addAnother: addAnother, checkDuplicate: false);

  Future<ExpenseSaveOutcome?> _save({
    required bool addAnother,
    required bool checkDuplicate,
  }) async {
    if (state.saving || state.load != ExpenseFormLoad.ready) return null;
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (familyId == null || uid == null) {
      state = state.copyWith(failure: const PermissionDenied());
      return null;
    }

    final amount = readAmountInput(
      qtyText: state.qtyText,
      unit: state.unit,
      unitPriceText: state.unitPriceText,
      totalText: state.totalText,
    );
    final errors = <String, String>{
      ...expenseContentErrors(state, today: ref.read(currentDateKeyProvider)),
      ...amount.errors,
    };
    final total = amount.total;
    if (errors.isNotEmpty || total == null) {
      state = state.copyWith(fieldErrors: errors, failure: null);
      return null;
    }

    final draft = expenseDraftOf(state, amount);
    state = state.copyWith(
      saving: true,
      fieldErrors: const <String, String>{},
      failure: null,
      duplicate: null,
    );

    if (checkDuplicate) {
      // A failed duplicate check never blocks saving: it is only a warning.
      final found = await ref.read(checkDuplicateProvider)(
        familyId: familyId,
        draft: draft,
        total: total,
        actorUid: uid,
      );
      if (!ref.mounted) return null;
      final warning = found.valueOrNull;
      if (warning != null) {
        state = state.copyWith(saving: false, duplicate: warning);
        return null;
      }
    }

    final Result<Expense> result = state.editing
        ? await ref.read(updateExpenseProvider)(
            actorUid: uid,
            familyId: familyId,
            expenseId: state.expenseId,
            draft: draft,
            eventId: state.eventId,
          )
        : await ref.read(addExpenseProvider)(
            actorUid: uid,
            familyId: familyId,
            draft: draft,
            id: state.expenseId,
            eventId: state.eventId,
            newItemId: state.newItemId,
          );
    if (!ref.mounted) return null;

    final failure = result.failureOrNull;
    if (failure != null) {
      state = _failed(failure);
      return null;
    }

    final expense = result.valueOrNull!;
    // On success the screen closes, so the form stays busy: a second tap on
    // Save can no longer repeat the write.
    state = addAnother ? _resetForAnother() : state;
    return ExpenseSaveOutcome(expense: expense, addAnother: addAnother);
  }

  /// A failure about one field shows under it; any other shows as a banner.
  ExpenseFormState _failed(AppFailure failure) {
    if (failure is Validation && expenseFormFields.contains(failure.field)) {
      return state.copyWith(
        saving: false,
        fieldErrors: <String, String>{failure.field: failure.code},
        failure: null,
      );
    }
    return state.copyWith(
      saving: false,
      fieldErrors: const <String, String>{},
      failure: failure,
    );
  }

  /// "Save & add another": keeps date, shop, funding and payer; new ids.
  ExpenseFormState _resetForAnother() {
    final newId = ref.read(idGeneratorProvider);
    return ExpenseFormState(
      expenseId: newId(),
      eventId: newId(),
      newItemId: newId(),
      date: state.date,
      shop: state.shop,
      funding: state.funding,
      paidByMemberId: state.paidByMemberId,
    );
  }

  Future<void> _loadForEdit() async {
    final familyId = ref.read(currentFamilyIdProvider);
    if (familyId == null) {
      state = state.copyWith(
        load: ExpenseFormLoad.failed,
        failure: const PermissionDenied(),
      );
      return;
    }
    final result = await ref
        .read(expenseRepositoryProvider)
        .getExpense(familyId, state.expenseId);
    if (!ref.mounted) return;

    final failure = result.failureOrNull;
    final expense = result.valueOrNull;
    if (failure != null || expense == null || expense.isDeleted) {
      state = state.copyWith(
        load: ExpenseFormLoad.failed,
        failure:
            failure ??
            (expense == null
                ? const NotFound(entity: 'expense')
                : const Conflict(code: 'expense_deleted')),
      );
      return;
    }
    final item = ref.read(catalogIndexProvider).itemsById[expense.itemId];
    state = expenseFormFromExpense(
      expense,
      eventId: state.eventId,
      newItemId: state.newItemId,
      item: item,
    );
  }
}
