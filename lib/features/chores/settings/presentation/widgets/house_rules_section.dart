import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/shared/widgets/mini_markdown_view.dart';
import 'package:flutter/material.dart';

/// House rules editor + preview section of the chore settings screen (P3-17).
///
/// The editor is a plain `TextField` limited to 2000 characters
/// ([ChoreSettingsLimits.maxHouseRulesLength]) with a mini-markdown hint.
/// The preview is always visible so the family can see how the rules will look.
/// The live preview re-renders on every keystroke (the text is short, the
/// parser is O(n), so performance is not a concern).
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
  late final TextEditingController _ctrl;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.houseRules);
    _ctrl.addListener(() => widget.onChanged(_ctrl.text));
  }

  @override
  void didUpdateWidget(HouseRulesSection old) {
    super.didUpdateWidget(old);
    // Keep the controller in sync when the parent resets the draft.
    if (widget.houseRules != _ctrl.text) {
      _ctrl.text = widget.houseRules;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Editor / preview toggle ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  _showPreview
                      ? l10n.choresSettingsHouseRulesPreview
                      : l10n.choresSettingsHouseRulesEditor,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _showPreview = !_showPreview),
                child: Text(
                  _showPreview
                      ? l10n.choresSettingsHouseRulesEditor
                      : l10n.choresSettingsHouseRulesPreview,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (!_showPreview) ...[
            TextField(
              key: const ValueKey('house-rules-field'),
              controller: _ctrl,
              maxLength: ChoreSettingsLimits.maxHouseRulesLength,
              maxLines: 8,
              decoration: InputDecoration(
                helperText: l10n.choresSettingsHouseRulesHelp,
                helperMaxLines: 2,
              ),
            ),
          ] else ...[
            MiniMarkdownView(
              markdown: _ctrl.text,
              emptyText: l10n.choresSettingsHouseRulesEmpty,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

