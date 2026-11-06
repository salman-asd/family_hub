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
import 'package:family_hub/features/chores/achievements/data/engagement_settings_mappers.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings_repository.dart';

final class FirestoreEngagementSettingsRepository
    implements EngagementSettingsRepository {
  FirestoreEngagementSettingsRepository({
    required this.tx,
    required this.clock,
    FirebaseFirestore? firestore,
    this._probe,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final TxRunner tx;
  final Clock clock;
  final FirebaseFirestore _db;
  final ServerProbe? _probe;

  @override
  Stream<EngagementSettings> watch(
    String familyId, {
    required EngagementSettings defaults,
  }) => watchKnownDoc(_db.doc(FirestorePaths.engagementSettingsDoc(familyId)))
      .map((map) => EngagementSettingsMappers.fromMap(map, defaults: defaults))
      .distinct();

  @override
  Future<Result<EngagementSettings>> get(
    String familyId, {
    required EngagementSettings defaults,
  }) => guardFirestore(() async {
    final snapshot = await _db
        .doc(FirestorePaths.engagementSettingsDoc(familyId))
        .get();
    return EngagementSettingsMappers.fromMap(
      snapshot.data(),
      defaults: defaults,
    );
  });

  @override
  Future<Result<EngagementSettings>> save(
    String familyId,
    EngagementSettings settings,
    List<AuditEvent> events,
  ) async {
    final result = await guardWrite(() async {
      final path = FirestorePaths.engagementSettingsDoc(familyId);
      final snapshot = await _db
          .doc(path)
          .get(const GetOptions(source: Source.server));
      final metadata = snapshot.exists
          ? BaseMapper.metadataFromMap(snapshot.data()!)
          : BaseMapper.createMetadata(uid: events.first.actorId, clock: clock);
      final updated = metadata.copyWith(
        updatedAt: events.first.at,
        updatedBy: events.first.actorId,
      );
      await tx.runBatch((batch) {
        batch.set(path, EngagementSettingsMappers.toMap(settings, updated));
        for (final event in events) {
          AuditWriter.write(batch, familyId, event);
        }
      });
    }, probe: _probe ?? serverProbeFor(_db, events.first.actorId));
    final failure = result.failureOrNull;
    return failure != null
        ? Failure<EngagementSettings>(failure)
        : Success<EngagementSettings>(settings);
  }
}
