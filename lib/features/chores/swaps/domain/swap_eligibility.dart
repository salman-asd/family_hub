import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/family/domain/member.dart';

/// Who may be asked to take a chore on [day] (P3-27): an ACTIVE member who is
/// not the requester and is not away that day. The order of [members] is kept
/// (the screen shows the family's order, never a ranking).
List<Member> eligibleRecipients({
  required List<Member> members,
  required String requesterId,
  required DateKey day,
  required AvailabilityIndex index,
}) => <Member>[
  for (final member in members)
    if (member.isActive &&
        member.uid != requesterId &&
        !index.isUnavailable(member.uid, day))
      member,
];
