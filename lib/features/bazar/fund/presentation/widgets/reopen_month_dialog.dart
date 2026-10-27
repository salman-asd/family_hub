import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/fund/domain/usecases/reopen_month.dart';
import 'package:flutter/material.dart';

/// Asks why a closed month is being reopened (at least [kMinReopenNote]
/// characters).  Returns the trimmed note, or `null` when dismissed.
///
/// `ReopenMonth` checks the same rule again; this only saves a round trip.
Future<String?> showReopenMonthDialog(BuildContext context) async {
  final note = await showDialog<String>(
    context: context,
    builder: (_) => const ReopenMonthDialog(),
  );
  final trimmed = note?.trim() ?? '';
  return trimmed.runes.length < kMinReopenNote ? null : trimmed;
}

class ReopenMonthDialog extends StatefulWidget {
  const ReopenMonthDialog({super.key});

  @override
  State<ReopenMonthDialog> createState() => _ReopenMonthDialogState();
}

class _ReopenMonthDialogState extends State<ReopenMonthDialog> {
  final TextEditingController _note = TextEditingController();
  bool _tooShort = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _note.text.trim();
    if (text.runes.length < kMinReopenNote) {
      setState(() => _tooShort = true);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.monthReopenNoteTitle),
      content: TextField(
        key: const ValueKey('reopen-note'),
        controller: _note,
        autofocus: true,
        maxLength: kMaxReopenNote,
        maxLines: 3,
        onChanged: (_) {
          if (_tooShort) setState(() => _tooShort = false);
        },
        decoration: InputDecoration(
          hintText: l10n.monthReopenNoteHint,
          errorText: _tooShort ? l10n.bazarErrReopenNoteRequired : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const ValueKey('reopen-note-send'),
          onPressed: _submit,
          child: Text(l10n.monthReopen),
        ),
      ],
    );
  }
}
