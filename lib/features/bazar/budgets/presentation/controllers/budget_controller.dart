import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_draft.dart';
import 'package:family_hub/features/bazar/budgets/presentation/budget_providers.dart';
import 'package:family_hub/features/bazar/expenses/domain/amount_input.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everything the budget editor holds while it is open.  Amounts stay text
/// until [BudgetController.save] reads them through the domain readers.
final class BudgetEditState {
  const BudgetEditState({
    required this.eventId,
    this.editing = false,
    this.version = 0,
    this.totalText = '',
    this.categoryTexts = const <String, String>{},
    this.lines = const <BudgetLineDraft>[],
    this.lineErrors = const <String, Map<String, String>>{},
    this.categoryErrors = const <String, String>{},
    this.totalError,
    this.saving = false,
    this.failure,
    this.createdAt,
    this.createdBy,
  });

  /// Generated once per editing session: a failed save retried reuses it, so
  /// the log gets one entry (CLAUDE.md rule 15).
  final String eventId;
  final bool editing;

  /// Bumped whenever the draft is replaced wholesale, so field widgets know to
  /// reload their text.
  final int version;
  final String totalText;
  final Map<String, String> categoryTexts;
  final List<BudgetLineDraft> lines;
  final Map<String, Map<String, String>> lineErrors;
  final Map<String, String> categoryErrors;
  final String? totalError;
  final bool saving;
  final AppFailure? failure;
  final DateTime? createdAt;
  final String? createdBy;

  BudgetEditState copyWith({
    bool? editing,
    int? version,
    String? totalText,
    Map<String, String>? categoryTexts,
    List<BudgetLineDraft>? lines,
    Map<String, Map<String, String>>? lineErrors,
    Map<String, String>? categoryErrors,
    String? totalError,
    bool clearTotalError = false,
    bool? saving,
    AppFailure? failure,
    bool clearFailure = false,
    DateTime? createdAt,
    String? createdBy,
  }) => BudgetEditState(
    eventId: eventId,
    editing: editing ?? this.editing,
    version: version ?? this.version,
    totalText: totalText ?? this.totalText,
    categoryTexts: categoryTexts ?? this.categoryTexts,
    lines: lines ?? this.lines,
    lineErrors: lineErrors ?? this.lineErrors,
    categoryErrors: categoryErrors ?? this.categoryErrors,
    totalError: clearTotalError ? null : (totalError ?? this.totalError),
    saving: saving ?? this.saving,
    failure: clearFailure ? null : (failure ?? this.failure),
    createdAt: createdAt ?? this.createdAt,
    createdBy: createdBy ?? this.createdBy,
  );
}

/// The editable draft of one month's budget.  Auto-disposed with its screen,
/// so leaving the screen (or changing month) drops an unsaved draft.
final budgetControllerProvider = NotifierProvider.autoDispose
    .family<BudgetController, BudgetEditState, MonthKey>(
      BudgetController.new,
    );

class BudgetController extends Notifier<BudgetEditState> {
  BudgetController(this.month);

  final MonthKey month;

  @override
  BudgetEditState build() =>
      BudgetEditState(eventId: ref.read(idGeneratorProvider)());

  String _newId() => ref.read(idGeneratorProvider)();

  /// Opens the editor, filled from [existing] (or empty for a new plan).
  void startEditing(Budget? existing) {
    final lines = <BudgetLineDraft>[
      if (existing != null)
        for (final line in existing.lines)
          BudgetLineDraft.fromLine(_newId(), line),
    ];
    state = BudgetEditState(
      eventId: state.eventId,
      editing: true,
      version: state.version + 1,
      totalText: existing == null || existing.totalEstimate.isZero
          ? ''
          : moneyEditText(existing.totalEstimate),
      categoryTexts: <String, String>{
        if (existing != null)
          for (final e in existing.categoryEstimates.entries)
            e.key: moneyEditText(e.value),
      },
      lines: lines,
      createdAt: existing?.createdAt,
      createdBy: existing?.createdBy,
    );
  }

  void cancel() => state = BudgetEditState(
    eventId: state.eventId,
    version: state.version + 1,
  );

  void setTotal(String text) =>
      state = state.copyWith(totalText: text, clearTotalError: true);

  void setCategory(String categoryId, String text) {
    state = state.copyWith(
      categoryTexts: <String, String>{...state.categoryTexts, categoryId: text},
      categoryErrors: <String, String>{...state.categoryErrors}
        ..remove(categoryId),
    );
  }

  void addLine() => state = state.copyWith(
    lines: <BudgetLineDraft>[...state.lines, BudgetLineDraft(id: _newId())],
  );

  void removeLine(String id) => state = state.copyWith(
    lines: <BudgetLineDraft>[
      for (final l in state.lines)
        if (l.id != id) l,
    ],
    lineErrors: <String, Map<String, String>>{...state.lineErrors}..remove(id),
  );

  void updateLine(String id, BudgetLineDraft Function(BudgetLineDraft) edit) {
    state = state.copyWith(
      lines: <BudgetLineDraft>[
        for (final l in state.lines) l.id == id ? edit(l) : l,
      ],
      lineErrors: <String, Map<String, String>>{...state.lineErrors}
        ..remove(id),
    );
  }

  /// The sum of the rows that already read cleanly (live footer).
  Money get linesTotal => Money.sum(
    readLineDrafts(state.lines).lines.map(Budget.lineEstimate),
  );

  /// Reads the draft, saves it once and closes the editor.  Returns `true` on
  /// success.  Field problems are shown inline and nothing is written.
  Future<bool> save() async {
    if (state.saving) return false;
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (familyId == null || uid == null) return false;

    final linesRead = readLineDrafts(state.lines);
    final categories = readCategoryTexts(state.categoryTexts);
    final total = readTotalText(state.totalText);
    if (!linesRead.isValid || !categories.isValid || total == null) {
      state = state.copyWith(
        lineErrors: linesRead.errors,
        categoryErrors: categories.errors,
        totalError: total == null ? 'invalid_amount' : null,
        clearTotalError: total != null,
        clearFailure: true,
      );
      return false;
    }

    state = state.copyWith(
      saving: true,
      lineErrors: const <String, Map<String, String>>{},
      categoryErrors: const <String, String>{},
      clearTotalError: true,
      clearFailure: true,
    );
    final result = await ref.read(saveBudgetProvider)(
      actorUid: uid,
      familyId: familyId,
      eventId: state.eventId,
      budget: Budget(
        month: month,
        totalEstimate: total,
        categoryEstimates: categories.estimates,
        lines: linesRead.lines,
        alertThresholds: ref.read(bazarSettingsProvider).alertThresholds,
        createdAt: state.createdAt,
        createdBy: state.createdBy,
      ),
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      state = state.copyWith(saving: false, failure: failure);
      return false;
    }
    // A new intent after this one: a fresh event id (a log entry is never
    // rewritten).
    state = BudgetEditState(eventId: _newId(), version: state.version + 1);
    return true;
  }

  /// "Copy last month": the budget stream then shows the new plan.
  Future<bool> copyLastMonth() async {
    if (state.saving) return false;
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (familyId == null || uid == null) return false;
    state = state.copyWith(saving: true, clearFailure: true);
    final result = await ref.read(copyLastMonthBudgetProvider)(
      actorUid: uid,
      familyId: familyId,
      month: month,
      eventId: state.eventId,
    );
    final failure = result.failureOrNull;
    if (failure == null) {
      state = BudgetEditState(eventId: _newId(), version: state.version + 1);
      return true;
    }
    state = state.copyWith(saving: false, failure: failure);
    return false;
  }
}
