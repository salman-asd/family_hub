import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/features/chores/duty_groups/domain/duty_group_repository.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_repository.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/occurrence_action.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/chores/templates/domain/template_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';

/// Loads the occurrence and the actor a comment action is about (P3-25).
///
/// The five comment use cases all start with the same six ports as the
/// completion use cases, so they share this one loader instead of repeating
/// the wiring. A PROJECTED chore is materialized exactly like every other
/// first action on it (D-P3-6): the context carries the draft and the plan
/// creates it in the same batch.
final class CommentLoader {
  const CommentLoader({
    required this.occurrences,
    required this.templates,
    required this.dutyGroups,
    required this.choreSettings,
    required this.families,
    required this.dateKeys,
  });

  final OccurrenceRepository occurrences;
  final TemplateRepository templates;
  final DutyGroupRepository dutyGroups;
  final ChoreSettingsRepository choreSettings;
  final FamilyRepository families;
  final FamilyDateKeys dateKeys;

  Future<Result<OccurrenceContext>> load({
    required String familyId,
    required String actorUid,
    required String occurrenceId,
  }) => loadOccurrenceContext(
    occurrences: occurrences,
    templates: templates,
    dutyGroups: dutyGroups,
    settings: choreSettings,
    families: families,
    dateKeys: dateKeys,
    familyId: familyId,
    occurrenceId: occurrenceId,
    actorUid: actorUid,
  );
}
