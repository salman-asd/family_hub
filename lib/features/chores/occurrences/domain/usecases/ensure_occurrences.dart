import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/duty_groups/domain/duty_group_repository.dart';
import 'package:family_hub/features/chores/occurrences/domain/generation_plan.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_draft.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_repository.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/drafts_for.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Materializes the next part of the generation horizon (P3-12, D-P3-10).
///
/// The run is RESUMABLE and safe to repeat: the marker is advanced only after
/// the last chunk, existing ids are dropped before a write (a create on an
/// existing id would be an update for the rules), and every id is
/// deterministic. A second device that raced the same range loses the conflict,
/// re-reads the ids and retries once; a second failure ends the run with
/// `Conflict('concurrent_edit')` and the next app open continues.
///
/// INTEGRITY write: the occurrences and the marker must reach the server, so
/// the repository probes it and an offline run fails fast with `Network`.
class EnsureOccurrences {
  const EnsureOccurrences({
    required this._occurrences,
    required this._markers,
    required this._templates,
    required this._dutyGroups,
    required this._settings,
    required this._families,
    required this._dateKeys,
    required this._clock,
    this._newId = randomId,
  });

  final OccurrenceRepository _occurrences;
  final GenerationMarkerRepository _markers;
  final TemplateRepository _templates;
  final DutyGroupRepository _dutyGroups;
  final ChoreSettingsRepository _settings;
  final FamilyRepository _families;
  final FamilyDateKeys _dateKeys;
  final Clock _clock;

  /// One id per audit entry, drawn once per chunk (B-10).
  final IdGenerator _newId;

