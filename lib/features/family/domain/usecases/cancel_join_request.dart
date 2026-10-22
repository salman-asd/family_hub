import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';

/// A pending person withdraws their own join request (self only).
///
/// Soft-deletes the member document with `removedAt` (the same field a
/// rejection uses), so the person returns to family choice.
class CancelJoinRequest {
  const CancelJoinRequest({
    required this._families,
    required this._clock,
    required this._newId,
  });

  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<Member>> call({
    required String actorUid,
    required String familyId,
  }) async {
    final found = await _families.getMember(familyId, actorUid);
    final findFailure = found.failureOrNull;
    if (findFailure != null) return Failure<Member>(findFailure);
    final me = found.valueOrNull;
    if (me == null || me.isRemoved) {
      return const Failure<Member>(NotFound(entity: 'member'));
    }
    if (me.status != MembershipStatus.pending) {
      return const Failure<Member>(Conflict(code: 'not_pending'));
    }

    final now = _clock.nowUtc();
    final updated = me.copyWith(removedAt: now);
    final saved = await _families.saveMembers(
      familyId,
      [updated],
      AuditEvent(
        id: _newId(),
        type: 'member.cancelled',
        actorId: actorUid,
        params: <String, String>{'memberName': me.fullName},
        refType: 'member',
        refId: actorUid,
        at: now,
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<Member>(failure)
        : Success<Member>(updated);
  }
}
