import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/availability/presentation/availability_index_provider.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_items_providers.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/presentation/date_of_key.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_eligibility.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/presentation/swap_providers.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "I can't do this" (P3-27): choose WHO may take the chore, say why, send.
///
/// Only members who are active, not the requester and not away that day are
/// offered. Each shows this month's load as a small bar so a busy person is not
/// asked by accident; it is information, never a ranking. Sending is an
/// EVERYDAY write (it queues offline). Returns null when the person backed out.
extension SwapSheets on WidgetRef {
  Future<Result<Object?>?> requestSwapWithSheet(
    BuildContext context, {
    required ChoreOccurrence occurrence,
  }) async {
    final familyId = read(currentFamilyIdProvider);
    final uid = read(currentUidProvider);
    if (familyId == null || uid == null) return null;
    final eligible = eligibleRecipients(
      members: read(membersProvider).value ?? const <Member>[],
      requesterId: uid,
      day: occurrence.dateKey,
      index: read(availabilityIndexProvider),
    );
    final picked = await showModalBottomSheet<({String to, String reason})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SwapSheet(occurrence: occurrence, eligible: eligible),
    );
    if (picked == null) return null;
    final result = await read(requestSwapProvider)(
      familyId: familyId,
      actorUid: uid,
      occurrenceId: occurrence.id,
      requestId: randomId(),
      toMemberId: picked.to,
      reason: picked.reason,
    );
    final failure = result.failureOrNull;
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.choresFailureMessage(failure))),
      );
    }
    return result;
  }
}

class _SwapSheet extends ConsumerStatefulWidget {
  const _SwapSheet({required this.occurrence, required this.eligible});

  final ChoreOccurrence occurrence;
  final List<Member> eligible;

  @override
  ConsumerState<_SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends ConsumerState<_SwapSheet> {
  final TextEditingController _reason = TextEditingController();
  String? _to;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _valid =>
      _to != null &&
      _reason.text.trim().length >= SwapLimits.minReason &&
      _reason.text.trim().length <= SwapLimits.maxReason;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final month = ref.watch(monthItemsProvider(widget.occurrence.monthKey));
    final load = <String, int>{};
    for (final item in month.value?.items ?? const <ChoreItem>[]) {
      final who = item.assigneeId;
      if (who != null) load[who] = (load[who] ?? 0) + 1;
    }
    final busiest = load.values.fold<int>(1, (a, b) => b > a ? b : a);
    Member? chosen;
    for (final member in widget.eligible) {
      if (member.uid == _to) chosen = member;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.swapSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.swapSheetPerson,
              style: TextStyle(color: t.textSecondary),
            ),
            if (widget.eligible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.swapSheetNobody,
                  key: const Key('swap_nobody'),
                ),
              ),
            for (final member in widget.eligible)
              Semantics(
                selected: member.uid == _to,
                button: true,
                child: InkWell(
                  key: Key('swap_person_${member.uid}'),
                  onTap: () => setState(() => _to = member.uid),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Row(
                      children: [
                        AppAvatar(
                          id: member.uid,
                          name: member.displayName,
                          avatarKey: member.avatarKey,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.displayName),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: (load[member.uid] ?? 0) / busiest,
                                minHeight: 4,
                                semanticsLabel: l10n.swapLoadLabel(
                                  formatters.number(load[member.uid] ?? 0),
                                ),
                              ),
                              Text(
                                l10n.swapLoadLabel(
                                  formatters.number(load[member.uid] ?? 0),
                                ),
                                style: TextStyle(
                                  color: t.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (member.uid == _to)
                          Icon(Icons.check_circle_rounded, color: t.accent),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('swap_reason'),
              controller: _reason,
              maxLength: SwapLimits.maxReason,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(hintText: l10n.swapSheetReasonHint),
              onChanged: (_) => setState(() {}),
            ),
            if (chosen != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.swapSheetPreview(
                    chosen.displayName,
                    widget.occurrence.nameBn,
                    formatters.fullDate(dateOfKey(widget.occurrence.dateKey)),
                  ),
                  style: TextStyle(color: t.textSecondary, fontSize: 13),
                ),
              ),
            FilledButton.icon(
              key: const Key('swap_send'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _valid
                  ? () =>
                        Navigator.of(context)
                            .pop((to: _to!, reason: _reason.text.trim()))
                  : null,
              icon: const Icon(Icons.send_rounded),
              label: Text(l10n.swapSheetSend),
            ),
          ],
        ),
      ),
    );
  }
}
