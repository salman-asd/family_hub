import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';
import 'package:family_hub/features/chores/presentation/date_of_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One absence in the list (P3-27): who, which days, why, its status as icon +
/// label, and only the buttons that can work for this viewer.
class AvailabilityCard extends ConsumerWidget {
  const AvailabilityCard({
    required this.record,
    required this.memberName,
    required this.typeLabel,
    this.onApprove,
    this.onReject,
    this.onCancel,
    super.key,
  });

  final MemberAvailability record;
  final String memberName;
  final String typeLabel;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  static (IconData, String) statusOf(
    AvailabilityStatus status,
    AppLocalizations l10n,
  ) => switch (status) {
    AvailabilityStatus.pending => (
      Icons.hourglass_top_rounded,
      l10n.availabilityStatusPending,
    ),
    AvailabilityStatus.active => (
      Icons.event_busy_rounded,
      l10n.availabilityStatusActive,
    ),
    AvailabilityStatus.rejected => (
      Icons.block_rounded,
      l10n.availabilityStatusRejected,
    ),
    AvailabilityStatus.cancelled => (
      Icons.cancel_outlined,
      l10n.availabilityStatusCancelled,
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final (icon, label) = statusOf(record.status, l10n);
    final range = l10n.availabilityRangeLine(
      formatters.fullDate(dateOfKey(record.startDate)),
      formatters.fullDate(dateOfKey(record.endDate)),
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    memberName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(icon, size: 16, color: t.textSecondary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(color: t.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(range, style: TextStyle(color: t.textPrimary)),
            Text(
              '$typeLabel · ${record.reason}',
              style: TextStyle(color: t.textSecondary, fontSize: 13),
            ),
            if (onApprove != null || onReject != null || onCancel != null)
              Wrap(
                spacing: 8,
                children: [
                  if (onApprove != null)
                    TextButton.icon(
                      key: const Key('availability_approve'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(l10n.availabilityApprove),
                    ),
                  if (onReject != null)
                    TextButton.icon(
                      key: const Key('availability_reject'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(l10n.availabilityReject),
                    ),
                  if (onCancel != null)
                    TextButton.icon(
                      key: const Key('availability_cancel'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: onCancel,
                      icon: const Icon(
                        Icons.event_available_outlined,
                        size: 18,
                      ),
                      label: Text(l10n.availabilityCancel),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
