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
import 'package:family_hub/features/bazar/settings/data/bazar_settings_mappers.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings_repository.dart';

/// Firestore implementation of [BazarSettingsRepository].
///
/// The document is `settings/bazar`; an absent document is read as defaults.
/// Saves replace the settings fields with `set(..., merge: true)` so the first
/// save creates the document, and require a server round trip.
class FirestoreBazarSettingsRepository implements BazarSettingsRepository {
  FirestoreBazarSettingsRepository({
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

  String _path(String familyId) => FirestorePaths.bazarSettingsDoc(familyId);

  @override
  Stream<BazarSettings> watch(String familyId) =>
      watchKnownDoc(_db.doc(_path(familyId)))
          .map(BazarSettingsMappers.fromMap)
          .distinct();

  @override
  Future<Result<BazarSettings>> get(String familyId) =>
      guardFirestore(() async {
        final snapshot = await _db.doc(_path(familyId)).get();
        return BazarSettingsMappers.fromMap(snapshot.data());
      });

  @override
  Future<Result<void>> save(
    String familyId,
    BazarSettings settings,
    AuditEvent event,
  ) =>
      guardWrite(probe: _probe ?? serverProbeFor(_db, event.actorId), () async {
        final path = _path(familyId);
        final snapshot = await _db.doc(path).get();
        final current = snapshot.exists
            ? BaseMapper.metadataFromMap(snapshot.data() ?? <String, dynamic>{})
            : BaseMapper.createMetadata(uid: event.actorId, clock: _clock);
        final metadata = current.copyWith(
          updatedAt: event.at,
          updatedBy: event.actorId,
        );

        await _tx.runBatch((batch) {
          batch.set(
            path,
            BazarSettingsMappers.toMap(settings, metadata),
            merge: true,
          );
          AuditWriter.write(batch, familyId, event);
        });
      });
}
