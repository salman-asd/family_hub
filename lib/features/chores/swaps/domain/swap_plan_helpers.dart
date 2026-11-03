import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/member.dart';

/// The acting member and the family's permission switches, read once.
typedef ChoreActor = ({Member member, PermissionSettings settings});

/// Loads the acting member and requires them to be ACTIVE (`PermissionDenied`
/// for a missing, pending, disabled or removed member).
Future<Result<ChoreActor>> loadActiveActor(
  FamilyRepository families,
  String familyId,
  String uid,
) async {
  final loaded = await families.getMember(familyId, uid);
  final failure = loaded.failureOrNull;
  if (failure != null) return Failure<ChoreActor>(failure);
  final member = loaded.valueOrNull;
  if (member == null || !member.isActive) {
    return const Failure<ChoreActor>(PermissionDenied());
  }
  final settings =
      (await families.getPermissionSettings(familyId)).valueOrNull ??
      PermissionSettings.defaults;
  return Success<ChoreActor>((member: member, settings: settings));
}

/// [base] with more inbox rows and audit entries (the occurrence part of a swap
/// plan is built by `OccurrenceActionWriter.planFor`, which only knows the
/// occurrence audit shape).
OccurrenceWritePlan extendPlan(
  OccurrenceWritePlan base, {
  List<NewInboxItem> inbox = const <NewInboxItem>[],
  List<NewAudit> audits = const <NewAudit>[],
}) => OccurrenceWritePlan(
  actorId: base.actorId,
  at: base.at,
  creates: base.creates,
  restores: base.restores,
  replans: base.replans,
  patches: base.patches,
  events: base.events,
  inbox: <NewInboxItem>[...base.inbox, ...inbox],
  audits: <NewAudit>[...base.audits, ...audits],
);

/// A swap audit entry (`refType` swapRequest) with a deterministic [id].
NewAudit swapAudit({
  required String type,
  required String id,
  required String requestId,
  required String name,
  required String date,
  required String from,
  required String to,
}) => NewAudit(
  id: id,
  type: type,
  refId: requestId,
  refType: AuditRefType.swapRequest,
  params: <String, String>{'name': name, 'date': date, 'from': from, 'to': to},
);

/// The managers of [members] (active, may manage the chores module).
List<Member> managersOf(List<Member> members) => <Member>[
  for (final member in members)
    if (member.isActive && member.permissionActor.isManager) member,
];
