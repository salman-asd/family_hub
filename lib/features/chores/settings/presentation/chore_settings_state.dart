import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';

/// The parts of the settings page that have their own "Reset to defaults".
enum ChoreSettingsSection {
  calendar,
  generation,
  catalogs,
  policies,
  houseRules,
}

/// What the chore settings page holds while it is open (P3-17).
///
/// [draft], [policy] and [completeForOthers] are what the user is editing; the
/// `saved*` fields are what the server has, so "unsaved changes" is one value
/// comparison per field.
final class ChoreSettingsFormState {
  const ChoreSettingsFormState({
    required this.draft,
    required this.saved,
    required this.policy,
    required this.savedPolicy,
    required this.completeForOthers,
    required this.savedCompleteForOthers,
    this.saving = false,
    this.failure,
    this.justSaved = false,
  });

  final ChoreSettings draft;
  final ChoreSettings saved;
  final AbsencePolicy policy;
  final AbsencePolicy savedPolicy;
  final bool completeForOthers;
  final bool savedCompleteForOthers;
  final bool saving;

  /// The last save failure; shown inline, never rolled into a silent retry.
  final AppFailure? failure;

  /// True right after a successful save (a snackbar shows once).
  final bool justSaved;

  bool get isDirty =>
      draft != saved ||
      policy != savedPolicy ||
      completeForOthers != savedCompleteForOthers;

  /// True when the failure is "no connection": the page shows the dedicated
  /// "needs internet" text because settings writes need the server.
  bool get needsInternet => failure is Network;

  ChoreSettingsFormState copyWith({
    ChoreSettings? draft,
    ChoreSettings? saved,
    AbsencePolicy? policy,
    AbsencePolicy? savedPolicy,
    bool? completeForOthers,
    bool? savedCompleteForOthers,
    bool? saving,
    AppFailure? failure,
    bool? justSaved,
    bool clearFailure = false,
  }) => ChoreSettingsFormState(
    draft: draft ?? this.draft,
    saved: saved ?? this.saved,
    policy: policy ?? this.policy,
    savedPolicy: savedPolicy ?? this.savedPolicy,
    completeForOthers: completeForOthers ?? this.completeForOthers,
    savedCompleteForOthers:
        savedCompleteForOthers ?? this.savedCompleteForOthers,
    saving: saving ?? this.saving,
    failure: clearFailure ? null : (failure ?? this.failure),
    justSaved: justSaved ?? this.justSaved,
  );
}
