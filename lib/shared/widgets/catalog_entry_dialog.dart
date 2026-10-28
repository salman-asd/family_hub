import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/catalog_editor.dart';
import 'package:flutter/material.dart';

/// Result of the add / rename dialog of a [CatalogEditor].
typedef CatalogLabel = ({String bn, String? en});

/// Asks for the Bangla (required) and English (optional) label of a row.
///
/// Split out of `catalog_editor.dart` so neither file grows past 300 lines.
Future<CatalogLabel?> showCatalogEntryDialog(
  BuildContext context, {
  CatalogEntry? entry,
}) => showDialog<CatalogLabel>(
  context: context,
  builder: (dialogContext) => _CatalogEntryDialog(entry: entry),
);

class _CatalogEntryDialog extends StatefulWidget {
  const _CatalogEntryDialog({required this.entry});

  final CatalogEntry? entry;

  @override
  State<_CatalogEntryDialog> createState() => _CatalogEntryDialogState();
}

class _CatalogEntryDialogState extends State<_CatalogEntryDialog> {
  late final TextEditingController _bn = TextEditingController(
    text: widget.entry?.labelBn ?? '',
  );
  late final TextEditingController _en = TextEditingController(
    text: widget.entry?.labelEn ?? '',
  );

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
      title: Text(
        widget.entry == null
            ? l10n.catalogEditorAddTitle
            : l10n.catalogEditorEditTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _bn,
            autofocus: true,
            maxLength: 40,
            decoration: InputDecoration(labelText: l10n.catalogEditorLabelBn),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _en,
            maxLength: 40,
            decoration: InputDecoration(labelText: l10n.catalogEditorLabelEn),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _bn.text.trim().isEmpty ? null : _submit,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }

  void _submit() {
    final en = _en.text.trim();
    Navigator.of(context)
        .pop((bn: _bn.text.trim(), en: en.isEmpty ? null : en));
  }
}
