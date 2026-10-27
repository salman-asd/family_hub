import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_guards.dart';
import 'package:flutter/material.dart';

/// Asks for a reject reason (1..`kMaxRejectReason` characters).
///
/// Returns the trimmed text, or `null` when the sheet was dismissed.  The use
/// case checks the same bounds again; this only saves a round trip.
Future<String?> showRejectReasonSheet(BuildContext context) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => const RejectReasonDialog(),
  );
  final trimmed = reason?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

class RejectReasonDialog extends StatefulWidget {
  const RejectReasonDialog({super.key});

  @override
  State<RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<RejectReasonDialog> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.fundRejectReasonTitle),
      content: TextField(
        key: const ValueKey('reject-reason'),
        controller: _text,
        autofocus: true,
        maxLength: kMaxRejectReason,
        maxLines: 3,
        decoration: InputDecoration(hintText: l10n.fundRejectReasonHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const ValueKey('reject-reason-send'),
          onPressed: () => Navigator.of(context).pop(_text.text),
          child: Text(l10n.fundReject),
        ),
      ],
    );
  }
}
