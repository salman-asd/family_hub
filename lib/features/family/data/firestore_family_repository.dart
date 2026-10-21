import 'package:family_hub/features/family/data/relationship_mappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/audit_writer.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/doc_watch.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/stream_utils.dart';
import 'package:family_hub/features/family/data/family_mappers.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/family_seeder.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/relationship_catalog.dart';

/// Cloud Firestore implementation of [FamilyRepository].
///
/// Every write is a single batch through [TxRunner] (activity and audit entries
/// included).  Queries are bounded with a `limit`.
class FirestoreFamilyRepository implements FamilyRepository {
  FirestoreFamilyRepository({
    required TxRunner tx,
    required Clock clock,
    FirebaseFirestore? firestore,
  })  : _tx = tx,
        _clock = clock,
        _db = firestore ?? FirebaseFirestore.instance;

  static const int _memberLimit = 200;
  static const int _invitationLimit = 50;

  final TxRunner _tx;
  final Clock _clock;
  final FirebaseFirestore _db;

  BaseDocumentMetadata _meta(String uid) =>
      BaseMapper.createMetadata(uid: uid, clock: _clock);

  /// Administrative writes need the server (rule 16); see [guardWrite].
  ServerProbe _probe(String uid) => serverProbeFor(_db, uid);

  @override
  Future<Result<void>> createFamily({
    required Family family,
    required Member owner,
    required AuditEvent event,
    List<SeedWrite> seedWrites = const <SeedWrite>[],
  }) =>
      guardWrite(
        probe: _probe(owner.uid),
        () => _tx.runBatch((b) {
          final meta = _meta(owner.uid);
          final fid = family.id;
          b
            ..set(
              FirestorePaths.familyDoc(fid),
              FamilyMappers.familyDocMap(family, meta),
            )
            ..set(
              FirestorePaths.memberDoc(fid, owner.uid),
              FamilyMappers.memberToMap(owner, meta),
            )
            ..set(
              FirestorePaths.settingsDoc(fid, 'general'),
              FamilyMappers.generalSettingsMap(family, meta),
            )
            ..set(
              FirestorePaths.settingsDoc(fid, 'modules'),
              FamilyMappers.modulesMap(family.modules, meta),
            )
            ..set(
              FirestorePaths.settingsDoc(fid, 'permissions'),
              FamilyMappers.permissionsMap(PermissionSettings.defaults, meta),
            )
            ..set(
              FirestorePaths.settingsDoc(fid, 'relationships'),
              RelationshipMappers.relationshipsMap(RelationshipCatalog.defaults, meta),
            )
            ..set(
              FirestorePaths.settingsDoc(fid, 'rotationPolicy'),
              FamilyMappers.rotationPolicyMap(meta),
            )
            ..set(
              FirestorePaths.settingsDoc(fid, 'notificationDefaults'),
              FamilyMappers.notificationDefaultsMap(meta),
            )
            ..set(
              FirestorePaths.userDoc(owner.uid),
              {'familyId': fid},
              merge: true,
            );
          for (final w in seedWrites) {
            b.set(w.path, w.data);
          }
          AuditWriter.write(b, fid, event);
        }),
      );

  @override
  Future<Result<Invitation?>> findInvitation(String code) =>
      guardFirestore(() async {
        final snap = await _db.doc(FirestorePaths.inviteCodeDoc(code)).get();
        final data = snap.data();
        return data == null ? null : FamilyMappers.invitationFromMap(data);
      });

  @override
  Future<Result<void>> saveInvitation(
    Invitation invitation,
    AuditEvent event,
  ) =>
      guardWrite(
        probe: _probe(event.actorId),
        () => _tx.runBatch((b) {
          final data = FamilyMappers.invitationToMap(invitation);
          b
            ..set(FirestorePaths.inviteCodeDoc(invitation.code), data)
            ..set(
              FirestorePaths.invitationDoc(
                invitation.familyId,
                invitation.code,
              ),
              data,
            );
          AuditWriter.write(b, invitation.familyId, event);
        }),
      );

  @override
  Future<Result<void>> requestToJoin({
    required Invitation invitation,
    required Member member,
    required AuditEvent event,
  }) =>
      guardWrite(
        probe: _probe(member.uid),
        () => _tx.runBatch((b) {
          final fid = invitation.familyId;
          final used = FamilyMappers.invitationUsedMap(
            member.uid,
            _clock.nowUtc(),
          );
          b
            ..set(
              FirestorePaths.memberDoc(fid, member.uid),
              FamilyMappers.memberToMap(member, _meta(member.uid)),
            )
            ..set(
              FirestorePaths.userDoc(member.uid),
              {'familyId': fid},
              merge: true,
            )
            ..update(FirestorePaths.inviteCodeDoc(invitation.code), used)
            ..update(
              FirestorePaths.invitationDoc(fid, invitation.code),
              used,
            );
          AuditWriter.write(b, fid, event);
        }),
      );

