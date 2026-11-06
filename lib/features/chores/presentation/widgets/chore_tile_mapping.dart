import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permission.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart'
    as domain;
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/flag_chip.dart' as chips;
import 'package:family_hub/shared/widgets/status_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The domain's flag set mapped onto the shared widget's enum.
chips.ChoreFlag sharedFlag(domain.ChoreFlag flag) => switch (flag) {
  domain.ChoreFlag.needsCover => chips.ChoreFlag.needsCover,
  domain.ChoreFlag.awaitingVerification => chips.ChoreFlag.awaitingVerification,
  domain.ChoreFlag.needsAttention => chips.ChoreFlag.needsAttention,
  domain.ChoreFlag.isProjected => chips.ChoreFlag.planned,
  domain.ChoreFlag.isCover => chips.ChoreFlag.needsCover,
  domain.ChoreFlag.hasPendingSwap => chips.ChoreFlag.swapPending,
};

/// The shared widget's status for a derived [ChoreStatus].
WidgetStatus widgetStatusOf(ChoreStatus status) => switch (status) {
  ChoreStatus.scheduled => WidgetStatus.scheduled,
  ChoreStatus.inProgress => WidgetStatus.inProgress,
  ChoreStatus.completed => WidgetStatus.completed,
  ChoreStatus.verified => WidgetStatus.verified,
  ChoreStatus.overdue => WidgetStatus.overdue,
  ChoreStatus.skipped => WidgetStatus.skipped,
};

/// The localized name of a [ChoreStatus].
String statusLabelOf(ChoreStatus status, AppLocalizations l10n) =>
    switch (status) {
      ChoreStatus.scheduled => l10n.statusScheduled,
      ChoreStatus.inProgress => l10n.statusInProgress,
      ChoreStatus.completed => l10n.statusCompleted,
      ChoreStatus.verified => l10n.statusVerified,
      ChoreStatus.overdue => l10n.statusOverdue,
      ChoreStatus.skipped => l10n.choreStatusSkipped,
    };

/// True when [item] can open the detail screen. A projected item (the
/// generator's draft, not yet written) has no document, so it is shown as
/// "planned" and stays read-only until the calendar can materialize it (U-03).
bool canOpenOccurrence(domain.ChoreItem item) => !item.isProjected;

/// True when the viewer may complete [item] (assignee, manager, or the family
/// switch) — used by a swipe action to hide what cannot work.
bool mayComplete(WidgetRef ref, domain.ChoreItem item) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return false;
  final own = item.assigneeId == uid;
  return ref.can(
    own ? Permission.completeOwnChore : Permission.completeChoreForOthers,
    ownerId: item.assigneeId,
  );
}
