import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_repository.dart';
import 'package:family_hub/features/chores/templates/domain/usecases/archive_template.dart';
import 'package:family_hub/features/chores/templates/domain/usecases/create_template.dart';
import 'package:family_hub/features/chores/templates/domain/usecases/duplicate_template.dart';
import 'package:family_hub/features/chores/templates/domain/usecases/pause_template.dart';
import 'package:family_hub/features/chores/templates/domain/usecases/resume_template.dart';
import 'package:family_hub/features/chores/templates/domain/usecases/update_template.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests (same pattern as Bazar).
final templateRepositoryProvider = Provider<TemplateRepository>(
  (ref) => throw UnimplementedError(
    'templateRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// The live `choreTemplates` list, in `sortOrder` order.
///
/// ONE listener for the whole feature: the calendar, the editor and the manage
/// hub all read this list and filter in memory (D-P3-8 discipline), so opening
/// a third screen never adds a fourth Firestore listener.
final _templatesStreamProvider = StreamProvider<List<TemplateRecord>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(const <TemplateRecord>[]);
  return ref.watch(templateRepositoryProvider).watch(familyId);
});

/// Every template (including paused and archived), synchronously.
final templatesProvider = Provider<List<TemplateRecord>>(
  (ref) =>
      ref.watch(_templatesStreamProvider).value ?? const <TemplateRecord>[],
);

/// True when the listener hit [kMaxChoreTemplates]: the list is incomplete and
/// a screen must say so instead of silently hiding templates.
final templatesTruncatedProvider = Provider<bool>(
  (ref) => ref.watch(templatesProvider).length >= kMaxChoreTemplates,
);

/// `id -> template`, so a screen holding an id never re-scans the list.
final templateIndexProvider = Provider<Map<String, ChoreTemplate>>((ref) {
  final templates = ref.watch(templatesProvider);
  return <String, ChoreTemplate>{
    for (final record in templates) record.template.id: record.template,
  };
});

/// Ids whose stored schedule this build cannot read ("invalid schedule").
final invalidScheduleIdsProvider = Provider<Set<String>>(
  (ref) => <String>{
    for (final record in ref.watch(templatesProvider))
      if (record.invalidSchedule) record.template.id,
  },
);

/// One template by id; null when it does not exist (or is not loaded yet).
final templateProvider = Provider.family<ChoreTemplate?, String>(
  (ref, id) => ref.watch(templateIndexProvider)[id],
);

/// The templates that still generate occurrences (not paused, not archived).
final activeTemplatesProvider = Provider<List<ChoreTemplate>>(
  (ref) => <ChoreTemplate>[
    for (final record in ref.watch(templatesProvider))
      if (record.template.isGenerating) record.template,
  ],
);

/// The templates of one chore group (`assignee`-independent: the group is the
/// template's own `groupId`).
final groupTemplatesProvider = Provider.family<List<ChoreTemplate>, String>(
  (ref, groupId) => <ChoreTemplate>[
    for (final template in ref.watch(activeTemplatesProvider))
      if (template.draft.groupId == groupId) template,
  ],
);

/// The templates that are due to be verified (their template requires it).
final verificationTemplatesProvider = Provider<Set<String>>(
  (ref) => <String>{
    for (final template in ref.watch(activeTemplatesProvider))
      if (template.draft.verification.id == 'required') template.id,
  },
);

// ── Use cases ─────────────────────────────────────────────────────────────────

final createTemplateProvider = Provider<CreateTemplate>(
  (ref) => CreateTemplate(
    templates: ref.watch(templateRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final updateTemplateProvider = Provider<UpdateTemplate>(
  (ref) => UpdateTemplate(
    templates: ref.watch(templateRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final pauseTemplateProvider = Provider<PauseTemplate>(
  (ref) => PauseTemplate(
    templates: ref.watch(templateRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final resumeTemplateProvider = Provider<ResumeTemplate>(
  (ref) => ResumeTemplate(
    templates: ref.watch(templateRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final archiveTemplateProvider = Provider<ArchiveTemplate>(
  (ref) => ArchiveTemplate(
    templates: ref.watch(templateRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final duplicateTemplateProvider = Provider<DuplicateTemplate>(
  (ref) => DuplicateTemplate(
    templates: ref.watch(templateRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);