  @override
  Future<Result<Membership>> getUserFamilyPointer(String uid) =>
      guardFirestore(() async {
        // Server reads only: a cached answer could say "free" while the user
        // is in a family elsewhere (rule 16 / 17).
        const server = GetOptions(source: Source.server);
        final user = await _db.doc(FirestorePaths.userDoc(uid)).get(server);
        final familyId = user.data()?['familyId'];
        if (familyId is! String || familyId.isEmpty) return Membership.none;
        final member =
            await _db.doc(FirestorePaths.memberDoc(familyId, uid)).get(server);
        final data = member.data();
        return FamilyMappers.membershipFromMember(
          familyId,
          data == null ? null : FamilyMappers.memberFromMap(data),
        );
      });

  @override
  Future<Result<void>> revokeInvitation(
    Invitation invitation,
    AuditEvent event,
  ) =>
      guardWrite(
        probe: _probe(event.actorId),
        () => _tx.runBatch((b) {
          final changes =
              FamilyMappers.invitationRevokedMap(event.actorId, event.at);
          b
            ..update(FirestorePaths.inviteCodeDoc(invitation.code), changes)
            ..update(
              FirestorePaths.invitationDoc(
                invitation.familyId,
                invitation.code,
              ),
              changes,
            );
          AuditWriter.write(b, invitation.familyId, event);
        }),
      );

  @override
  Future<Result<Member?>> getMember(String familyId, String uid) =>
      guardFirestore(() async {
        final snap = await _db.doc(FirestorePaths.memberDoc(familyId, uid)).get();
        final data = snap.data();
        return data == null ? null : FamilyMappers.memberFromMap(data);
      });

  @override
  Future<Result<List<Member>>> getMembers(String familyId) =>
      guardFirestore(() async {
        final snap = await _db
            .collection(FirestorePaths.members(familyId))
            .limit(_memberLimit)
            .get();
        return _liveMembers(snap);
      });

  @override
  Future<Result<void>> saveMembers(
    String familyId,
    List<Member> members,
    AuditEvent event, {
    List<String>? adminIds,
  }) =>
      guardWrite(
        probe: _probe(event.actorId),
        () => _tx.runBatch((b) {
          final now = _clock.nowUtc();
          for (final m in members) {
            b.update(
              FirestorePaths.memberDoc(familyId, m.uid),
              FamilyMappers.memberChangeMap(
                m,
                actorUid: event.actorId,
                now: now,
              ),
            );
          }
          // H6: keep `families/{f}.adminIds` truthful in the SAME batch.  The
          // rules require this document to change whenever the active-admin set
          // does, and re-check every listed uid against its member document.
          if (adminIds != null) {
            b.update(
              FirestorePaths.familyDoc(familyId),
              FamilyMappers.familyAdminIdsMap(
                adminIds,
                actorUid: event.actorId,
                now: now,
              ),
            );
          }
          AuditWriter.write(b, familyId, event);
        }),
      );

  @override
  Future<Result<void>> updateFamily(Family family, AuditEvent event) =>
      guardWrite(
        probe: _probe(event.actorId),
        () => _tx.runBatch((b) {
          final meta = _meta(event.actorId);
          final changes = <String, dynamic>{
            BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(event.at),
            BaseMapper.keyUpdatedBy: event.actorId,
          };
          b
            ..update(FirestorePaths.familyDoc(family.id), {
              'name': family.name,
              ...changes,
            })
            ..update(FirestorePaths.settingsDoc(family.id, 'general'), {
              'timezone': family.timezone,
              'currency': family.currency,
              ...changes,
            })
            ..set(
              FirestorePaths.settingsDoc(family.id, 'modules'),
              FamilyMappers.modulesMap(family.modules, meta),
            );
          AuditWriter.write(b, family.id, event);
        }),
      );

  @override
  Future<Result<PermissionSettings>> getPermissionSettings(String familyId) =>
      guardFirestore(() async {
        final snap = await _db
            .doc(FirestorePaths.settingsDoc(familyId, 'permissions'))
            .get();
        return FamilyMappers.permissionsFromMap(snap.data());
      });

