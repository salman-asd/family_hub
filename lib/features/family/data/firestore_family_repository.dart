import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/family/data/family_mappers.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/family_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member.dart';

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

  void _writeEvent(BatchContext b, String familyId, FamilyEvent e) {
    final data = FamilyMappers.eventMap(e);
    b
      ..set(FirestorePaths.activityDoc(familyId, e.id), data)
      ..set(FirestorePaths.auditLogDoc(familyId, e.id), data);
  }

  @override
  Future<Result<void>> createFamily({
    required Family family,
    required Member owner,
    required FamilyEvent event,
  }) =>
      guardFirestore(
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
          _writeEvent(b, fid, event);
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
    FamilyEvent event,
  ) =>
      guardFirestore(
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
          _writeEvent(b, invitation.familyId, event);
        }),
      );

  @override
  Future<Result<void>> requestToJoin({
    required Invitation invitation,
    required Member member,
    required FamilyEvent event,
  }) =>
      guardFirestore(
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
          _writeEvent(b, fid, event);
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
    FamilyEvent event,
  ) =>
      guardFirestore(
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
          _writeEvent(b, familyId, event);
        }),
      );

  @override
  Future<Result<void>> updateFamily(Family family, FamilyEvent event) =>
      guardFirestore(
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
          _writeEvent(b, family.id, event);
        }),
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
    // Three small documents; re-read all of them whenever any one changes.
    final family = _db.doc(FirestorePaths.familyDoc(familyId)).snapshots();
    return family.asyncMap((snap) async {
      if (!snap.exists) return null;
      final general =
          await _db.doc(FirestorePaths.settingsDoc(familyId, 'general')).get();
      final modules =
          await _db.doc(FirestorePaths.settingsDoc(familyId, 'modules')).get();
      return FamilyMappers.familyFromDocs(
        familyId,
        family: snap.data(),
        general: general.data(),
        modules: modules.data(),
      );
    });
  }

  List<Member> _liveMembers(QuerySnapshot<Map<String, dynamic>> snap) => [
        for (final d in snap.docs)
          if (!FamilyMappers.memberFromMap(d.data()).isRemoved)
            FamilyMappers.memberFromMap(d.data()),
      ];
}
