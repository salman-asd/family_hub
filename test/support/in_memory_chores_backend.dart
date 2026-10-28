import 'dart:async';

import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_repository.dart';

/// In-memory `choreTemplates` for use-case tests (road map P3-07).
///
/// Later steps add their own collections here (duty groups in P3-10,
/// occurrences in P3-13, …) rather than starting a second backend, so a test
/// can exercise a flow across several repositories with one fixture.
class InMemoryChoresBackend implements TemplateRepository {
  /// `familyId -> templateId -> template`.
  final Map<String, Map<String, ChoreTemplate>> templates = {};

  final List<AuditEvent> events = <AuditEvent>[];

  /// Set to make the next [save] fail (the failure is then cleared).
  AppFailure? nextSaveFailure;

  /// Set to make the next [get] / [list] fail.
  AppFailure? nextReadFailure;

  /// Number of applied writes.
  int writes = 0;

  final Map<String, StreamController<void>> _changes = {};

  StreamController<void> _controller(String familyId) =>
      _changes.putIfAbsent(familyId, () => StreamController<void>.broadcast());

  List<ChoreTemplate> _sorted(String familyId) {
    final all = templates[familyId]?.values.toList() ?? <ChoreTemplate>[];
    all.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return all;
  }

  /// Notifies every listener of [familyId] (the repositories call this after a
  /// write; a test may call it to simulate a remote change).
  void notify(String familyId) => _controller(familyId).add(null);

  @override
  Stream<List<TemplateRecord>> watch(String familyId) async* {
    yield _records(familyId);
    await for (final _ in _controller(familyId).stream) {
      yield _records(familyId);
    }
  }

  List<TemplateRecord> _records(String familyId) => <TemplateRecord>[
    for (final template in _sorted(familyId)) TemplateRecord(template: template),
  ];

  @override
  Future<Result<List<TemplateRecord>>> list(String familyId) async {
    final failure = nextReadFailure;
    if (failure != null) {
      nextReadFailure = null;
      return Failure<List<TemplateRecord>>(failure);
    }
    return Success<List<TemplateRecord>>(_records(familyId));
  }

  @override
  Future<Result<TemplateRecord?>> get(String familyId, String templateId) async {
    final failure = nextReadFailure;
    if (failure != null) {
      nextReadFailure = null;
      return Failure<TemplateRecord?>(failure);
    }
    final template = templates[familyId]?[templateId];
    return Success<TemplateRecord?>(
      template == null ? null : TemplateRecord(template: template),
    );
  }

  @override
  Future<Result<void>> save(
    String familyId,
    ChoreTemplate template,
    AuditEvent event,
  ) async {
    final failure = nextSaveFailure;
    if (failure != null) {
      nextSaveFailure = null;
      return Failure<void>(failure);
    }
    writes++;
    (templates[familyId] ??= <String, ChoreTemplate>{})[template.id] = template;
    events.add(event);
    notify(familyId);
    return const Success<void>(null);
  }
}

