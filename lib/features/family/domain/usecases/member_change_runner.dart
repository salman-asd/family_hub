import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/family/domain/family_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Shared skeleton of the single-member use cases: check the actor, load the
/// members, let the use case decide the new state of the target, save it and
/// the activity/audit event in ONE batch.
class MemberChangeRunner {
  const MemberChangeRunner({
    required this.families,
    required this.clock,
    required this.newId,
  });

  final FamilyRepository families;
  final Clock clock;
  final IdGenerator newId;

  Future<Result<Member>> run({
    required String actorUid,
    required String familyId,
    required String targetUid,
    required Permission permission,
    required String eventType,
    required Result<Member> Function(Member target, List<Member> all) decide,
  }) async {
    final actor = await requirePermission(
      families,
      familyId: familyId,
      actorUid: actorUid,
      permission: permission,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<Member>(denied);

    final listed = await families.getMembers(familyId);
    final listFailure = listed.failureOrNull;
    if (listFailure != null) return Failure<Member>(listFailure);
    final all = listed.valueOrNull ?? const <Member>[];

    Member? target;
    for (final m in all) {
      if (m.uid == targetUid) target = m;
    }
    if (target == null) {
      return const Failure<Member>(NotFound(entity: 'member'));
    }

    final decided = decide(target, all);
    final decideFailure = decided.failureOrNull;
    if (decideFailure != null) return Failure<Member>(decideFailure);
    final updated = decided.valueOrNull!;

    final saved = await families.saveMembers(
      familyId,
      [updated],
      FamilyEvent(
        id: newId(),
        type: eventType,
        actorId: actorUid,
        summary: '$eventType: ${updated.fullName}',
        refType: 'member',
        refId: targetUid,
        at: clock.nowUtc(),
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<Member>(failure)
        : Success<Member>(updated);
  }
}