  @override
  Future<Result<void>> updatePermissionSettings(
    String familyId,
    PermissionSettings settings,
    AuditEvent event,
  ) =>
      guardWrite(
        probe: _probe(event.actorId),
        () async {
          final path = FirestorePaths.settingsDoc(familyId, 'permissions');
          // A family created before H7 has no such document yet: create it
          // (with its metadata) instead of updating it.
          final exists = (await _db.doc(path).get()).exists;
          await _tx.runBatch((b) {
            if (exists) {
              b.update(
                path,
                FamilyMappers.permissionsChangeMap(
                  settings,
                  actorUid: event.actorId,
                  now: event.at,
                ),
              );
            } else {
              b.set(
                path,
                FamilyMappers.permissionsMap(settings, _meta(event.actorId)),
              );
            }
            AuditWriter.write(b, familyId, event);
          });
        },
      );

  @override
  Stream<PermissionSettings> watchPermissionSettings(String familyId) => _db
      .doc(FirestorePaths.settingsDoc(familyId, 'permissions'))
      .snapshots()
      .map((s) => FamilyMappers.permissionsFromMap(s.data()))
      .distinct();

  @override
  Stream<RelationshipCatalog> watchRelationshipCatalog(String familyId) => _db
      .doc(FirestorePaths.settingsDoc(familyId, 'relationships'))
      .snapshots()
      .map((s) => RelationshipMappers.relationshipsFromMap(s.data()))
      .distinct();

  @override
  Future<Result<RelationshipCatalog>> getRelationshipCatalog(String familyId) =>
      guardFirestore(() async {
        final snap = await _db
            .doc(FirestorePaths.settingsDoc(familyId, 'relationships'))
            .get();
        return RelationshipMappers.relationshipsFromMap(snap.data());
      });

  @override
  Future<Result<void>> saveRelationshipCatalog(
    String familyId,
    RelationshipCatalog catalog,
    AuditEvent event,
  ) =>
      guardWrite(
        probe: _probe(event.actorId),
        () async {
          final path = FirestorePaths.settingsDoc(familyId, 'relationships');
          // A family created before H10 has no such document yet: create it
          // (with its metadata) instead of updating it.
          final exists = (await _db.doc(path).get()).exists;
          await _tx.runBatch((b) {
            if (exists) {
              b.update(
                path,
                RelationshipMappers.relationshipsChangeMap(
                  catalog,
                  actorUid: event.actorId,
                  now: event.at,
                ),
              );
            } else {
              b.set(
                path,
                RelationshipMappers.relationshipsMap(
                  catalog,
                  _meta(event.actorId),
                ),
              );
            }
            AuditWriter.write(b, familyId, event);
          });
        },
      );

  @override
  Stream<List<Member>> watchMembers(String familyId) => _db
      .collection(FirestorePaths.members(familyId))
      .limit(_memberLimit)
      .snapshots()
      .map(_liveMembers);

  @override
  Stream<List<Invitation>> watchInvitations(String familyId) => _db
      .collection(FirestorePaths.invitations(familyId))
      .orderBy(BaseMapper.keyCreatedAt, descending: true)
      .limit(_invitationLimit)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs) FamilyMappers.invitationFromMap(d.data()),
        ],
      );

  @override
  Stream<Family?> watchFamily(String familyId) {
    // H10: three small documents followed together.  The family document is
    // the "known" one (an unknown/offline state emits nothing, rule 14); the two
    // settings documents may legitimately be missing and then use defaults.
    final family = watchKnownDoc(_db.doc(FirestorePaths.familyDoc(familyId)));
    final general = _db
        .doc(FirestorePaths.settingsDoc(familyId, 'general'))
        .snapshots()
        .map((s) => s.data());
    final modules = _db
        .doc(FirestorePaths.settingsDoc(familyId, 'modules'))
        .snapshots()
        .map((s) => s.data());
    return combineLatest3<Map<String, dynamic>?, Map<String, dynamic>?,
        Map<String, dynamic>?, Family?>(
      family,
      general,
      modules,
      (familyData, generalData, modulesData) => familyData == null
          ? null
          : FamilyMappers.familyFromDocs(
              familyId,
              family: familyData,
              general: generalData,
              modules: modulesData,
            ),
    );
  }

  List<Member> _liveMembers(QuerySnapshot<Map<String, dynamic>> snap) => [
        for (final d in snap.docs)
          if (!FamilyMappers.memberFromMap(d.data()).isRemoved)
            FamilyMappers.memberFromMap(d.data()),
      ];
}
