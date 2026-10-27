import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/presentation/controllers/contribution_form_state.dart';
import 'package:family_hub/features/bazar/contributions/presentation/widgets/record_contribution_sheet.dart';
import 'package:flutter/material.dart';

/// The owner's action on their own contribution row.
///
/// A pending request can be corrected in place; an approved one can only be
/// *asked* to change (a manager decides).  Anyone who is not the owner, and
/// every manager (they use the approval list), sees nothing.
class MemberActionsButton extends StatelessWidget {
  const MemberActionsButton({
    required this.memberId,
    required this.month,
    required this.myId,
    required this.canRecord,
    required this.contributions,
    super.key,
  });

  final String memberId;
  final MonthKey month;
  final String? myId;
  final bool canRecord;
  final List<Contribution> contributions;

  @override
  Widget build(BuildContext context) {
    if (canRecord || myId == null || memberId != myId) {
      return const SizedBox.shrink();
    }
    final mine = <Contribution>[
      for (final row in contributions)
        if (row.memberId == myId && !row.isVoided) row,
    ]..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    if (mine.isEmpty) return const SizedBox.shrink();

    final latest = mine.first;
    return IconButton(
      key: const ValueKey('fund-member-edit'),
      tooltip: latest.isPending
          ? context.l10n.fundEditRequest
          : context.l10n.fundRequestChange,
      icon: Icon(latest.isPending ? Icons.edit_outlined : Icons.sync_rounded),
      onPressed: () => showContributionSheet(
        context,
        latest.isPending
            ? ContributionFormMode.editPending
            : ContributionFormMode.requestChange,
        month: month,
        contributionId: latest.id,
      ),
    );
  }
}