  Future<Result<GenerationOutcome>> call({
    required String familyId,
    required String actorUid,
    required DateKey today,
    AvailabilityIndex availabilityIndex = AvailabilityIndex.empty,
  }) async {
    final permitted = await requireActiveMember(
      _families,
      familyId: familyId,
      actorUid: actorUid,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<GenerationOutcome>(denied);

    final loadedSettings = await _settings.get(familyId);
    final settingsFailure = loadedSettings.failureOrNull;
    if (settingsFailure != null) {
      return Failure<GenerationOutcome>(settingsFailure);
    }
    final settings = loadedSettings.valueOrNull!;
    final target = today.addDays(settings.generationHorizonDays);

    final readMarker = await _markers.readThrough(familyId);
    final markerFailure = readMarker.failureOrNull;
    if (markerFailure != null) {
      return Failure<GenerationOutcome>(markerFailure);
    }
    final through = readMarker.valueOrNull ?? today.addDays(-1);
    if (!through.isBefore(target)) {
      return Success<GenerationOutcome>(GenerationOutcome(through: through));
    }

    final listed = await _templates.list(familyId);
    final listFailure = listed.failureOrNull;
    if (listFailure != null) return Failure<GenerationOutcome>(listFailure);
    final generating = <ChoreTemplate>[
      for (final record in listed.valueOrNull ?? const <TemplateRecord>[])
        if (record.template.isGenerating) record.template,
    ];

    final range = DateKeyRange(through.addDays(1), target);
    if (generating.isEmpty) {
      return _advance(familyId, actorUid, target);
    }

    final built = await draftsFor(
      familyId: familyId,
      templates: generating,
      range: range,
      dutyGroups: _dutyGroups,
      settings: _settings,
      families: _families,
      dateKeys: _dateKeys,
      availabilityIndex: availabilityIndex,
    );
    final builtFailure = built.failureOrNull;
    if (builtFailure != null) return Failure<GenerationOutcome>(builtFailure);
    final drafts = built.valueOrNull!;

    final existing = await _occurrences.idsInRange(
      familyId,
      from: range.start,
      to: range.end,
    );
    final existingFailure = existing.failureOrNull;
    if (existingFailure != null) {
      return Failure<GenerationOutcome>(existingFailure);
    }
    final known = existing.valueOrNull!.toSet();
    final missing = <OccurrenceDraft>[
      for (final draft in drafts)
        if (!known.contains(draft.id)) draft,
    ];

    final at = _clock.nowUtc();
    var created = 0;
    var chunks = 0;
    for (final chunk in chunksOf(missing)) {
      final written = await _writeChunk(
        familyId: familyId,
        actorUid: actorUid,
        at: at,
        chunk: chunk,
      );
      final writeFailure = written.failureOrNull;
      if (writeFailure != null) {
        return Failure<GenerationOutcome>(writeFailure);
      }
      created += written.valueOrNull!;
      if (written.valueOrNull! > 0) chunks++;
    }

    final advanced = await _advance(familyId, actorUid, target);
    final advanceFailure = advanced.failureOrNull;
    if (advanceFailure != null) {
      return Failure<GenerationOutcome>(advanceFailure);
    }
    return Success<GenerationOutcome>(
      GenerationOutcome(created: created, chunks: chunks, through: target),
    );
  }

  Future<Result<GenerationOutcome>> _advance(
    String familyId,
    String actorUid,
    DateKey target,
  ) async {
    final written = await _markers.writeThrough(
      familyId,
      target,
      actorId: actorUid,
    );
    final failure = written.failureOrNull;
    if (failure != null) return Failure<GenerationOutcome>(failure);
    return Success<GenerationOutcome>(GenerationOutcome(through: target));
  }

  /// Stages one chunk, retrying ONCE after re-reading the ids when the first
  /// attempt fails with a [Conflict] OR a [PermissionDenied] (B-07).
  ///
  /// A create on an id that another device wrote in the meantime is an UPDATE
  /// for the rules, which deny it; `guardWrite` reports that as
  /// `PermissionDenied`, never as `Conflict`. A real denial simply fails the
  /// same way on the retry and is returned as it is. Any other failure
  /// (`Network`, ...) is not a race and is not retried.
  Future<Result<int>> _writeChunk({
    required String familyId,
    required String actorUid,
    required DateTime at,
    required List<OccurrenceDraft> chunk,
  }) async {
    // ONE audit id per chunk, reused by the retry: the first attempt failed,
    // so nothing was written under it (B-10).
    final auditId = _newId();
    final first = await _occurrences.stageIntegrity(
      familyId,
      _plan(
        familyId: familyId,
        actorUid: actorUid,
        at: at,
        drafts: chunk,
        auditId: auditId,
      ),
    );
    final failure = first.failureOrNull;
    if (failure == null) return Success<int>(chunk.length);
    if (failure is! Conflict && failure is! PermissionDenied) {
      return Failure<int>(failure);
    }

    final fresh = await _occurrences.idsInRange(
      familyId,
      from: _firstDate(chunk),
      to: _lastDate(chunk),
    );
    final readFailure = fresh.failureOrNull;
    if (readFailure != null) return Failure<int>(readFailure);
    final known = fresh.valueOrNull!.toSet();
    final remaining = <OccurrenceDraft>[
      for (final draft in chunk)
        if (!known.contains(draft.id)) draft,
    ];
    if (remaining.isEmpty) return const Success<int>(0);

    final retry = await _occurrences.stageIntegrity(
      familyId,
      _plan(
        familyId: familyId,
        actorUid: actorUid,
        at: at,
        drafts: remaining,
        auditId: auditId,
      ),
    );
    final retryFailure = retry.failureOrNull;
    if (retryFailure != null) {
      return Failure<int>(
        retryFailure is Conflict
            ? const Conflict(code: 'concurrent_edit')
            : retryFailure,
      );
    }
    return Success<int>(remaining.length);
  }

  OccurrenceWritePlan _plan({
    required String familyId,
    required String actorUid,
    required DateTime at,
    required List<OccurrenceDraft> drafts,
    required String auditId,
  }) => OccurrenceWritePlan(
    actorId: actorUid,
    at: at,
    creates: drafts,
    audits: <NewAudit>[
      NewAudit(
        id: auditId,
        type: AuditEventType.choresOccurrencesGenerated,
        refType: AuditRefType.choreSettings,
        refId: familyId,
        params: <String, String>{
          'from': _firstDate(drafts).toString(),
          'to': _lastDate(drafts).toString(),
          'count': '${drafts.length}',
        },
      ),
    ],
  );

  static DateKey _firstDate(List<OccurrenceDraft> drafts) => drafts
      .map((draft) => draft.dateKey)
      .reduce((a, b) => a.isBefore(b) ? a : b);

  static DateKey _lastDate(List<OccurrenceDraft> drafts) => drafts
      .map((draft) => draft.dateKey)
      .reduce((a, b) => a.isAfter(b) ? a : b);
}
