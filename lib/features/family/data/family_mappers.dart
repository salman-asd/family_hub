import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/server_time.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/family_event.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/modules/module_flags.dart';

/// Pure functions between domain objects and Firestore maps.  Kept free of any
/// Firestore instance so they are unit-testable.
abstract final class FamilyMappers {
  // ── Member ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> memberToMap(
    Member m,
    BaseDocumentMetadata meta,
  ) =>
      <String, dynamic>{
        'uid': m.uid,
        'role': m.role.name,
        'status': m.status.name,
        'fullName': m.fullName,
        'nickname': m.nickname,
        'relationship': m.relationship,
        'spouseId': m.spouseId,
        'avatarKey': m.avatarKey,
        'inviteCode': m.inviteCode,
        'removedAt': BaseMapper.dateTimeToTimestamp(m.removedAt),
        'leftAt': BaseMapper.dateTimeToTimestamp(m.leftAt),
        ...BaseMapper.metadataToMap(meta),
      };

  /// Only the fields an admin action changes (merge-safe).
  static Map<String, dynamic> memberChangeMap(
    Member m, {
    required String actorUid,
    required DateTime now,
  }) =>
      <String, dynamic>{
        'role': m.role.name,
        'status': m.status.name,
        'removedAt': BaseMapper.dateTimeToTimestamp(m.removedAt),
        // Only written when set: older documents have no `leftAt`, and adding
        // a null key would count as a changed field in the security rules.
        if (m.leftAt != null)
          'leftAt': BaseMapper.dateTimeToTimestamp(m.leftAt),
        BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(now),
        BaseMapper.keyUpdatedBy: actorUid,
      };

  static Member memberFromMap(Map<String, dynamic> d) => Member(
        uid: d['uid'] as String? ?? '',
        role: MemberRole.parse(d['role'] as String?),
        status: _status(d['status'] as String?),
        fullName: d['fullName'] as String? ?? '',
        relationship: d['relationship'] as String? ?? 'other',
        nickname: d['nickname'] as String?,
        spouseId: d['spouseId'] as String?,
        avatarKey: d['avatarKey'] as String?,
        inviteCode: d['inviteCode'] as String?,
        removedAt: BaseMapper.timestampToDateTime(d['removedAt']),
        leftAt: BaseMapper.timestampToDateTime(d['leftAt']),
      );

  static MembershipStatus _status(String? v) {
    for (final s in MembershipStatus.values) {
      if (s.name == v && s != MembershipStatus.none) return s;
    }
    return MembershipStatus.pending;
  }

  /// Membership as the router sees it; a removed or missing member is `none`.
  static Membership membershipFromMember(String familyId, Member? m) {
    if (m == null || m.isRemoved) return Membership.none;
    return Membership(status: m.status, familyId: familyId, role: m.role);
  }

  // ── Invitation ────────────────────────────────────────────────────────────

  static Map<String, dynamic> invitationToMap(Invitation i) =>
      <String, dynamic>{
        'code': i.code,
        'familyId': i.familyId,
        'role': i.role.name,
        'status': i.status.name,
        'expiresAt': BaseMapper.dateTimeToTimestamp(i.expiresAt),
        'usedBy': i.usedBy,
        BaseMapper.keyCreatedAt: BaseMapper.dateTimeToTimestamp(i.createdAt),
        BaseMapper.keyCreatedBy: i.createdBy,
        BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(i.createdAt),
        BaseMapper.keyUpdatedBy: i.createdBy,
        BaseMapper.keySchemaVersion: 1,
      };

  static Invitation invitationFromMap(Map<String, dynamic> d) => Invitation(
        code: d['code'] as String? ?? '',
        familyId: d['familyId'] as String? ?? '',
        role: MemberRole.parse(d['role'] as String?),
        expiresAt: BaseMapper.timestampToDateTime(d['expiresAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        createdBy: d['createdBy'] as String? ?? '',
        createdAt: BaseMapper.timestampToDateTime(d['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        status: InvitationStatus.parse(d['status'] as String?),
        usedBy: d['usedBy'] as String?,
      );

  /// Fields changed when an invitation is revoked.
  static Map<String, dynamic> invitationRevokedMap(
    String uid,
    DateTime now,
  ) =>
      <String, dynamic>{
        'status': InvitationStatus.revoked.name,
        BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(now),
        BaseMapper.keyUpdatedBy: uid,
      };

  /// Fields changed when an invitation is consumed.
  static Map<String, dynamic> invitationUsedMap(
    String uid,
    DateTime now,
  ) =>
      <String, dynamic>{
        'status': InvitationStatus.used.name,
        'usedBy': uid,
        BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(now),
        BaseMapper.keyUpdatedBy: uid,
      };

  // ── Family and settings ───────────────────────────────────────────────────

  static Map<String, dynamic> familyDocMap(Family f, BaseDocumentMetadata m) =>
      <String, dynamic>{'name': f.name, ...BaseMapper.metadataToMap(m)};

  static Map<String, dynamic> generalSettingsMap(
    Family f,
    BaseDocumentMetadata m,
  ) =>
      <String, dynamic>{
        'timezone': f.timezone,
        'currency': f.currency,
        ...BaseMapper.metadataToMap(m),
      };

  static const List<String> moduleIds = ['chores', 'bazar'];

  static Map<String, dynamic> modulesMap(
    ModuleFlags flags,
    BaseDocumentMetadata m,
  ) =>
      <String, dynamic>{
        'flags': {for (final id in moduleIds) id: flags.isEnabled(id)},
        ...BaseMapper.metadataToMap(m),
      };

  static ModuleFlags modulesFromMap(Map<String, dynamic>? d) {
    final raw = d?['flags'];
    if (raw is! Map) return ModuleFlags.allOn;
    var flags = ModuleFlags.allOn;
    raw.forEach((key, value) {
      if (key is String && value is bool) {
        flags = flags.withFlag(key, enabled: value);
      }
    });
    return flags;
  }

  static Family familyFromDocs(
    String id, {
    Map<String, dynamic>? family,
    Map<String, dynamic>? general,
    Map<String, dynamic>? modules,
  }) =>
      Family(
        id: id,
        name: family?['name'] as String? ?? '',
        timezone: general?['timezone'] as String? ?? Family.defaultTimezone,
        currency: general?['currency'] as String? ?? Family.defaultCurrency,
        modules: modulesFromMap(modules),
      );

  /// Defaults written once when a family is created.
  static Map<String, dynamic> rotationPolicyMap(BaseDocumentMetadata m) =>
      <String, dynamic>{
        'absencePolicy': 'ask_cover',
        ...BaseMapper.metadataToMap(m),
      };

  static Map<String, dynamic> notificationDefaultsMap(
    BaseDocumentMetadata m,
  ) =>
      <String, dynamic>{
        'enabled': true,
        ...BaseMapper.metadataToMap(m),
      };

  // ── Activity / audit ──────────────────────────────────────────────────────

  static Map<String, dynamic> eventMap(FamilyEvent e) => <String, dynamic>{
        'type': e.type,
        'actorId': e.actorId,
        'summary': e.summary,
        'refType': e.refType,
        'refId': e.refId,
        'params': e.params,
        // The server clock: the rules require recordedAt == request.time.
        'recordedAt': ServerTime.instance,
        BaseMapper.keyCreatedAt: BaseMapper.dateTimeToTimestamp(e.at),
        BaseMapper.keyCreatedBy: e.actorId,
        BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(e.at),
        BaseMapper.keyUpdatedBy: e.actorId,
        BaseMapper.keySchemaVersion: 1,
      };
}
