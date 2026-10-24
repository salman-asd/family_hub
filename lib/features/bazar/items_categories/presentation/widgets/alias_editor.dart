import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

/// Search spellings of an item as removable chips plus a field to add one.
class AliasEditor extends StatelessWidget {
  const AliasEditor({
    required this.aliases,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    this.errorText,
    super.key,
  });

  final List<String> aliases;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final alias in aliases)
              InputChip(label: Text(alias), onDeleted: () => onRemove(alias)),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('item-alias'),
                controller: controller,
                onSubmitted: (_) => onAdd(),
                decoration: InputDecoration(
                  labelText: l10n.catalogAliasField,
                  errorText: errorText,
                  errorMaxLines: 2,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('item-alias-add'),
              tooltip: l10n.catalogAliasAdd,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAdd,
            ),
          ],
        ),
      ],
    );
  }
}
