import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/presentation/member_names.dart';
import 'package:family_hub/features/chores/rota/presentation/rota_providers.dart';
import 'package:family_hub/features/chores/rota/presentation/widgets/member_share_row.dart';
import 'package:family_hub/features/chores/rota/presentation/widgets/on_duty_strip.dart';
import 'package:family_hub/features/chores/rota/presentation/widgets/rota_matrix_view.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The rota board (P3-28): who is on duty today, each member's share of the
/// load, and a members-by-days grid, for the week or the month.
///
/// Managers always see it; members only when the family switched the workload
/// on. Every figure is a number next to its bar, and the grid shows a count plus
/// a check icon rather than a colour. Read-only: nothing here writes.
class RotaBoardScreen extends ConsumerWidget {
  const RotaBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    if (!ref.watch(rotaVisibleProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.rotaTitle)),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: l10n.rotaNoAccess,
        ),
      );
    }
    final range = ref.watch(rotaRangeProvider);
    final summary = ref.watch(rotaWorkloadProvider);
    final matrix = ref.watch(rotaMatrixProvider);
    final memberIds = ref.watch(rotaMemberIdsProvider);
    final members = ref.watch(membersProvider).value ?? const [];
    final today = ref.watch(familyDateKeysProvider).today();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rotaTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SegmentedButton<RotaRange>(
              key: const Key('rota_range'),
              segments: [
                ButtonSegment(
                  value: RotaRange.week,
                  label: Text(l10n.rotaWeek),
                ),
                ButtonSegment(
                  value: RotaRange.month,
                  label: Text(l10n.rotaMonth),
                ),
              ],
              selected: {range},
              onSelectionChanged: (s) =>
                  ref.read(rotaRangeProvider.notifier).select(s.first),
            ),
          ),
          OnDutyStrip(matrix: matrix),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.rotaShareTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (memberIds.isEmpty ||
              summary.totalPoints == 0 && matrix.unassigned.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.rotaEmpty,
                key: const Key('rota_empty'),
                style: TextStyle(color: t.textSecondary),
              ),
            ),
          for (final workload in summary.members)
            MemberShareRow(
              workload: workload,
              name: memberNameOf(
                members,
                workload.memberId,
                fallback: l10n.inboxSomeone,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.rotaMatrixTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RotaMatrixView(
              matrix: matrix,
              memberIds: memberIds,
              members: members,
              today: today,
            ),
          ),
        ],
      ),
    );
  }
}
