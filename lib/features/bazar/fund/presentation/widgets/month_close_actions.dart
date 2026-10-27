import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/bazar/fund/presentation/widgets/reopen_month_dialog.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Close month (open) or Reopen (closed), with the confirmation the card asks
/// for.  Both writes need the server, so offline they fail with the network
/// message and change nothing.
class MonthCloseActions extends ConsumerStatefulWidget {
  const MonthCloseActions({
    required this.month,
    required this.closing,
    super.key,
  });

  final MonthKey month;
  final MonthClosing? closing;

  @override
  ConsumerState<MonthCloseActions> createState() => _MonthCloseActionsState();
}

class _MonthCloseActionsState extends ConsumerState<MonthCloseActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final closed = widget.closing?.status == MonthStatus.closed;
    return BusyButton(
      key: const ValueKey('month-close-action'),
      label: closed ? l10n.monthReopen : l10n.monthClose,
      busy: _busy,
      busyLabel: l10n.loadingSemantics,
      onPressed: closed
          ? () => _reopen()
          : () => _close(),
    );
  }

  Future<void> _close() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.monthCloseConfirmTitle),
        content: Text(l10n.monthCloseConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const ValueKey('month-close-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.monthClose),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final result = await ref.read(closeMonthProvider)(
      actorUid: ref.read(currentUidProvider) ?? '',
      familyId: ref.read(currentFamilyIdProvider) ?? '',
      month: widget.month,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    final failure = result.failureOrNull;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? l10n.monthClosedDone
              : l10n.bazarFailureMessage(failure),
        ),
      ),
    );
  }

  Future<void> _reopen() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final note = await showReopenMonthDialog(context);
    if (note == null || !mounted) return;

    setState(() => _busy = true);
    final result = await ref.read(reopenMonthProvider)(
      actorUid: ref.read(currentUidProvider) ?? '',
      familyId: ref.read(currentFamilyIdProvider) ?? '',
      month: widget.month,
      note: note,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    final failure = result.failureOrNull;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? l10n.monthReopenedDone
              : l10n.bazarFailureMessage(failure),
        ),
      ),
    );
  }
}
