import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaseMapper and BaseDocumentMetadata', () {
    final fixedInstant = DateTime.utc(2026, 10, 17, 12, 0, 0);
    late FakeClock clock;
    const uid = 'user_test_123';

    setUp(() {
      clock = FakeClock(fixedInstant);
    });

    test('createMetadata generates initial timestamps and createdBy', () {
      final meta = BaseMapper.createMetadata(
        uid: uid,
        clock: clock,
        schemaVersion: 1,
      );

      expect(meta.createdAt, fixedInstant);
      expect(meta.createdBy, uid);
      expect(meta.updatedAt, fixedInstant);
      expect(meta.updatedBy, uid);
      expect(meta.schemaVersion, 1);
      expect(meta.deletedAt, isNull);
      expect(meta.deletedBy, isNull);
      expect(meta.isDeleted, isFalse);
    });

    test(
        'updateMetadata updates updatedAt and updatedBy while preserving createdAt',
        () {
      final initial = BaseMapper.createMetadata(uid: uid, clock: clock);
      clock.advance(const Duration(minutes: 15));
      const updaterUid = 'user_updater_456';

      final updated = BaseMapper.updateMetadata(
        initial,
        uid: updaterUid,
        clock: clock,
      );

      expect(updated.createdAt, fixedInstant);
      expect(updated.createdBy, uid);
      expect(updated.updatedAt, fixedInstant.add(const Duration(minutes: 15)));
      expect(updated.updatedBy, updaterUid);
      expect(updated.isDeleted, isFalse);
    });

    test(
        'softDeleteMetadata marks document as deleted with deletedAt and deletedBy',
        () {
      final initial = BaseMapper.createMetadata(uid: uid, clock: clock);
      clock.advance(const Duration(hours: 1));
      const deleterUid = 'user_admin';

      final deleted = BaseMapper.softDeleteMetadata(
        initial,
        uid: deleterUid,
        clock: clock,
      );

      expect(deleted.isDeleted, isTrue);
      expect(deleted.deletedAt, fixedInstant.add(const Duration(hours: 1)));
      expect(deleted.deletedBy, deleterUid);
      expect(deleted.updatedAt, fixedInstant.add(const Duration(hours: 1)));
      expect(deleted.updatedBy, deleterUid);
    });

    test('round-trip serialization with Firestore Timestamp', () {
      final meta = BaseDocumentMetadata(
        createdAt: DateTime.utc(2026, 10, 17, 8, 30),
        createdBy: 'uid_1',
        updatedAt: DateTime.utc(2026, 10, 17, 9, 0),
        updatedBy: 'uid_2',
        schemaVersion: 2,
        deletedAt: DateTime.utc(2026, 10, 17, 9, 30),
        deletedBy: 'uid_3',
      );

      final map = BaseMapper.metadataToMap(meta);
      expect(map[BaseMapper.keyCreatedAt], isA<Timestamp>());
      expect(map[BaseMapper.keyCreatedBy], 'uid_1');
      expect(map[BaseMapper.keyUpdatedAt], isA<Timestamp>());
      expect(map[BaseMapper.keyUpdatedBy], 'uid_2');
      expect(map[BaseMapper.keySchemaVersion], 2);
      expect(map[BaseMapper.keyDeletedAt], isA<Timestamp>());
      expect(map[BaseMapper.keyDeletedBy], 'uid_3');

      final deserialized = BaseMapper.metadataFromMap(map);
      expect(deserialized, equals(meta));
    });

    test('timestampToDateTime handles null, Timestamp, DateTime, and String',
        () {
      expect(BaseMapper.timestampToDateTime(null), isNull);

      final ts = Timestamp.fromDate(fixedInstant);
      expect(BaseMapper.timestampToDateTime(ts), fixedInstant);

      expect(BaseMapper.timestampToDateTime(fixedInstant), fixedInstant);

      expect(
        BaseMapper.timestampToDateTime('2026-10-17T12:00:00Z'),
        fixedInstant,
      );
      expect(BaseMapper.timestampToDateTime('not_a_date'), isNull);
    });
  });
}
