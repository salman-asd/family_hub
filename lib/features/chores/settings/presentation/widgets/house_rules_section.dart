import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/draft_text_field.dart';
import 'package:family_hub/shared/widgets/mini_markdown_view.dart';
import 'package:flutter/material.dart';

/// House rules (P3-17): a mini-markdown editor with a live preview, at most
/// [ChoreSettingsLimits.maxHouseRulesLength] characters.
///
/// The text is rendered by [MiniMarkdownView] everywhere (also read-only on
/// the Manage hub), so what the preview shows is exactly what the family sees.
class HouseRulesSection extends StatefulWidget {
  const HouseRulesSection({
    required this.houseRules,
    required this.onChanged,
    super.key,
  });

  final String houseRules;
  final ValueChanged<String> onChanged;

  @override
  State<HouseRulesSection> createState() => _HouseRulesSectionState();
}

class _HouseRulesSectionState extends State<HouseRulesSection> {
  bool _preview = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          key: const ValueKey<String>('rules_mode'),
          showSelectedIcon: true,
          segments: [
            ButtonSegment<bool>(
              value: false,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.choresSettingsHouseRulesEditor),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.choresSettingsHouseRulesPreview),
            ),
          ],
          selected: <bool>{_preview},
          onSelectionChanged: (s) => setState(() => _preview = s.first),
        ),
        const SizedBox(height: 12),
        if (_preview)
          MiniMarkdownView(
            markdown: widget.houseRules,
            emptyText: l10n.choresSettingsHouseRulesEmpty,
          )
        else ...[
          DraftTextField(
            key: const ValueKey<String>('house_rules_field'),
            value: widget.houseRules,
            onChanged: widget.onChanged,
            maxLength: ChoreSettingsLimits.maxHouseRulesLength,
            maxLines: 10,
            minLines: 5,
            keyboardType: TextInputType.multiline,
          ),
          Text(
            l10n.choresSettingsHouseRulesHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
