import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/audit_writer.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/doc_watch.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/chores/settings/data/chore_settings_mappers.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';

/// Firestore implementation of [ChoreSettingsRepository].
///
/// Two documents: `settings/chores` (catalogs and preferences) and
/// `settings/rotationPolicy` (the absence policy). Both are read with a live
/// listener, an absent document reads as its default, and every save replaces
/// the fields with `set(..., merge: true)` inside a server-required batch
/// together with its audit entry.
class FirestoreChoreSettingsRepository implements ChoreSettingsRepository {
  FirestoreChoreSettingsRepository({
    required this._tx,
    required this._clock,
    this._firestore,
    this._probe,
  });

  final TxRunner _tx;
  final Clock _clock;
  final FirebaseFirestore? _firestore;
  final ServerProbe? _probe;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  String _settingsPath(String familyId) =>
      FirestorePaths.choreSettingsDoc(familyId);

  String _policyPath(String familyId) =>
      FirestorePaths.rotationPolicyDoc(familyId);

  @override
  Stream<ChoreSettings> watch(String familyId) =>
      watchKnownDoc(_db.doc(_settingsPath(familyId)))
          .map(ChoreSettingsMappers.fromMap)
          .distinct();

  @override
  Future<Result<ChoreSettings>> get(String familyId) =>
      guardFirestore(() async {
        final snapshot = await _db.doc(_settingsPath(familyId)).get();
        return ChoreSettingsMappers.fromMap(snapshot.data());
      });

  @override
  Future<Result<void>> save(
    String familyId,
    ChoreSettings settings,
    AuditEvent event,
  ) => _write(
    path: _settingsPath(familyId),
    body: (meta) => ChoreSettingsMappers.toMap(settings, meta),
    event: event,
    familyId: familyId,
  );

  @override
  Stream<AbsencePolicy> watchAbsencePolicy(String familyId) =>
      watchKnownDoc(_db.doc(_policyPath(familyId)))
          .map(ChoreSettingsMappers.absencePolicyFromMap)
          .distinct();

  @override
  Future<Result<AbsencePolicy>> getAbsencePolicy(String familyId) =>
      guardFirestore(() async {
        final snapshot = await _db.doc(_policyPath(familyId)).get();
        return ChoreSettingsMappers.absencePolicyFromMap(snapshot.data());
      });

  @override
  Future<Result<void>> saveAbsencePolicy(
    String familyId,
    AbsencePolicy policy,
    AuditEvent event,
  ) => _write(
    path: _policyPath(familyId),
    body: (meta) => ChoreSettingsMappers.absencePolicyToMap(policy, meta),
    event: event,
    familyId: familyId,
  );

  /// One write pattern for both documents: read the existing metadata (or
  /// create it), stamp `updatedAt/By`, then batch the document with its audit
  /// entry. `probe` makes the call require the server (road map 3.4).
  Future<Result<void>> _write({
    required String path,
    required Map<String, dynamic> Function(BaseDocumentMetadata meta) body,
    required AuditEvent event,
    required String familyId,
  }) =>
      guardWrite(probe: _probe ?? serverProbeFor(_db, event.actorId), () async {
        final snapshot = await _db.doc(path).get();
        final current = snapshot.exists
            ? BaseMapper.metadataFromMap(snapshot.data() ?? <String, dynamic>{})
            : BaseMapper.createMetadata(uid: event.actorId, clock: _clock);
        final metadata = current.copyWith(
          updatedAt: event.at,
          updatedBy: event.actorId,
        );

        await _tx.runBatch((batch) {
          batch.set(path, body(metadata), merge: true);
          AuditWriter.write(batch, familyId, event);
        });
      });
}
