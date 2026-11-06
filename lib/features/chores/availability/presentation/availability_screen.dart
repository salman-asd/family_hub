import 'dart:async';

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';
import 'package:family_hub/features/chores/availability/presentation/add_availability_sheet.dart';
import 'package:family_hub/features/chores/availability/presentation/availability_card.dart';
import 'package:family_hub/features/chores/availability/presentation/availability_providers.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/presentation/member_names.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Absences (P3-27): "Mine" for everybody, plus "Everyone" for managers, who
/// also approve or reject pending records. The button to add is always for the
/// viewer's OWN absence.
class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  bool _everyone = false;

  void _show(AppFailure failure) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.choresFailureMessage(failure))),
    );
  }

  Future<void> _cancel(MemberAvailability record) async {
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (familyId == null || uid == null) return;
    final result = await ref.read(cancelAvailabilityProvider)(
      familyId: familyId,
      actorUid: uid,
      availabilityId: record.id,
    );
    final failure = result.failureOrNull;
    if (failure != null) _show(failure);
  }

  Future<void> _decide(
    MemberAvailability record, {
    required bool approve,
  }) async {
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (familyId == null || uid == null) return;
    final result = await ref.read(decideAvailabilityProvider)(
      familyId: familyId,
      actorUid: uid,
      availabilityId: record.id,
      approve: approve,
    );
    var failure = result.failureOrNull;
    if (failure == null && approve) {
      failure = (await ref.read(applyAbsencePolicyProvider)(
        familyId: familyId,
        actorUid: uid,
        availabilityId: record.id,
      )).failureOrNull;
    }
    if (failure != null) _show(failure);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uid = ref.watch(currentUidProvider);
    final members = ref.watch(membersProvider).value ?? const [];
    final reasons = ref.watch(absenceReasonsProvider);
    final english = Localizations.localeOf(context).languageCode == 'en';
    final canManage = ref.can(Permission.manageAvailability);
    final records = ref.watch(availabilityProvider);

    String typeLabel(String id) {
      for (final reason in reasons) {
        if (reason.id == id) {
          return english && reason.labelEn != null
              ? reason.labelEn!
              : reason.labelBn;
        }
      }
      return id;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.availabilityTitle)),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('availability_fab'),
              onPressed: () => unawaited(
                ref.addAvailabilityWithSheet(context, memberId: uid),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.availabilityAdd),
            ),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorView(
          message: l10n.choresFailure_unknown,
          onRetry: () => ref.invalidate(availabilityProvider),
        ),
        data: (all) {
          final shown = <MemberAvailability>[
            for (final r in all)
              if (_everyone && canManage || r.memberId == uid) r,
          ]..sort((a, b) => b.startDate.compareTo(a.startDate));
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (canManage)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SegmentedButton<bool>(
                    key: const Key('availability_scope'),
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.availabilityMine),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.availabilityEveryone),
                      ),
                    ],
                    selected: {_everyone},
                    onSelectionChanged: (s) =>
                        setState(() => _everyone = s.first),
                  ),
                ),
              if (shown.isEmpty)
                EmptyState(
                  icon: Icons.event_available_outlined,
                  title: l10n.availabilityEmpty,
                ),
              for (final record in shown)
                AvailabilityCard(
                  record: record,
                  memberName: memberNameOf(
                    members,
                    record.memberId,
                    fallback: l10n.inboxSomeone,
                  ),
                  typeLabel: typeLabel(record.typeId),
                  onApprove:
                      canManage && record.status == AvailabilityStatus.pending
                      ? () => unawaited(_decide(record, approve: true))
                      : null,
                  onReject:
                      canManage && record.status == AvailabilityStatus.pending
                      ? () => unawaited(_decide(record, approve: false))
                      : null,
                  onCancel:
                      record.isLive && (record.memberId == uid || canManage)
                      ? () => unawaited(_cancel(record))
                      : null,
                ),
            ],
          );
        },
      ),
    );
  }
}
