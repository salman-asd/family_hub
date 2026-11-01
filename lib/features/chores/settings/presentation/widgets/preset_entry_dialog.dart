import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/shared/widgets/minutes_field.dart';
import 'package:flutter/material.dart';

/// Asks for a due-time preset's names and time of day (P3-17). Returns the
/// edited preset (same id, `builtIn` and `active`), or null when cancelled.
Future<DueTimePreset?> showPresetEntryDialog(
  BuildContext context, {
  required DueTimePreset base,
  required bool isNew,
  required AppFormatters formatters,
}) => showDialog<DueTimePreset>(
  context: context,
  builder: (_) =>
      _PresetEntryDialog(base: base, isNew: isNew, formatters: formatters),
);

class _PresetEntryDialog extends StatefulWidget {
  const _PresetEntryDialog({
    required this.base,
    required this.isNew,
    required this.formatters,
  });

  final DueTimePreset base;
  final bool isNew;
  final AppFormatters formatters;

  @override
  State<_PresetEntryDialog> createState() => _PresetEntryDialogState();
}

class _PresetEntryDialogState extends State<_PresetEntryDialog> {
  late final TextEditingController _bn = TextEditingController(
    text: widget.base.labelBn,
  );
  late final TextEditingController _en = TextEditingController(
    text: widget.base.labelEn ?? '',
  );
  late int _minutes = widget.base.minutes;

  @override
  void dispose() {
    _bn.dispose();
    _en.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.isNew ? l10n.choresPresetAddTitle : l10n.choresPresetEditTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey<String>('preset_label_bn'),
            controller: _bn,
            autofocus: true,
            maxLength: 30,
            decoration: InputDecoration(labelText: l10n.catalogEditorLabelBn),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            key: const ValueKey<String>('preset_label_en'),
            controller: _en,
            maxLength: 30,
            decoration: InputDecoration(labelText: l10n.catalogEditorLabelEn),
          ),
          const SizedBox(height: 8),
          MinutesField(
            key: const ValueKey<String>('preset_minutes'),
            label: l10n.choresPresetTime,
            minutes: _minutes,
            formatters: widget.formatters,
            clearable: false,
            onChanged: (m) => setState(() => _minutes = m ?? _minutes),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const ValueKey<String>('preset_dialog_save'),
          onPressed: _bn.text.trim().isEmpty ? null : _submit,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }

  void _submit() {
    final en = _en.text.trim();
    Navigator.of(context).pop(
      DueTimePreset(
        id: widget.base.id,
        labelBn: _bn.text.trim(),
        labelEn: en.isEmpty ? null : en,
        minutes: _minutes,
        active: widget.base.active,
        builtIn: widget.base.builtIn,
      ),
    );
  }
}
