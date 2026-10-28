import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

/// Asks for a reason in one shared sheet, so every Phase 3 flow validates it
/// the same way (D-P3-17, CLAUDE.md rule 40).
///
/// Returns the trimmed text when the user confirms, or `null` when the sheet is
/// dismissed (including the system back gesture) — the caller must treat
/// `null` as "no action", never as an empty reason.
///
/// Validation: 3–300 characters by default (`minLength` / `maxLength`). With
/// `required: false` an empty field is accepted and returned as `''`;
/// otherwise the confirm button stays disabled until the text is long enough,
/// and the message that explains why is shown as soon as the user types
/// something too short.
Future<String?> showReasonSheet(
  BuildContext context, {
  required String title,
  String? hint,
  int minLength = 3,
  int maxLength = 300,
  bool required = true,
  String? initialText,
}) {
  assert(minLength >= 0, 'minLength must not be negative');
  assert(maxLength >= minLength, 'maxLength must not be below minLength');
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _ReasonSheet(
      title: title,
      hint: hint,
      minLength: minLength,
      maxLength: maxLength,
      required: required,
      initialText: initialText,
    ),
  );
}

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({
    required this.title,
    required this.hint,
    required this.minLength,
    required this.maxLength,
    required this.required,
    required this.initialText,
  });

  final String title;
  final String? hint;
  final int minLength;
  final int maxLength;
  final bool required;
  final String? initialText;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  bool _touched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _trimmed => _controller.text.trim();

  bool get _valid =>
      _trimmed.length >= widget.minLength ||
      (!widget.required && _trimmed.isEmpty);

  String? get _error {
    if (!_touched || _valid) return null;
    return context.l10n.reasonSheetTooShort(widget.minLength);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final insets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + insets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: widget.maxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: widget.hint ?? l10n.reasonSheetHint,
              errorText: _error,
            ),
            onChanged: (_) => setState(() => _touched = true),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.actionCancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: tokens.accent,
                  foregroundColor: tokens.textOnAccent,
                ),
                onPressed: _valid
                    ? () => Navigator.of(context).pop(_trimmed)
                    : null,
                child: Text(l10n.actionSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
